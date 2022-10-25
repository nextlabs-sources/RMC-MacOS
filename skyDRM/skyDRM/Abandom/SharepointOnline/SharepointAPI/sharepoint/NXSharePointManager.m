//
//  NXSharePointSDK.m
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/21.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXSharePointManager.h"
#import "NXSharePointXMLParse.h"
typedef void (^RemoteQueryResponseHandler) (NXSharePointRemoteQueryBase* query, NSData* data, NSError *error);



@interface NXSharePointManager()

@property(nonatomic, strong) NSString* user;
@property(nonatomic, strong) NSString* psw;
@property(nonatomic, strong) NSArray *cookies;


@property(nonatomic, strong) NSMutableDictionary *siteChildrenItemDictionary;
@property(nonatomic, strong) NSMutableDictionary *folderChildrenItemDictionary;

@property(nonatomic, strong) NSMutableDictionary *downloadQueryDictionary;
@property(nonatomic, strong) NSMutableDictionary *rangeDownloadQueryDictionary;
@property(nonatomic, strong) NSMutableDictionary *updateFileQueryDictionary;
@property(nonatomic, strong) NSMutableDictionary *addFileQueryDictionary;

@property(nonatomic, strong) NSMutableDictionary* remoteQueryResponseHandlers;
@property(nonatomic, strong) NSMutableDictionary* formDigestValueDictionary; //To do POST request in Sharepoint, need post formdigest to do

-(void) initRemoteQueryResponseHandler;
@end


@implementation NXSharePointManager
#pragma mark ALLOC and INIT and SETTER/GETTER
- (instancetype) initWithURL:(NSString *)siteURL cookies:(NSArray *)cookies Type:(SPManagerType)type {
    if (self = [super init]) {
        _siteURL = siteURL;
        _cookies = cookies;
        _spMgrType = type;
        _siteChildrenItemDictionary = [[NSMutableDictionary alloc] init];
        _folderChildrenItemDictionary = [[NSMutableDictionary alloc] init];
        
        _remoteQueryResponseHandlers = [[NSMutableDictionary alloc] init];
        _formDigestValueDictionary = [[NSMutableDictionary alloc] init];
        _downloadQueryDictionary = [[NSMutableDictionary alloc] init];
        _rangeDownloadQueryDictionary = [[NSMutableDictionary alloc] init];
        _updateFileQueryDictionary = [[NSMutableDictionary alloc] init];
        _addFileQueryDictionary = [[NSMutableDictionary alloc] init];
        [self initRemoteQueryResponseHandler];
        
       
    }
    return  self;
}

-(instancetype) initWithSiteURL:(NSString*) siteURL userName:(NSString*) userName passWord:(NSString*) psw Type:(SPManagerType) type
{
    if (self = [super init]) {
        _siteURL = siteURL;
        _user = userName;
        _psw = psw;
        _spMgrType = type;
        
        // siteURL is like 'https://pf1-w12-sps06/sites/spe/tyy/Forms/AllItems.aspx'
        // so servername is siteURLcontent[2];
        NSArray* siteURLcontent  = [siteURL componentsSeparatedByString:@"/"];
        if(siteURLcontent.count >= 3)
        {
             _serverName = siteURLcontent[2];
        }
        
        _siteChildrenItemDictionary = [[NSMutableDictionary alloc] init];
        _folderChildrenItemDictionary = [[NSMutableDictionary alloc] init];
        
        _remoteQueryResponseHandlers = [[NSMutableDictionary alloc] init];
        _formDigestValueDictionary = [[NSMutableDictionary alloc] init];
        _downloadQueryDictionary = [[NSMutableDictionary alloc] init];
        _rangeDownloadQueryDictionary = [[NSMutableDictionary alloc] init];
        _updateFileQueryDictionary = [[NSMutableDictionary alloc] init];
        _addFileQueryDictionary = [[NSMutableDictionary alloc] init];
        [self initRemoteQueryResponseHandler];
    }
    return self;
}

