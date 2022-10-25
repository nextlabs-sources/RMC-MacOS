//
//  NXSharepointOnlineRemoteQuery.m
//  NXsharepointonline
//
//  Created by nextlabs on 5/28/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXSharepointOnlineRemoteQuery.h"
#import "NXXMLDocument.h"

#define NOSUCHFILEHTTPCODE 500
#define SuccessHttpCode 200
#define FailureHttpCode 400

@interface NXSharepointOnlineRemoteQuery()<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@property (nonatomic,strong) NSArray* cookies;

//for download progress.
@property long long filesize;
@property NSRange range;
@property (nonatomic,assign)BOOL isRangeDownloadFinished;
@property long long downloadsize;
@property NSString* downloadfiledestfullpath;
@property NSMutableData *receivedata;

@property(nonatomic, strong) NSURLSessionDataTask* dataTask;
@property(nonatomic, strong) NSURLSessionDownloadTask* downloadTask;
@property(nonatomic, strong) NSData *downloadData;
@end

@implementation NXSharepointOnlineRemoteQuery

# pragma mark public method

- (instancetype) initWithURL:(NSString*)url cookies:(NSArray *)cookies {
    if (self = [super init]) {
        self.queryUrl = url;
        _requestMethod = @"GET";
        _cookies = cookies;
    }
    self.isRangeDownloadFinished = FALSE;
    return self;
}
#pragma mark Getter/Setter functions


# pragma  mark  private method

- (NSMutableURLRequest*) initializeRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self.queryUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet]]];
    
    [request setHTTPMethod:_requestMethod];
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:_cookies];
    [request setAllHTTPHeaderFields:headers];
    
    return  request;
}

#pragma mark Private Interface
-(void) startNewDataTask:(NSURLRequest*) request
{
    self.dataTask = [self.spSession dataTaskWithRequest:request];
    [self.dataTask resume];
}

-(void) startNewDownLoadTask:(NSURLRequest*) request
{
    self.downloadTask = [self.spSession downloadTaskWithRequest:request];
    [self.downloadTask resume];
}

- (void) executeQUery:(NSURLRequest*)request {
    [self startNewDataTask:request];
}

# pragma mark

- (void) executeQueryWithRequestId:(NSInteger)requestid {
    self.queryID = requestid;
    NSMutableURLRequest *request = [self initializeRequest];
    
    if (self.queryID == kSPQueryDownloadFile) {
        NSDictionary *fileinfo = (NSDictionary*)self.additionData;
        _filesize =  [[fileinfo objectForKey:@"fileSize"] longLongValue];
        _downloadfiledestfullpath = [fileinfo objectForKey:@"destPath"];
        [self startNewDownLoadTask:request];
        
    } else {
        if (self.queryID == kSPQueryRangeDownloadFile) {
            [request setValue:[NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)_range.location, _range.location+_range.length-1] forHTTPHeaderField:@"Range"];
        }
        self.dataTask = [self.spSession dataTaskWithRequest:request];
        [self.dataTask resume];
    }
}

- (void) executeQueryWithRequestId:(NSInteger)requestid withAdditionData:(id) additionData {
    self.additionData = additionData;
    [self executeQueryWithRequestId: requestid];
}

- (void) executeQueryWithRequestId:(NSInteger)requestid withAdditionData:(id) additionData range:(NSRange)range {
    self.additionData = additionData;
    _range = range;
    [self executeQueryWithRequestId: requestid];
}

- (void) executeQueryWithRequestId:(NSInteger)requestid Headers:(NSDictionary *)headers RequestMethod:(NSString *)rqMethod BodyData:(NSData *)bodyData withAdditionData:(id)additionData {
    self.additionData = additionData;
    self.queryID = requestid;
    
    NSMutableURLRequest *request = (NSMutableURLRequest*)[self initializeRequest];
    
    // 1. set method
    [request setHTTPMethod:rqMethod];
    
    // 2. set request headers
    for (NSString* key in headers) {
        [request setValue:[headers objectForKey:key] forHTTPHeaderField:key];
    }
    
    // 3. set request body
    if (bodyData) {
        [request setHTTPBody:bodyData];
        NSString* contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length];
        [request setValue:contentLength forHTTPHeaderField:@"content-length"];
    }else {
        [request setValue:@"0" forHTTPHeaderField:@"content-length"];
    }
    
    [self executeQUery:request];
}

