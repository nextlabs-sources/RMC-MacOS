//
//  NXSharePointRemoteQuery.m
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/25.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXSharePointRemoteQuery.h"
#define SuccessHttpCode 200
#define FailureHttpCode 400

@interface NXSharePointRemoteQuery()
@property(nonatomic, strong) NSURLSessionDataTask* dataTask;
@property(nonatomic, strong) NSURLSessionDownloadTask* downloadTask;
@property(nonatomic) BOOL needAuthen;
@end

@implementation NXSharePointRemoteQuery

#pragma mark INIT Methods
-(instancetype) initWithURL:(NSString *)url userName:(NSString *)name passWord:(NSString *)psw
{
    if (self = [super init]) {
        self.queryUrl = url;
        _userName = name;
        _psw = psw;
    }
    return self;
}

#pragma mark Getter/Setter functions

#pragma mark Public Interface
-(void) executeQueryWithRequestId:(NSInteger) reqId
{
    self.queryID = reqId;
    
    NSURLRequest* rq = [NSURLRequest requestWithURL:[NSURL URLWithString:[self.queryUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet]]];
    if (self.queryID == kSPQueryDownloadFile) {
        
        [self startNewDownLoadTask:rq];
        
    }else
    {
        [self startNewDataTask:rq];

    }
}

-(void) executeQueryWithRequestId:(NSInteger) reqId withAdditionData:(id) additionData
{
    
    self.queryID = reqId;
    self.additionData = additionData;
    
    NSURLRequest* rq = [NSURLRequest requestWithURL:[NSURL URLWithString:[self.queryUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet]]];
    if (self.queryID == kSPQueryDownloadFile) {
        
        [self startNewDownLoadTask:rq];
        
    }else
    {
        [self startNewDataTask:rq];
        
    }

}

- (void) executeQueryWithRequestId:(NSInteger)requestid Headers:(NSDictionary*)headers RequestMethod:(NSString*) rqMethod BodyData:(NSData*)bodyData withAdditionData:(id) additionData
{
    self.queryID = requestid;
    self.additionData = additionData;
    NSMutableURLRequest* rq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self.queryUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet]]];
    
    
    // 1.set request method
    [rq setValue:rqMethod forHTTPHeaderField:@"METHOD"];
    [rq setHTTPMethod:rqMethod];
    
    // 2. set request headers
    for (NSString* key in headers) {
        [rq setValue:[headers objectForKey:key] forHTTPHeaderField:key];
    }
    
    // 3. set request body
    if (bodyData) {
        [rq setHTTPBody:bodyData];
        NSString* contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length];
        [rq setValue:contentLength forHTTPHeaderField:@"content-length"];
    }else
    {
        [rq setValue:@"0" forHTTPHeaderField:@"content-length"];
    }

    // 4. do request
    if (self.queryID == kSPQueryDownloadFile) {
        
        [self startNewDownLoadTask:rq];
        
    }else
    {
        [self startNewDataTask:rq];
        
    }

}
-(void) cancelQueryWithRequestId:(NSInteger) requestid AdditionData:(id) additionData
{
    self.queryID = requestid;
    self.additionData = additionData;
    
    if (requestid == kSPQueryDownloadFile) {
        if (self.downloadTask.state == NSURLSessionTaskStateRunning || self.downloadTask.state == NSURLSessionTaskStateSuspended) {
            [self.downloadTask cancel];
        }
    }else
    {
        if (self.dataTask.state == NSURLSessionTaskStateRunning || self.dataTask.state == NSURLSessionTaskStateSuspended) {
            [self.dataTask cancel];
        }
    }
    
}
#pragma mark Private Interface
-(void) startNewDataTask:(NSURLRequest*) request
{
    self.dataTask = [self.spSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate remoteQuery:self didCompleteQuery:nil error:error];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                if (httpResponse.statusCode >= SuccessHttpCode && httpResponse.statusCode < FailureHttpCode) {
                    if (self.queryID == kSPQueryAuthentication) {
                        if (self.needAuthen) {
                            NSDictionary* headDic = [httpResponse allHeaderFields];
                            
                            NSString* spHeader = [headDic valueForKey:@"MicrosoftSharePointTeamServices"];
                            if (spHeader) {
                                [self.delegate remoteQuery:self didCompleteQuery:data error:nil];
                            }else
                            {
                                NSError* newError = [NSError errorWithDomain:@"NXHttpAutoRedirectError" code:1 userInfo:nil];
                                [self.delegate remoteQuery:self didCompleteQuery:nil error:newError];
                            }
                            self.needAuthen = NO;
                        }else // no needAuthen, but get response correctly(it is wrong situation for we need authen challenge)
                        {
                            NSError* newError = [NSError errorWithDomain:@"NXHttpAutoRedirectError" code:1 userInfo:nil];
                            [self.delegate remoteQuery:self didCompleteQuery:nil error:newError];
                        }
                    }else
                    {
                        NSDictionary* headDic = [httpResponse allHeaderFields];
                        
                        NSString* spHeader = [headDic valueForKey:@"MicrosoftSharePointTeamServices"];
                        // make sure the response is from sharepoint not other service
                        if (spHeader) {
                            [self.delegate remoteQuery:self didCompleteQuery:data error:nil];
                        }else
                        {
                            assert(NO);
                            // http error code
                            NSError* newError = [NSError errorWithDomain:@"NXHttpStatusError" code:httpResponse.statusCode userInfo:nil];
                            [self.delegate remoteQuery:self didCompleteQuery:nil error:newError];
                        }
                        
                    }
                }// Http success code
                else
                {
                    // http error code
                    NSError* newError = [NSError errorWithDomain:@"NXHttpStatusError" code:httpResponse.statusCode userInfo:nil];
                    [self.delegate remoteQuery:self didCompleteQuery:nil error:newError];
                }
            }
            }); //dispatch_async
        }
    }];
    
    [self.dataTask resume];
}

-(void) startNewDownLoadTask:(NSURLRequest*) request
{
    self.downloadTask = [self.spSession downloadTaskWithRequest:request];
    [self.downloadTask resume];
}

#pragma mark NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate remoteQuery:self didCompleteQuery:nil error:error];
        });
    }
}

#pragma mark downloadTask delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSData* fileData = [NSData dataWithContentsOfFile:location.path];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate remoteQuery:self didCompleteQuery:fileData error:nil];
    });
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSDictionary* dic = (NSDictionary*)self.additionData;
    NSNumber* fileSize = [dic valueForKey:SP_DICTION_TAG_FILE_SIZE];
    CGFloat totalSize = [fileSize longLongValue];
    CGFloat progress = (CGFloat)totalBytesWritten/totalSize;
    NSLog(@"SharePoint download...%f", progress);
    dispatch_async(dispatch_get_main_queue(),^{
        [self.delegate remoteQuery:self downloadProcess:progress];
    });
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"YES");
}


@end