-(void) initRemoteQueryResponseHandler
{
    __weak NXSharePointManager *weakself = self;
    
    RemoteQueryResponseHandler getContextInfo = ^(NXSharePointRemoteQueryBase* query, NSData* data, NSError *error)
    {
        
        NSDictionary* appendDic = (NSDictionary*)query.additionData;
        
        NSNumber* rqNum = appendDic[SP_DICTION_TAG_REQ_TYPE];
        NSInteger rqType = [rqNum integerValue];
        
        //parse error
        if (error) {
            switch (rqType) {
                case kSPQueryAddFile:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *fileName = appendDic[SP_DICTION_TAG_FILE_NAME];
                    NSString *folderURL = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                    NSString *fileSrcPath = appendDic[SP_DICTION_TAG_FILE_SRC_PATH];
                    if ([self.delegate respondsToSelector:@selector(addFileFinishedWithSite:fileName:folderPath:localPath:error:)]) {
                        [self.delegate addFileFinishedWithSite:site fileName:fileName folderPath:folderURL localPath:fileSrcPath error:error];
                    }
                    break;
                }
                case kSPQueryUpdateFile:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString* fileUrl = appendDic[SP_DICTION_TAG_FILE_REV_URL];
                    NSString* fileSrcPath = appendDic[SP_DICTION_TAG_FILE_SRC_PATH];
                    if ([self.delegate respondsToSelector:@selector(updateFileFinishedWithSite:filePath:localPath:error:)]) {
                        [self.delegate updateFileFinishedWithSite:site filePath:fileUrl localPath:fileSrcPath error:error];
                    }
                    break;
                }
                case kSPQueryDeleteFolder:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *relativePath = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                    if ([self.delegate respondsToSelector:@selector(deleteFolderOrDocumentlibWithSite:relativePath:)]) {
                        [self.delegate deleteFolderFinishedWithSite:site relativePath:relativePath error:error];
                    }
                    break;
                }
                case kSPQueryDeleteFile:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *relativePath = appendDic[SP_DICTION_TAG_FILE_REV_URL];
                    if ([self.delegate respondsToSelector:@selector(deleteFileFinishedWithSite:filePath:error:)]) {
                        [self.delegate deleteFileFinishedWithSite:site filePath:relativePath error:error];
                    }
                    break;
                }
                case kSPQueryCreateFolder:
                {
                    NSString *folderName = appendDic[SP_DICTION_TAG_FOLDER_NAME];
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *parentPath = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                    if ([self.delegate respondsToSelector:@selector(createFolderFinishedWithSite:folderName:parentPath:item:error:)]) {
                        [self.delegate createFolderFinishedWithSite:site folderName:folderName parentPath:parentPath item:nil error:error];
                    }
                    break;
                }
                case kSPQueryCreateDocLibrary:
                {
                    NSString *name = appendDic[SP_DICTION_TAG_DOCUMENTLIB_NAME];
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    if ([self.delegate respondsToSelector:@selector(createDocumentLibFinishedWithSite:name:item:error:)]) {
                        [self.delegate createDocumentLibFinishedWithSite:site name:name item:nil error:error];
                    }
                    break;
                }
                default:
                break;
            }
        }
        else{
    
            NSArray* result = [NXSharePointXMLParse parseContextInfo:data];

            NSDictionary* dic = result.firstObject;
            NSString *formDigestValue = [dic valueForKey:SP_FORM_DIGEST_TAG];
            
            switch (rqType) {
                case kSPQueryAddFile:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *fileName = appendDic[SP_DICTION_TAG_FILE_NAME];
                    NSString *folderURL = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                    NSString *fileSrcPath = appendDic[SP_DICTION_TAG_FILE_SRC_PATH];
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself addFileAfterContextSite:site fileName:fileName folderPath:folderURL localPath:fileSrcPath digest:formDigestValue];
                    break;
                }
                case kSPQueryUpdateFile:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString* fileUrl = appendDic[SP_DICTION_TAG_FILE_REV_URL];
                    NSString* fileSrcPath = appendDic[SP_DICTION_TAG_FILE_SRC_PATH];
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself updateFileAfterContextSite:site filePath:fileUrl localPath:fileSrcPath digest:formDigestValue];
                    break;
                }
                case kSPQueryDeleteFolder:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *relativePath = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself deleteFolderOrDocumentlibAfterContextSite:site relativePath:relativePath digest:formDigestValue];
                    break;
                }
                case kSPQueryDeleteFile:
                {
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *relativePath = appendDic[SP_DICTION_TAG_FILE_REV_URL];
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself deleteFileAfterContextSite:site filePath:relativePath digest:formDigestValue];
                    break;
                }
                case kSPQueryCreateFolder:
                {
                    NSString *folderName = appendDic[SP_DICTION_TAG_FOLDER_NAME];
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    NSString *parentPath = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself creatFolderAfterContextSite:site folderName:folderName parentPath:parentPath digest:formDigestValue];
                    break;
                }
                case kSPQueryCreateDocLibrary:
                {
                    NSString *name = appendDic[SP_DICTION_TAG_DOCUMENTLIB_NAME];
                    NSString *site = appendDic[SP_DICTION_TAG_SITE];
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself createDocumentLibAfterContextSite:site documentLibName:name digest:formDigestValue];
                    break;
                }
                default:
                    break;
            }
        }
    };
    

    if (!_remoteQueryResponseHandlers) {
        
        _remoteQueryResponseHandlers = [[NSMutableDictionary alloc] init];
    }
    
    [_remoteQueryResponseHandlers setObject:[getContextInfo copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetContextInfo]];
}

-(void) siteURL:(NSString*) newSiteURL
{
    if (newSiteURL) {
        _siteURL = newSiteURL;
        
        // siteURL is like 'https://pf1-w12-sps06/sites/spe/tyy/Forms/AllItems.aspx'
        // so servername is siteURLcontent[2];
        NSArray* siteURLcontent  = [_siteURL componentsSeparatedByString:@"/"];
        _serverName = siteURLcontent[2];
    }
}

- (NXSharePointRemoteQueryBase*) initializeQuery:(NSString *)queryURLStr {
    NXSharePointRemoteQueryBase *spQuery = nil;
    switch (_spMgrType) {
        case kSPMgrSharePoint:
            spQuery = [[NXSharePointRemoteQuery alloc] initWithURL:queryURLStr userName:self.user passWord:self.psw];
            break;
        case kSPMgrSharePointOnline:
            spQuery = [[NXSharepointOnlineRemoteQuery alloc] initWithURL:queryURLStr cookies:self.cookies];
            break;
        default:
            break;
    }
    
    spQuery.delegate = self;
    
    return spQuery;
}

