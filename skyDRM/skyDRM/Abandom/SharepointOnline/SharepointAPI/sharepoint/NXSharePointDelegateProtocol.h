//
//  NXSharePointDelegateProtocol.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/25.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#ifndef RecordWebRequest_NXSharePointDelegateProtocol_h
#define RecordWebRequest_NXSharePointDelegateProtocol_h

#import <Foundation/Foundation.h>

//////////////////////////////////////NXSharePointManager define
typedef enum
{
    kSPQueryGetAllDocLists = 1,
    kSPQueryGetAllChildFoldersInFolder,
    kSPQueryGetAllChildFilesInFolder,
    kSPQueryGetAllChildFilesInRootFolder,
    kSPQueryGetAllChildFoldersInRootFolder,
    kSPQueryGetAllChildSites,
    kSPQueryGetAllItemsInSite,
    kSPQueryGetAllItemsInFolder,
    kSPQueryGetFilesEnd,   // end
    /////NOTE!!! THE END OF GET FILE ENUM!!!!!!!//////////
    kSPQueryCheckFolderExistForGetFiles,
    kSPQueryCheckListExistForGetFiles,
    kSPQueryCheckSiteExistForGetFiles,
    kSPQueryFileMetaData,
    kSPQueryFileMetaDataForDownload,
    kSPQueryListMetaData,
    kSPQueryFolderMetaData,
    kSPQuerySiteMetaData,
    kSPQueryGetFileFolderDataInfoEnd,
    /////NOTE!!!!THE END OF GET FILE , FOLDER DATA INFO!!!!!!////////
    kSPQueryDownloadFile,
    kSPQueryRangeDownloadFile,
    kSPQueryAuthentication,
    kSPQueryAddFile,
    kSPQueryUpdateFile,
    kSPQueryGetContextInfo,
    kSPQueryGetCurrentUserInfo,
    kSPQueryGetCurrentUserDetailInfo,
    kSPQueryGetSiteQuota,
    kSPQueryCreateFolder,
    kSPQueryCreateDocLibrary,
    kSPQueryDeleteFile,
    kSPQueryDeleteFolder,
}SPQueryIdentify;

#define SP_DICTION_TAG_SITE @"site"
#define SP_DICTION_TAG_DOCUMENTLIB_NAME @"documentLibName"
#define SP_DICTION_TAG_FOLDER_NAME @"folderName"
#define SP_DICTION_TAG_FILE_NAME @"fileName"
#define SP_DICTION_TAG_FILE_SIZE @"fileSize"
#define SP_DICTION_TAG_REQ_TYPE @"requestType"
#define SP_DICTION_TAG_FILE_REV_URL @"fileRelativeURL"
#define SP_DICTION_TAG_FILE_SRC_PATH @"fileSrcPath"
#define SP_DICTION_TAG_BASEFILE      @"baseFile"
#define SP_DICTION_TAG_IS_ROOT_FOLDER @"IsRootFolder"
#define SP_DICTION_TAG_UPLOAD_TYPE @"uploadType"
#define SP_DICTION_TAG_FOLDER_REV_URL @"folderRelativeURL"
#define SP_DICTION_TAG_FILE_DEST_PATH @"destPath"
#define SP_DICTION_TAG_FORM_DIGEST @"formDigest"

//////////////////////////////////////NXSharePointXMLParse define
#define SP_EXTERNAL_NAME_TAG @"ExternalName"
#define SP_EXTERNAL_LAST_MODIFIED_DATE_TAG @"ExternalLastModifiedDate"
#define SP_EXTERNAL_RELATIVEPATH_TAG @"ExternalRelativePath"
#define SP_EXTERNAL_SITE_TAG @"ExternalSite"
#define SP_EXTERNAL_SIZE_TAG @"ExteranlSize"

#define SP_ENTRY_TAG  @"entry"
#define SP_PROPERTY_TAG @"properties"
#define SP_HIDDEN_TAG @"Hidden"
#define SP_ID_TAG @"Id"
#define SP_id_TAG @"id"
#define SP_CREATED_TAG @"Created"
#define SP_LAST_ITEM_MODIFID_DATE @"LastItemModifiedDate"
#define SP_PARENT_WEB_URL @"ParentWebUrl"
#define SP_TITLE_TAG @"Title"
#define SP_CONTENT_TAG @"content"
#define SP_D_TAG @"d"
#define SP_NAME_TAG @"Name"
#define SP_SERV_RELT_URL_TAG @"ServerRelativeUrl"
#define SP_CONTENT_VERSION_TAG @"ContentTag"
#define SP_FILE_SIZE_TAG @"Length"
#define SP_TIME_LAST_MODIFY @"TimeLastModified"
#define SP_URL_TAG @"Url"
#define SP_DOC_LIB_TEMP_TYPE @"101"
#define SP_CONTEXT_WEB_INFO_TAG @"GetContextWebInformation"
#define SP_FORM_DIGEST_TAG @"FormDigestValue"
#define SP_EMAIL_TAG @"EMail"
#define SP_USAGE_TAG @"Usage"
#define SP_STORAGE_TAG @"Storage"
#define SP_STORAGE_USED_TAG @"StorageUsed"
#define SP_STORAGE_PERCENT_USAGE @"StoragePercentageUsed"
// used to identify the type of node
#define SP_NODE_TYPE @"SPNodeType"
#define SP_NODE_SITE @"SITE"
#define SP_NODE_DOC_LIST @"DOC_LIST"
#define SP_NODE_FOLDER @"FOLDER"
#define SP_NODE_FILE @"FILE"