-(void) cancelQueryWithRequestId:(NSInteger) requestid AdditionData:(id) additionData {
    self.queryID = requestid;
    
    
    if (requestid == kSPQueryDownloadFile || requestid == kSPQueryRangeDownloadFile) {
        [self.downloadTask cancel];
        self.downloadTask = nil;
        [self.spSession invalidateAndCancel];
    }else
    {
        [self.dataTask cancel];
        
        self.dataTask = nil;
        
        [self.spSession invalidateAndCancel];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpres = (NSHTTPURLResponse*)response;
        if ([httpres statusCode] == 200 ||
            ((self.queryID == kSPQueryCreateFolder || self.queryID == kSPQueryCreateDocLibrary) && [httpres statusCode] == 201)) {
            _receivedata = [[NSMutableData alloc] init];
            [_receivedata setLength:0];
        }
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [_receivedata appendData:data];
    if (self.queryID == kSPQueryRangeDownloadFile) {
        if (_receivedata.length >= _range.length + _range.location ) {
            
            dispatch_async(dispatch_get_main_queue(),^{
                [self.delegate remoteQuery:self downloadProcess:1.0];
            });
            _isRangeDownloadFinished = true;
            [dataTask cancel];
            return;
        }
        CGFloat progress = (CGFloat)_receivedata.length/(_range.length + _range.location);
        dispatch_async(dispatch_get_main_queue(),^{
            [self.delegate remoteQuery:self downloadProcess:progress];
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    
    NSURLResponse * response = task.response;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) { // check html response error code
        NSHTTPURLResponse *httpres = (NSHTTPURLResponse*)response;
        
        if ([httpres statusCode] == NOSUCHFILEHTTPCODE) {
            NSError *newError = [NSError errorWithDomain:@"NXRMCServicesErrorDomain" code:10000 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate remoteQuery:self didCompleteQuery:nil error:newError];
                [self.dataTask cancel];
                self.dataTask = nil;
            });
            return;
            
        }else if(httpres.statusCode < SuccessHttpCode || httpres.statusCode >= FailureHttpCode) {
            // http error code
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError* newError = [NSError errorWithDomain:@"NXHttpStatusError" code:httpres.statusCode userInfo:nil];
                [self.delegate remoteQuery:self didCompleteQuery:nil error:newError];
            });
            return;
        }
    }
    
    if(error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *retError = error;
            if (self.queryID == kSPQueryRangeDownloadFile && self->_isRangeDownloadFinished ) {
                NSUInteger len = MIN(self->_range.length, self->_receivedata.length - self->_range.location);
                self->_downloadData = [NSData dataWithBytes:(char *)self->_receivedata.bytes + self->_range.location length:len];
                retError = nil;
            }
            if ([self.delegate respondsToSelector:@selector(remoteQuery:didCompleteQuery:error:)]) {
                [self.delegate remoteQuery:self didCompleteQuery:self->_downloadData error:retError];
            }
        });
        
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(remoteQuery:didCompleteQuery:error:)]) {
                if (self.queryID == kSPQueryDownloadFile) {
                    [self.delegate remoteQuery:self didCompleteQuery:self->_downloadData error:nil];
                }else {
                    [self.delegate remoteQuery:self didCompleteQuery:self->_receivedata error:nil];
                }
            }
        });
    }
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    CGFloat progress = (CGFloat)totalBytesSent/totalBytesExpectedToSend;
    [self.delegate remoteQuery:self uploadFileProcess:progress];
}
#pragma mark downloadTask delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    _downloadData = [NSData dataWithContentsOfFile:location.path];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    CGFloat progress = (CGFloat)totalBytesWritten/_filesize;
    NSLog(@"SharePoint download...%f", progress);
    dispatch_async(dispatch_get_main_queue(),^{
        [self.delegate remoteQuery:self downloadProcess:progress];
    });
}
@end