#pragma mark SharePoint SDK public interface
-(void) allChildItemsWithSite:(NSString *)site
{
    NSString* queryAllChildrenSites = [NSString stringWithFormat:[NXSharePointRestTemp SPGetChildenSitesTemp], site];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllChildrenSites];
    spQuery.additionData = site;
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildSites];
}
-(void) allDocumentLibSite:(NSString *)site
{
    NSString* queryURLStr = [NSString stringWithFormat:[NXSharePointRestTemp SPGetAllListsTemp], site];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryURLStr];
    spQuery.additionData = site;
    [spQuery executeQueryWithRequestId:kSPQueryGetAllDocLists];
}
-(void) allChildItemsInFolderWithSite:(NSString *)site folderPath:(NSString *)folderPath
{
    [self allChildenFoldersInFolderSite:site folderPath:folderPath];
}

-(void) allChildenFoldersInFolderSite:(NSString *)site folderPath:(NSString *)folderPath
{
    NSString* queryAllFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetChildenFolderTemp], site, folderPath];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFolder];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, folderPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FOLDER_REV_URL]];
    spQuery.additionData = appendData;
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildFoldersInFolder];
}

-(void) allChildenFilesInFolderSite:(NSString *)site folderPath:(NSString *)folderPath
{
    NSString* queryAllFiles = [NSString stringWithFormat:[NXSharePointRestTemp SPGetChildenFileTemp], site, folderPath];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFiles];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, folderPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FOLDER_REV_URL]];
    spQuery.additionData = appendData;
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildFilesInFolder];
}


-(void) getFolderMeataDataWithSite:(NSString *)site relativePath:(NSString *)relativePath
{
    NSString* queryFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetFolderTemp], site, relativePath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryFolder];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, relativePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FOLDER_REV_URL]];
    spQuery.additionData = appendData;
    [spQuery executeQueryWithRequestId:kSPQueryFolderMetaData];

}

-(void) getSiteMetaDataWithSite:(NSString *)site
{
    NSString* querySiteProperty = [NSString stringWithFormat:[NXSharePointRestTemp SPQuerySitePropertyTemp], site];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:querySiteProperty];
    spQuery.additionData = site;
    [spQuery executeQueryWithRequestId:kSPQuerySiteMetaData];

}

-(void) getFileMetaDataWithSite:(NSString *)site filePath:(NSString *)filePath
{
    NSString* queryFileProperty = [NSString stringWithFormat:[NXSharePointRestTemp SPQueryFilePropertyTemp], site, filePath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryFileProperty];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL]];
    spQuery.additionData = appendData;
    [spQuery executeQueryWithRequestId:kSPQueryFileMetaData];
}


-(void) downloadFileWithSite:(NSString *)site filePath:(NSString *)filePath destPath:(NSString *)destPath
{
    NSString* queryFileProperty = [NSString stringWithFormat:[NXSharePointRestTemp SPQueryFilePropertyTemp], site, filePath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryFileProperty];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath, destPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_DEST_PATH]];
    spQuery.additionData = appendData;
    [spQuery executeQueryWithRequestId:kSPQueryFileMetaDataForDownload];
    
}
-(void) downloadFileWithSite:(NSString *)site filePath:(NSString *)filePath range:(NSRange)range
{
    NSString* queryDownloadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPDownloadFileTemp], site, filePath];
    NSDictionary* appendData = [NSDictionary dictionaryWithObjects:@[site, filePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL]];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryDownloadFile];
    [spQuery executeQueryWithRequestId:kSPQueryRangeDownloadFile withAdditionData:appendData range:range];
    
    NSMutableDictionary* key = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL]];
    NSString *dicKey = [self getJsonStringByDictionary:key];
    [_rangeDownloadQueryDictionary setValue:spQuery forKey:dicKey];
    
}
-(void) downloadFileWithSize:(NSNumber *)size site:(NSString *)site filePath:(NSString *)filePath destPath:(NSString *)destPath
{
    NSString* queryDownloadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPDownloadFileTemp], site, filePath];
    NSDictionary* appendData = [NSDictionary dictionaryWithObjects:@[site, filePath, size, destPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_SIZE, SP_DICTION_TAG_FILE_DEST_PATH]];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryDownloadFile];
    [spQuery executeQueryWithRequestId:kSPQueryDownloadFile withAdditionData:(id)appendData];
    
    
    NSMutableDictionary* key = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath, destPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_DEST_PATH]];
    NSString *dicKey = [self getJsonStringByDictionary:key];
    [_downloadQueryDictionary setValue:spQuery forKey:dicKey];
}