@class NXSharePointRemoteQueryBase;

// NOTE: the delegate called in subthread, if operate UIKit, we need change them into main thread!!!!!!
@protocol NXSharePointQueryDelegate<NSObject>

@required
-(void) remoteQuery:(NXSharePointRemoteQueryBase *) spQuery didCompleteQuery:(NSData *) data error:(NSError *)error;
-(void) remoteQuery:(NXSharePointRemoteQueryBase *) spQuery downloadProcess:(CGFloat)progress;
-(void) remoteQuery:(NXSharePointRemoteQueryBase *)spQuery uploadFileProcess:(CGFloat)progress;
@end

@protocol NXSharePointManagerDelegate <NSObject>
@optional
//pragma mark - new interface
-(void) allChildItemsFinishedWithSite:(NSString *)site
                                items:(NSArray *)items
                                error:(NSError *)error;
-(void) allChildItemsInFolderFinishedWithSite:(NSString *)site
                                   folderPath:(NSString *)folderPath
                                        items:(NSArray *)items
                                        error:(NSError *)error;
-(void) downloadFileFinishedWithSite:(NSString *)site
                            filePath:(NSString *)filePath
                             dstPath:(NSString *)dstPath
                               error:(NSError *)error;
-(void) rangeDownloadFileFinishedWithSite:(NSString *)site
                                 filePath:(NSString *)filePath
                                     data:(NSData *)data
                                    error:(NSError *)error;
-(void) downloadProcessWithSite:(NSString *)site
                       filePath:(NSString *)filePath
                        dstPath:(NSString *)dstPath
                       progress:(CGFloat)progress;
-(void) rangeDownloadProcessWithSite:(NSString *)site
                            filePath:(NSString *)filePath
                            progress:(CGFloat)progress;
-(void) addFileFinishedWithSite:(NSString *)site
                       fileName:(NSString *)fileName
                     folderPath:(NSString *)folderPath
                      localPath:(NSString *)localPath
                          error:(NSError *)error;
-(void) updateFileFinishedWithSite:(NSString *)site
                          filePath:(NSString *)filePath
                         localPath:(NSString *)localPath
                             error:(NSError *)error;
-(void) addFileProcessWithSite:(NSString *)site
                      fileName:(NSString *)fileName
                    folderPath:(NSString *)folderPath
                     localPath:(NSString *)localPath
                      progress:(CGFloat)progress;
-(void) updateFileProcessWithSite:(NSString *)site
                         filePath:(NSString *)filePath
                        localPath:(NSString *)localPath
                         progress:(CGFloat)progress;
-(void) getUserInfoFinishedWithEmail:(NSString *)email
                                 url:(NSString *)url
                        totalstorage:(long long)totalstorage
                         usedstorage:(long long)usedstorage
                               error:(NSError *) error;
-(void) deleteFolderFinishedWithSite:(NSString *)site
                        relativePath:(NSString *)relativePath
                               error:(NSError *)error;
-(void) deleteFileFinishedWithSite:(NSString *)site
                          filePath:(NSString *)filePath
                             error:(NSError *)error;
-(void) createFolderFinishedWithSite:(NSString *)site
                          folderName:(NSString *)folderName
                          parentPath:(NSString *)parentPath
                                item:(NSDictionary *)item
                               error:(NSError *)error;
-(void) createDocumentLibFinishedWithSite:(NSString *)site
                                     name:(NSString *)name
                                     item:(NSDictionary *)item
                                    error:(NSError *)error;
-(void) getSiteMetaDataFinishedWithSite:(NSString *)site
                                   item:(NSDictionary *)item
                                  error:(NSError *)error;
-(void) getFolderMetaDataFinishedWithSite:(NSString *)site
                             relativePath:(NSString *)relativePath
                                     item:(NSDictionary *)item
                                    error:(NSError *)error;
-(void) getFileMetaDataFinishedWithSite:(NSString *)site
                               filePath:(NSString *)filePath
                                   item:(NSDictionary *)item
                                  error:(NSError *)error;
@end
#endif
