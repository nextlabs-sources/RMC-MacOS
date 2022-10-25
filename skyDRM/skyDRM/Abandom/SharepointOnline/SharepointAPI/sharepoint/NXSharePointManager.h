//
//  NXSharePointSDK.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/21.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXSharePointDelegateProtocol.h"
#import "NXSharePointRestTemp.h"
#import "NXSharePointRemoteQuery.h"
#import "NXSharepointOnlineRemoteQuery.h"
#import "NXXMLDocument.h"


typedef enum{
    kSPMgrSharePoint = 1,
    kSPMgrSharePointOnline,
    
} SPManagerType;

@interface NXSharePointManager : NSObject<NXSharePointQueryDelegate>
@property(nonatomic, strong) id<NXSharePointManagerDelegate> delegate;
@property(nonatomic, strong) NSString* siteURL;
@property(nonatomic, strong) NSString* serverName;
@property(nonatomic) SPManagerType spMgrType;

-(instancetype) initWithSiteURL:(NSString*) siteURL userName:(NSString*) userName passWord:(NSString*) psw Type:(SPManagerType) type;
-(instancetype) initWithURL:(NSString *)siteURL cookies:(NSArray *)cookies Type:(SPManagerType)type;


//pragma mark - new interface
-(void) allChildItemsWithSite:(NSString *)site; // (subSites + doc lists)
-(void) allChildItemsInFolderWithSite:(NSString *)site
                       folderPath:(NSString *)folderPath;
-(void) createFolderWithSite:(NSString *)site
                  folderName:(NSString *)folderName
                  parentPath:(NSString *)parentPath;
-(void) createDocumentLibWithSite:(NSString *)site
              documentLibName:(NSString *)documentLibName;
-(void) deleteFileWithSite:(NSString *)site
                  filePath:(NSString *)filePath;
-(void) deleteFolderOrDocumentlibWithSite:(NSString *)site
                             relativePath:(NSString *)relativePath;
-(void) downloadFileWithSite:(NSString *)site
                    filePath:(NSString *)filePath
                    destPath:(NSString *)destPath;
-(void) downloadFileWithSite:(NSString *)site
                    filePath:(NSString *)filePath
                       range:(NSRange) range;
-(BOOL) cancelDownloadFileWithSite:(NSString *)site
                         filePath:(NSString *)filePath
                         destPath:(NSString *)destPath;
-(BOOL) cancelRangeDownloadFileWithSite:(NSString *)site
                               filePath:(NSString *)filePath;
//-(void) cancelDownloadFile:(NXSharePointFile*) spFile;
//pragma mark - need to add file info for add file and update file 
-(void) addFileWithSite:(NSString *)site
               fileName:(NSString *)fileName
             folderPath:(NSString *)folderPath
               localPath:(NSString*)localPath;
-(BOOL) cancelAddFileWithSite:(NSString *)site
               fileName:(NSString *)fileName
             folderPath:(NSString *)folderPath
              localPath:(NSString*)localPath;
-(void) updateFileWithSite:(NSString *)site
                  filePath:(NSString *)filePath
                 localPath:(NSString *) localPath;
    
-(BOOL) cancelUpdateFileWithSite:(NSString *)site
                  filePath:(NSString *)filePath
                 localPath:(NSString *) localPath;
    
// get user info
- (void) getCurrentUserInfo;
- (void) getSiteMetaDataWithSite:(NSString *)site;
- (void) getFolderMeataDataWithSite:(NSString *)site
                       relativePath:(NSString *)relativePath;
- (void) getFileMetaDataWithSite:(NSString *)site
                        filePath:(NSString *)filePath;
@end