-(BOOL) cancelDownloadFileWithSite:(NSString *)site filePath:(NSString *)filePath destPath:(NSString *)destPath {
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath, destPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_DEST_PATH]];
    NSString *dicKey = [self getJsonStringByDictionary:appendData];
    NXSharePointRemoteQueryBase *spQuery = [_downloadQueryDictionary objectForKey:dicKey];
    if (spQuery) {
        [spQuery cancelQueryWithRequestId:spQuery.queryID AdditionData:nil];
        [_downloadQueryDictionary removeObjectForKey:dicKey];
        return TRUE;
    }
    return FALSE;
}
-(BOOL) cancelRangeDownloadFileWithSite:(NSString *)site filePath:(NSString *)filePath {
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL]];
    NSString *dicKey = [self getJsonStringByDictionary:appendData];
    NXSharePointRemoteQueryBase *spQuery = [_rangeDownloadQueryDictionary objectForKey:dicKey];
    if (spQuery) {
        [spQuery cancelQueryWithRequestId:spQuery.queryID AdditionData:nil];
        [_rangeDownloadQueryDictionary removeObjectForKey:dicKey];
        return TRUE;
    }
    return FALSE;
}
-(NSString*)getJsonStringByDictionary:(NSDictionary*)dictionary{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

-(void) addFileWithSite:(NSString *)site
           fileName:(NSString *)fileName
         folderPath:(NSString *)folderPath
          localPath:(NSString *)localPath
{
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryAddFile], site, fileName, folderPath, localPath] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_NAME, SP_DICTION_TAG_FOLDER_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];
    [self getContextInfo:appendData];
}
-(BOOL) cancelAddFileWithSite:(NSString *)site
               fileName:(NSString *)fileName
             folderPath:(NSString *)folderPath
              localPath:(NSString *)localPath{
    NSMutableDictionary* key = [[NSMutableDictionary alloc] initWithObjects:@[site, fileName, folderPath, localPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_NAME, SP_DICTION_TAG_FOLDER_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];
    NSString *dicKey = [self getJsonStringByDictionary:key];
    NXSharepointOnlineRemoteQuery *spQuery = [_addFileQueryDictionary objectForKey:dicKey];
    NSLog(@"=======%@", dicKey);
    if (spQuery) {
        [spQuery cancelQueryWithRequestId:spQuery.queryID AdditionData:nil];
        return TRUE;
    }
    return FALSE;
}
-(void) addFileAfterContextSite:(NSString *)site
                       fileName:(NSString *)fileName
                     folderPath:(NSString *)folderPath
                      localPath:(NSString *)localPath
                         digest:(NSString *)digest
{
    NSDictionary* headers = @{@"X-RequestDigest":digest, @"content-type":@"application/json;odata=verbose"};
    NSString* queryUploadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPUploadFileTemp], site, folderPath, fileName];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryUploadFile];
    // get src file data
    NSData* fileData = [NSData dataWithContentsOfFile:localPath];
    
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, fileName, folderPath, localPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_NAME, SP_DICTION_TAG_FOLDER_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];
    
    [spQuery executeQueryWithRequestId:kSPQueryAddFile Headers:headers RequestMethod:@"POST" BodyData:fileData withAdditionData:appendData];
    NSString *dicKey = [self getJsonStringByDictionary:appendData];
    [_addFileQueryDictionary setValue:spQuery forKey:dicKey];
    NSLog(@"=======%@", dicKey);
}
-(void) updateFileWithSite:(NSString *)site
              filePath:(NSString *)filePath
             localPath:(NSString *)localPath
{
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryUpdateFile], site, filePath, localPath] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];
    [self getContextInfo:appendData];
}
-(BOOL) cancelUpdateFileWithSite:(NSString *)site
                  filePath:(NSString *)filePath
                 localPath:(NSString *)localPath {
    
    NSMutableDictionary* key = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath, localPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];
    NSString *dicKey = [self getJsonStringByDictionary:key];
    NXSharepointOnlineRemoteQuery *spQuery = [_updateFileQueryDictionary objectForKey:dicKey];
    if (spQuery) {
        [spQuery cancelQueryWithRequestId:spQuery.queryID AdditionData:nil];
        return TRUE;
    }
    return FALSE;
}
    
-(void) updateFileAfterContextSite:(NSString *)site
                          filePath:(NSString *)filePath
                         localPath:(NSString *)localPath
                            digest:(NSString *)digest
{
    NSDictionary *headers = @{@"X-RequestDigest":digest,@"X-HTTP-Method":@"PUT"};
    NSString* queryUploadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPUploadFileTempOverWriteTemp], site, filePath];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryUploadFile];
    // get src file data
    NSData* fileData = [NSData dataWithContentsOfFile:localPath];
    
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath, localPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];
    
    [spQuery executeQueryWithRequestId:kSPQueryUpdateFile Headers:headers RequestMethod:@"POST" BodyData:fileData withAdditionData:appendData];
    NSString *keyStr = [self getJsonStringByDictionary:appendData];
    [_updateFileQueryDictionary setValue:spQuery forKey:keyStr];
    
}
-(void) createFolderWithSite:(NSString *)site
                  folderName:(NSString *)folderName
                  parentPath:(NSString *)parentPath{
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryCreateFolder], folderName, site, parentPath] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_FOLDER_NAME, SP_DICTION_TAG_SITE, SP_DICTION_TAG_FOLDER_REV_URL]];
    
    [self getContextInfo:appendData];
}
-(void)creatFolderAfterContextSite:(NSString *)site
                        folderName:(NSString *)folderName
                        parentPath:(NSString *)parentPath
                            digest:(NSString *)digest
{
    NSString *createFolder = [site stringByAppendingPathComponent:@"_api/web/folders"];
    NSString *decPath = [parentPath stringByAppendingPathComponent:folderName];
    NSDictionary *bodyDic = @{@"__metadata":@{@"type":@"SP.Folder"},@"ServerRelativeUrl":decPath};
    NXSharePointRemoteQueryBase *createBase =[self initializeQuery:createFolder];
    NSDictionary *headers = @{@"X-RequestDigest":digest,@"accept":@"application/json;odata=verbose",@"content-type":@"application/json;odata=verbose"};
    NSError *error;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDic options:NSJSONWritingPrettyPrinted error:&error];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, folderName, parentPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FOLDER_NAME, SP_DICTION_TAG_FOLDER_REV_URL]];
    [createBase executeQueryWithRequestId:kSPQueryCreateFolder Headers:headers RequestMethod:@"POST" BodyData:bodyData withAdditionData:appendData];
}

-(void) createDocumentLibWithSite:(NSString *)site
                  documentLibName:(NSString *)documentLibName
{
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryCreateDocLibrary], documentLibName, site] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_DOCUMENTLIB_NAME, SP_DICTION_TAG_SITE]];
    
    [self getContextInfo:appendData];
}
-(void) createDocumentLibAfterContextSite:(NSString *)site
                          documentLibName:(NSString *)documentLibName
                                   digest:(NSString *)digest
{
    NSString *createFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPCreateListFolderTemp], site];
    NSDictionary *bodyDic = @{@"__metadata":@{@"type": @"SP.List"}, @"AllowContentTypes":@"true", @"BaseTemplate":@"101", @"ContentTypesEnabled":@"true", @"Title":documentLibName};
    NXSharePointRemoteQueryBase *createBase =[self initializeQuery:createFolder];
    NSDictionary *headers = @{@"X-RequestDigest":digest, @"accept":@"application/json;odata=verbose", @"content-type":@"application/json;odata=verbose"};
    NSError *error;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDic options:NSJSONWritingPrettyPrinted error:&error];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, documentLibName] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_DOCUMENTLIB_NAME]];
    [createBase executeQueryWithRequestId:kSPQueryCreateDocLibrary Headers:headers RequestMethod:@"POST" BodyData:bodyData withAdditionData:appendData];
}

-(void) deleteFileWithSite:(NSString *)site
              filePath:(NSString *)filePath
{
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryDeleteFile], filePath, site] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_SITE]];
    
    [self getContextInfo:appendData];
}
-(void) deleteFileAfterContextSite:(NSString *)site
                          filePath:(NSString *)filePath
                            digest:(NSString *)digest
{
    NSString *deleteItem = [NSString stringWithFormat:[NXSharePointRestTemp SPDeleteFileTemp], site, filePath];
    NSDictionary *headers = @{@"X-RequestDigest":digest, @"X-HTTP-Method":@"DELETE", @"IF-MATCH":@"*"};
    
    NXSharePointRemoteQueryBase *deleteQuery = [self initializeQuery:deleteItem];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL]];
    
    [deleteQuery executeQueryWithRequestId:kSPQueryDeleteFile Headers:headers RequestMethod:@"POST" BodyData:nil withAdditionData:appendData];
}

-(void) deleteFolderOrDocumentlibWithSite:(NSString *)site
                         relativePath:(NSString *)relativePath
{
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryDeleteFolder], relativePath, site] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_FOLDER_REV_URL, SP_DICTION_TAG_SITE]];
    
    [self getContextInfo:appendData];
}
-(void) deleteFolderOrDocumentlibAfterContextSite:(NSString *)site
                                     relativePath:(NSString *)relativePath
                                           digest:(NSString *)digest
{
    NSString *deleteItem = [NSString stringWithFormat:[NXSharePointRestTemp SPDeleteFolderTemp], site, relativePath];
    NSDictionary *headers = @{@"X-RequestDigest":digest, @"X-HTTP-Method":@"DELETE", @"IF-MATCH":@"*"};
    
    NXSharePointRemoteQueryBase *deleteQuery = [self initializeQuery:deleteItem];
    NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[site, relativePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FOLDER_REV_URL]];
    
    [deleteQuery executeQueryWithRequestId:kSPQueryDeleteFolder Headers:headers RequestMethod:@"POST" BodyData:nil withAdditionData:appendData];
}

-(void) getContextInfo:(NSMutableDictionary*)appendData
{
    NSString* queryContextInfo = [NSString stringWithFormat:[NXSharePointRestTemp SPGetContextInfo], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryContextInfo];
    [spQuery executeQueryWithRequestId:kSPQueryGetContextInfo Headers:nil RequestMethod:@"POST" BodyData:nil withAdditionData:appendData];
}

- (void) getCurrentUserInfo
{
    NSString* queryCurrentUserInfo = [NSString stringWithFormat:[NXSharePointRestTemp SPGetCurrentUserInfoTemp], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryCurrentUserInfo];
    [spQuery executeQueryWithRequestId:kSPQueryGetCurrentUserInfo];
}


-(void) getCurrentUserDetailInfo:(NSString *) userId
{
    NSString *queryCurrentUserDetailInfo = [NSString stringWithFormat:[NXSharePointRestTemp SPGetCurrentUserDetailTemp], self.siteURL, userId];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryCurrentUserDetailInfo];
    [spQuery executeQueryWithRequestId:kSPQueryGetCurrentUserDetailInfo];
}

-(void) getSiteQuota:(NSDictionary *) userDetailInfo
{
    NSString *querySiteQuota = [NSString stringWithFormat:[NXSharePointRestTemp SPSiteQuotaTemp], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:querySiteQuota];
    [spQuery executeQueryWithRequestId:kSPQueryGetSiteQuota withAdditionData:userDetailInfo];
}

#pragma mark NXSharePointQueryDelegate Implement
-(void) remoteQuery:(NXSharePointRemoteQueryBase *) spQuery didCompleteQuery:(NSData *) data error:(NSError *)error
{
    switch (spQuery.queryID) {
        case kSPQueryGetAllChildSites:
        {
            NSString *site = spQuery.additionData;
            if (error) {
                if ([self.delegate respondsToSelector:@selector(allChildItemsFinishedWithSite:items:error:)]) {
                    [self.delegate allChildItemsFinishedWithSite:site items:nil error:error];
                }
            }
            else {
                if (data) {
                    NSArray *sitesArray = [NXSharePointXMLParse parseGetChildSites:data];
                    NSMutableArray *cache = [NSMutableArray arrayWithArray:sitesArray];
                    [self.siteChildrenItemDictionary setObject:cache forKey:site];
                }
                [self allDocumentLibSite:site];
            }
            break;
        }
        case kSPQueryGetAllDocLists:
        {
            NSString *site = spQuery.additionData;
            NSMutableArray *cache = [self.siteChildrenItemDictionary objectForKey:site];
            if (error) {
                if ([self.delegate respondsToSelector:@selector(allChildItemsFinishedWithSite:items:error:)]) {
                    [self.delegate allChildItemsFinishedWithSite:site items:cache error:error];
                    if (cache) {
                        [self.siteChildrenItemDictionary removeObjectForKey:site];
                    }
                }
            }
            else {
                if (data) {
                    NSArray *docListsArray = [NXSharePointXMLParse parseGetDocLibLists:data];
                    if (cache) {
                        [cache addObjectsFromArray:docListsArray];
                    }
                    else{
                        cache = [NSMutableArray arrayWithArray:docListsArray];
                    }
                }
                [self.siteChildrenItemDictionary removeObjectForKey:site];
                if ([self.delegate respondsToSelector:@selector(allChildItemsFinishedWithSite:items:error:)]) {
                    [self.delegate allChildItemsFinishedWithSite:site items:cache error:nil];
                }
            }
            break;
        }
        case kSPQueryGetAllChildFoldersInFolder:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *folderPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
            if (error) {
                if ([self.delegate respondsToSelector:@selector(allChildItemsInFolderFinishedWithSite:folderPath:items:error:)]) {
                    [self.delegate allChildItemsInFolderFinishedWithSite:site folderPath:folderPath items:nil error:error];
                }
            }
            else {
                if (data) {
                    NSArray *folderArray = [NXSharePointXMLParse parseGetChildFolders:data];
                    NSString *key = [site stringByAppendingString:folderPath];
                    NSMutableArray *cache = [NSMutableArray arrayWithArray:folderArray];
                    [self.folderChildrenItemDictionary setObject:cache forKey:key];
                }
                [self allChildenFilesInFolderSite:site folderPath:folderPath];
            }
            break;
        }
        case kSPQueryGetAllChildFilesInFolder:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *folderPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
            NSString *key = [site stringByAppendingString:folderPath];
            NSMutableArray *cache = [self.folderChildrenItemDictionary objectForKey:key];
            if (error) {
                if ([self.delegate respondsToSelector:@selector(allChildItemsInFolderFinishedWithSite:folderPath:items:error:)]) {
                    [self.delegate allChildItemsInFolderFinishedWithSite:site folderPath:folderPath items:nil error:error];
                    if (cache) {
                        [self.folderChildrenItemDictionary removeObjectForKey:key];
                    }
                }
                
            }
            else{
                if (data) {
                    NSArray *fileArray = [NXSharePointXMLParse parseGetChildFiles:data];
                    if (cache) {
                        [cache addObjectsFromArray:fileArray];
                    }
                    else{
                        cache = [NSMutableArray arrayWithArray:fileArray];
                    }
                }
                [self.folderChildrenItemDictionary removeObjectForKey:key];
                if ([self.delegate respondsToSelector:@selector(allChildItemsInFolderFinishedWithSite:folderPath:items:error:)]) {
                    [self.delegate allChildItemsInFolderFinishedWithSite:site folderPath:folderPath items:cache error:nil];
                }
            }
            break;
        }
        case kSPQueryGetContextInfo:
        {
            RemoteQueryResponseHandler handlerBlcok = _remoteQueryResponseHandlers[[[NSNumber alloc] initWithInteger:spQuery.queryID]];
            handlerBlcok(spQuery, data, error);
            break;
        }
        case kSPQueryCreateFolder:
        {
            NSError *retError = nil;
            NSDictionary *item = nil;
            if (error) {
                retError = error;
            }
            else {
                if (data) {
                    item = [NXSharePointXMLParse ParseCreateFolder:data];
                }
            }
            if ([self.delegate respondsToSelector:@selector(createFolderFinishedWithSite:folderName:parentPath:item:error:)]) {
                NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
                NSString *folderName = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_NAME];
                NSString *parentPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
                [self.delegate createFolderFinishedWithSite:site folderName:folderName parentPath:parentPath item:item error:retError];
            }
            break;
        }
        case kSPQueryCreateDocLibrary:
        {
            NSError *retError = nil;
            NSDictionary *item = nil;
            if (error) {
                retError = error;
            }
            else {
                if (data) {
                    item = [NXSharePointXMLParse parseCreateDocumentLib:data];
                }
            }
            if ([self.delegate respondsToSelector:@selector(createDocumentLibFinishedWithSite:name:item:error:)]) {
                NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
                NSString *folderName = [spQuery.additionData objectForKey:SP_DICTION_TAG_DOCUMENTLIB_NAME];
                [self.delegate createDocumentLibFinishedWithSite:site name:folderName item:item error:retError];
            }
            break;
        }
        case kSPQueryDeleteFile:
        {
            if ([self.delegate respondsToSelector:@selector(deleteFileFinishedWithSite:filePath:error:)]) {
                NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
                NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
                [self.delegate deleteFileFinishedWithSite:site filePath:filePath error:error];
            }
            break;
        }
        case kSPQueryDeleteFolder:
        {
            if ([self.delegate respondsToSelector:@selector(deleteFolderFinishedWithSite:relativePath:error:)]) {
                NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
                NSString *folderPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
                [self.delegate deleteFolderFinishedWithSite:site relativePath:folderPath error:error];
            }
            break;
        }
        case kSPQueryAddFile:
        {
            if ([self.delegate respondsToSelector:@selector(addFileFinishedWithSite:fileName:folderPath:localPath:error:)]  ) {
                NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
                NSString *fileName = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_NAME];
                NSString *folderPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
                NSString *localPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_SRC_PATH];
                [self.delegate addFileFinishedWithSite:site fileName:fileName folderPath:folderPath localPath:localPath error:error];
            }
            NSString *dicKey = [self getJsonStringByDictionary:spQuery.additionData];
            [_addFileQueryDictionary removeObjectForKey:dicKey];
            break;
        }
        case kSPQueryUpdateFile:
        {
            if ([self.delegate respondsToSelector:@selector(updateFileFinishedWithSite:filePath:localPath:error:)]) {
                NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
                NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
                NSString *localPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_SRC_PATH];
                [self.delegate updateFileFinishedWithSite:site filePath:filePath localPath:localPath error:error];
            }
            NSString *dicKey = [self getJsonStringByDictionary:spQuery.additionData];
            [_updateFileQueryDictionary removeObjectForKey:dicKey];
            break;
        }
        case kSPQueryRangeDownloadFile:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
            if ([self.delegate respondsToSelector:@selector(rangeDownloadFileFinishedWithSite:filePath:data:error:)]) {
                [self.delegate rangeDownloadFileFinishedWithSite:site filePath:filePath data:data error:error];
            }
            NSMutableDictionary* key = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL]];
            NSString *dicKey = [self getJsonStringByDictionary:key];
            [_rangeDownloadQueryDictionary removeObjectForKey:dicKey];
            break;
        }
        case kSPQueryDownloadFile:
        {
            NSError *retError = nil;
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
            NSString *localPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_DEST_PATH];
            if (error == nil) {
                NSFileManager* fm = [NSFileManager defaultManager];
                if ([fm createFileAtPath:localPath contents:data attributes:nil] == false){
                    retError = [NSError errorWithDomain:@"NXNXFILEDOMAIN" code:10000 userInfo:nil];
                }
            }
            else{
                retError = error;
            }
            if ([self.delegate respondsToSelector:@selector(downloadFileFinishedWithSite:filePath:dstPath:error:)]) {
                [self.delegate downloadFileFinishedWithSite:site filePath:filePath dstPath:localPath error:retError];
            }
            NSMutableDictionary* key = [[NSMutableDictionary alloc] initWithObjects:@[site, filePath, localPath] forKeys:@[SP_DICTION_TAG_SITE, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_DEST_PATH]];
            NSString *dicKey = [self getJsonStringByDictionary:key];
            [_downloadQueryDictionary removeObjectForKey:dicKey];
            break;
        }
        case kSPQueryGetCurrentUserInfo:
        {
            if (error) {
                if ([self.delegate respondsToSelector:@selector(getUserInfoFinishedWithEmail:url:totalstorage:usedstorage:error:)]) {
                    [self.delegate getUserInfoFinishedWithEmail:nil url:nil totalstorage:0 usedstorage:0 error:error];
                }
            }
            else {
                if (data) {
                    NSString * userId = [NXSharePointXMLParse parseGetCurrentUserId:data];
                    if (userId) {
                        [self getCurrentUserDetailInfo:userId];
                    }
                    else{
                        if ([self.delegate respondsToSelector:@selector(getUserInfoFinishedWithEmail:url:totalstorage:usedstorage:error:)]) {
                            NSError * error = [NSError errorWithDomain:@"NXRMCServicesErrorDomain" code:10009 userInfo:nil];
                            [self.delegate getUserInfoFinishedWithEmail:nil url:nil totalstorage:0 usedstorage:0 error:error];
                        }
                    }
                }
                else{
                    if ([self.delegate respondsToSelector:@selector(getUserInfoFinishedWithEmail:url:totalstorage:usedstorage:error:)]) {
                        NSError * error = [NSError errorWithDomain:@"NXRMCServicesErrorDomain" code:10009 userInfo:nil];
                        [self.delegate getUserInfoFinishedWithEmail:nil url:nil totalstorage:0 usedstorage:0 error:error];
                    }
                }
            }
            break;
        }
        case kSPQueryGetCurrentUserDetailInfo:
        {
            if (error) {
                if ([self.delegate respondsToSelector:@selector(getUserInfoFinishedWithEmail:url:totalstorage:usedstorage:error:)]) {
                    [self.delegate getUserInfoFinishedWithEmail:nil url:nil totalstorage:0 usedstorage:0 error:error];
                }
            }
            else {
                NSDictionary *userDetail = [[NSDictionary alloc] init];
                if (data) {
                    userDetail = [NXSharePointXMLParse parseGetUserDetailInfo:data];
                }
                [self getSiteQuota:userDetail];
            }
            break;
        }
        case kSPQueryGetSiteQuota:
        {
            NSString *email = nil;
            if (error) {

            }
            else {
                NSDictionary *siteQuota = nil;
                if (data) {
                    siteQuota = [NXSharePointXMLParse parseSiteQuota:data];
                }
                NSMutableDictionary *storedData = (NSMutableDictionary *) spQuery.additionData;
                if (siteQuota) {
                    [storedData addEntriesFromDictionary:siteQuota];
                }
                else{
                    email = storedData[SP_EMAIL_TAG];
                }
            }
            if ([self.delegate respondsToSelector:@selector(getUserInfoFinishedWithEmail:url:totalstorage:usedstorage:error:)]) {
                [self.delegate getUserInfoFinishedWithEmail:email url:_siteURL totalstorage:0 usedstorage:0 error:nil];
            }
            break;
        }
        case kSPQuerySiteMetaData:
        {
            NSString *site = (NSString *)spQuery.additionData;
            NSDictionary* result = nil;
            NSError *retError = nil;
            if (error) {
                retError = error;
            }
            else if (data) {
                result = [NXSharePointXMLParse parseGetSiteMetaData:data];
            }
            if ([self.delegate respondsToSelector:@selector(getSiteMetaDataFinishedWithSite:item:error:)]) {
                [self.delegate getSiteMetaDataFinishedWithSite:site item:result error:retError];
            }
            break;
        }
        case kSPQueryFolderMetaData:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *folderPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
            NSDictionary* result = nil;
            NSError *retError = nil;
            if (error) {
                retError = error;
            }
            else if (data) {
                result = [NXSharePointXMLParse parseGetFolderMetaData:data];
            }
            if ([self.delegate respondsToSelector:@selector(getFolderMetaDataFinishedWithSite:relativePath:item:error:)]) {
                [self.delegate getFolderMetaDataFinishedWithSite:site relativePath:folderPath item:result error:retError];
            }
            break;
        }
        case kSPQueryFileMetaData:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
            NSDictionary *result = nil;
            NSError *retError = nil;
            if (error) {
                retError = error;
            }
            else if (data){
                result = [NXSharePointXMLParse parseGetFileMetaData:data];
            }
            if ([self.delegate respondsToSelector:@selector(getFileMetaDataFinishedWithSite:filePath:item:error:)]) {
                [self.delegate getFileMetaDataFinishedWithSite:site filePath:filePath item:result error:retError];
            }
            break;
        }
        case kSPQueryFileMetaDataForDownload:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
            NSString *destPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_DEST_PATH];
            NSDictionary *result = nil;
            NSError *retError = nil;
            NSString *strLen = nil;
            if (error) {
                retError = error;
            }
            else {
                if (!data){
                    retError = [NSError errorWithDomain:@"NXRMCServicesErrorDomain" code:10009 userInfo:nil];
                }
                else{
                    result = [NXSharePointXMLParse parseGetFileMetaData:data];
                    strLen = [result objectForKey:SP_EXTERNAL_SIZE_TAG];
                    if (!strLen) {
                        retError = [NSError errorWithDomain:@"NXRMCServicesErrorDomain" code:10009 userInfo:nil];
                    }
                }
                
            }
            if (retError) {
                if ([self.delegate respondsToSelector:@selector(downloadFileFinishedWithSite:filePath:dstPath:error:)]) {
                    [self.delegate downloadFileFinishedWithSite:site filePath:filePath dstPath:destPath error:retError];
                }
            }
            else{
                NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
                format.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *len = [format numberFromString:strLen];
                [self downloadFileWithSize:len site:site filePath:filePath destPath:destPath];
            }
            break;
        }
        default:
            break;
    }
    

    [spQuery.spSession invalidateAndCancel];
    spQuery = nil;
    
}

-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery downloadProcess:(CGFloat)progress{
    NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
    NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
    if (spQuery.queryID == kSPQueryDownloadFile) {
        NSString *localPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_DEST_PATH];
        if ([self.delegate respondsToSelector:@selector(downloadProcessWithSite:filePath:dstPath:progress:)]) {
            [self.delegate downloadProcessWithSite:site filePath:filePath dstPath:localPath progress:progress];
        }
    }
    else if (spQuery.queryID == kSPQueryRangeDownloadFile) {
        if ([self.delegate respondsToSelector:@selector(rangeDownloadProcessWithSite:filePath:progress:)]) {
            [self.delegate rangeDownloadProcessWithSite:site filePath:filePath progress:progress];
        }
    }
}
-(void) remoteQuery:(NXSharePointRemoteQueryBase *)spQuery uploadFileProcess:(CGFloat)progress{
    switch (spQuery.queryID) {
        case kSPQueryUpdateFile:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *filePath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_REV_URL];
            NSString *localPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_SRC_PATH];
            if ([self.delegate respondsToSelector:@selector(updateFileProcessWithSite:filePath:localPath:progress:)]) {
                [self.delegate updateFileProcessWithSite:site filePath:filePath localPath:localPath progress:progress];
            }
            break;
        }
        case kSPQueryAddFile:
        {
            NSString *site = [spQuery.additionData objectForKey:SP_DICTION_TAG_SITE];
            NSString *fileName = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_NAME];
            NSString *folderPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FOLDER_REV_URL];
            NSString *localPath = [spQuery.additionData objectForKey:SP_DICTION_TAG_FILE_SRC_PATH];
            if ([self.delegate respondsToSelector:@selector(addFileProcessWithSite:fileName:folderPath:localPath:progress:)]) {
                [self.delegate addFileProcessWithSite:site fileName:fileName folderPath:folderPath localPath:localPath progress:progress];
            }
            break;
        }
        default:
            break;
    }
}

@end
