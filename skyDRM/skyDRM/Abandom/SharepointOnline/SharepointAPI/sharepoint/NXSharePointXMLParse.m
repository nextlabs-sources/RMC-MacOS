//
//  NXSharePointXMLParse.m
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/26.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//



#import "NXSharePointXMLParse.h"
#import "NXXMLDocument.h"
#import "NXSharePointDelegateProtocol.h"

@implementation NXSharePointXMLParse
+(NSArray*) parseGetDocLibLists:(NSData*) data
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NSArray* entryArray = [root childrenNamed:SP_ENTRY_TAG];
    for (NXXMLElement* entryNode in entryArray) {
        NXXMLElement* contentNode = [entryNode childNamed:SP_CONTENT_TAG];
        if (contentNode) {
            NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
            if (propertiesNode) {
                
                NXXMLElement* titleNode = [propertiesNode childNamed:SP_TITLE_TAG];
                NXXMLElement* hiddenNode = [propertiesNode childNamed:SP_HIDDEN_TAG];
                NXXMLElement* lastModifyTimeNode = [propertiesNode childNamed:SP_LAST_ITEM_MODIFID_DATE];
                NXXMLElement *parentWebURL = [propertiesNode childNamed:SP_PARENT_WEB_URL];
                // only display not hidden list
                if (![hiddenNode.value isEqualToString:@"true"]) {
                    if (titleNode.value && lastModifyTimeNode.value && parentWebURL.value) {
                        NSString *localString = [NSString stringWithFormat:@"%@/%@", parentWebURL.value, titleNode.value];
                        NSDictionary* dic = [NSDictionary dictionaryWithObjects:@[titleNode.value, SP_NODE_DOC_LIST, lastModifyTimeNode.value, localString] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_NODE_TYPE, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG, SP_EXTERNAL_RELATIVEPATH_TAG]];
                        [retArray addObject:dic];
                    }
                }
            }
        }
    }
    
    // sometimes, NSXMLParser delegate method is not called by IOS.Why?(do not know).
    // so we should check root here(if delegate is called, root will not be nil)
    if (!root) {
        return [self parseGetDocLibLists:data];
    }
    return [retArray copy];
}

+(NSArray*) parseGetChildFolders:(NSData*) data
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NSArray* entryArray = [root childrenNamed:SP_ENTRY_TAG];
    for (NXXMLElement* entryNode in entryArray) {
        NXXMLElement* contentNode = [entryNode childNamed:SP_CONTENT_TAG];
        if (contentNode) {
            NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
            if (propertiesNode) {
                
                NXXMLElement* nameNode = [propertiesNode childNamed:SP_NAME_TAG];
                NXXMLElement* serverRelativeUrlNode = [propertiesNode childNamed:SP_SERV_RELT_URL_TAG];
                NXXMLElement* modifiedTimeNode = [propertiesNode childNamed:SP_TIME_LAST_MODIFY];
                if (nameNode.value && serverRelativeUrlNode.value && modifiedTimeNode.value) {
                    NSDictionary* dic = [NSDictionary dictionaryWithObjects:@[nameNode.value, serverRelativeUrlNode.value, modifiedTimeNode.value, SP_NODE_FOLDER] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG, SP_NODE_TYPE]];
                    [retArray addObject:dic];
                    
                }
            }
            
        }
    }
    
    // sometimes, NSXMLParser delegate method is not called by IOS.Why?(do not know).
    // so we should check root here(if delegate is called, root will not be nil)
    if (!root) {
        return [self parseGetChildFolders:data];
    }

    return [retArray copy];
}

+(NSArray*) parseGetChildFiles:(NSData*) data
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NSArray* entryArray = [root childrenNamed:SP_ENTRY_TAG];
    for (NXXMLElement* entryNode in entryArray) {
        NXXMLElement* contentNode = [entryNode childNamed:SP_CONTENT_TAG];
        if (contentNode) {
            NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
            if (propertiesNode) {
                
                NXXMLElement* nameNode = [propertiesNode childNamed:SP_NAME_TAG];
                NXXMLElement* serverRelativeUrlNode = [propertiesNode childNamed:SP_SERV_RELT_URL_TAG];
                NXXMLElement* fileLength = [propertiesNode childNamed:SP_FILE_SIZE_TAG];
                NXXMLElement* timeLastModified = [propertiesNode childNamed:SP_TIME_LAST_MODIFY];
                if (nameNode.value && serverRelativeUrlNode.value && fileLength.value && timeLastModified.value) {
                    NSDictionary* dic = [NSDictionary dictionaryWithObjects:@[nameNode.value, serverRelativeUrlNode.value, fileLength.value, SP_NODE_FILE, timeLastModified.value] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG, SP_EXTERNAL_SIZE_TAG, SP_NODE_TYPE, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG]];
                    [retArray addObject:dic];
                }
            }
            
        }
    }
    
    // sometimes, NSXMLParser delegate method is not called by IOS.Why?(do not know).
    // so we should check root here(if delegate is called, root will not be nil)
    if (!root) {
        return [self parseGetChildFiles:data];
    }

    return [retArray copy];
}
+(NSDictionary *)parseCreateDocumentLib:(NSData *)data
{
    NSDictionary* retDict = nil;
    NSError *error = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (dic) {
        NSDictionary *dNode = [dic objectForKey:SP_D_TAG];
        if (dNode) {
            NSString *title = [dNode objectForKey:SP_TITLE_TAG];
            NSString *parentWebURL = [dNode objectForKey:SP_SERV_RELT_URL_TAG];
            NSString *timeLastModified = [dNode objectForKey:SP_LAST_ITEM_MODIFID_DATE];
            if (title && parentWebURL && timeLastModified) {
                NSString *fullPath = [parentWebURL stringByAppendingPathComponent:title];
                retDict = [NSDictionary dictionaryWithObjects:@[title, fullPath, timeLastModified, SP_NODE_DOC_LIST] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG, SP_NODE_TYPE]];
            }
        }
    }

    
    return [retDict copy];

}

+(NSDictionary *) ParseCreateFolder:(NSData *)data
{
    NSDictionary* retDict = nil;
    NSError *error = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (dic) {
        NSDictionary *dNode = [dic objectForKey:SP_D_TAG];
        if (dNode) {
            NSString *name = [dNode objectForKey:SP_NAME_TAG];
            NSString *serverRelativeUrl = [dNode objectForKey:SP_SERV_RELT_URL_TAG];
            NSString *timeLastModified = [dNode objectForKey:SP_TIME_LAST_MODIFY];
            if (name && serverRelativeUrl && timeLastModified) {
                retDict = [NSDictionary dictionaryWithObjects:@[name, serverRelativeUrl, timeLastModified, SP_NODE_FOLDER] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG, SP_NODE_TYPE]];
            }
        }
    }
    
    return [retDict copy];
}
+(NSDictionary*) parseGetFileMetaData:(NSData*) data
{
    NSDictionary* retDict = nil;
    
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
        if (propertiesNode) {
            
            NXXMLElement* nameNode = [propertiesNode childNamed:SP_NAME_TAG];
            NXXMLElement* serverRelativeUrlNode = [propertiesNode childNamed:SP_SERV_RELT_URL_TAG];
            NXXMLElement* fileLength = [propertiesNode childNamed:SP_FILE_SIZE_TAG];
            NXXMLElement* timeLastModified = [propertiesNode childNamed:SP_TIME_LAST_MODIFY];
            if (nameNode.value && serverRelativeUrlNode.value && fileLength.value && timeLastModified.value) {
                retDict = [NSDictionary dictionaryWithObjects:@[nameNode.value, serverRelativeUrlNode.value, fileLength.value, SP_NODE_FILE, timeLastModified.value] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG,  SP_EXTERNAL_SIZE_TAG, SP_NODE_TYPE, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG]];
            }
        }
        
    }
    if (!root) {
        return [self parseGetFileMetaData:data];
    }

    return [retDict copy];
}

+(NSDictionary*) parseGetFolderMetaData:(NSData*) data
{
    NSDictionary* retDict = nil;

    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
  
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
            if (propertiesNode) {
                
                NXXMLElement* nameNode = [propertiesNode childNamed:SP_NAME_TAG];
                NXXMLElement* serverRelativeUrlNode = [propertiesNode childNamed:SP_SERV_RELT_URL_TAG];
                NXXMLElement* timeLastModified = [propertiesNode childNamed:SP_TIME_LAST_MODIFY];
                if (nameNode.value && serverRelativeUrlNode.value && timeLastModified.value) {
                    retDict = [NSDictionary dictionaryWithObjects:@[nameNode.value, serverRelativeUrlNode.value, timeLastModified.value, SP_NODE_FOLDER] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG, SP_NODE_TYPE]];
                    
                }
            }
            
    }
    if (!root) {
        return [self parseGetFileMetaData:data];
    }
    return [retDict copy];
}

+(NSDictionary*) parseGetListMetaData:(NSData*) data
{
    NSDictionary* retDict = nil;
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
        if (propertiesNode) {
            NXXMLElement* titleNode = [propertiesNode childNamed:SP_TITLE_TAG];
            NXXMLElement* hiddenNode = [propertiesNode childNamed:SP_HIDDEN_TAG];
            NXXMLElement* idNode = [propertiesNode childNamed:SP_ID_TAG];
            NXXMLElement* modifiedTimeNode = [propertiesNode childNamed:SP_LAST_ITEM_MODIFID_DATE];
            // only display not hidden list
            if (![hiddenNode.value isEqualToString:@"true"]) {
                if (titleNode.value && idNode.value && modifiedTimeNode.value) {
                    retDict = [NSDictionary dictionaryWithObjects:@[titleNode.value, SP_NODE_DOC_LIST, idNode.value, modifiedTimeNode.value] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_NODE_TYPE, SP_ID_TAG, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG]];
                }
            }
        }
    }
    
    if (!root) {
        return [self parseGetFileMetaData:data];
    }
    return [retDict copy];
}

+(NSDictionary*) parseGetSiteMetaData:(NSData*) data
{
    NSDictionary* retDict = nil;
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
        if (propertiesNode) {
            NXXMLElement* titleNode = [propertiesNode childNamed:SP_TITLE_TAG];
            NXXMLElement* siteURLNode = [propertiesNode childNamed:SP_URL_TAG];
            NXXMLElement* modifiedTimeNode = [propertiesNode childNamed:SP_LAST_ITEM_MODIFID_DATE];
            
            if (titleNode.value && siteURLNode.value && modifiedTimeNode.value) {
               retDict = [NSDictionary dictionaryWithObjects:@[titleNode.value, siteURLNode.value, SP_NODE_SITE, modifiedTimeNode.value] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_SITE_TAG, SP_NODE_TYPE, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG]];
            }
        }
    }
    if (!root) {
        return [self parseGetFileMetaData:data];
    }
    return [retDict copy];
}

+(NSString *) parseGetCurrentUserId:(NSData *) data
{
  
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
        if (propertiesNode) {
            NXXMLElement* idNode = [propertiesNode childNamed:SP_ID_TAG];
            if (idNode) {
                return idNode.value;
            }
        }
    }
    return nil;
}

+(NSDictionary *) parseGetUserDetailInfo:(NSData *) data
{
    NSMutableDictionary *retDict = [[NSMutableDictionary alloc] init];
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
        if (propertiesNode) {
            NXXMLElement *nameNode = [propertiesNode childNamed:SP_TITLE_TAG];
            NXXMLElement *emailNode = [propertiesNode childNamed:SP_EMAIL_TAG];
            if (nameNode.value) {
                [retDict setObject:nameNode.value forKey:SP_TITLE_TAG];
            }
            
            if (emailNode.value) {
                [retDict setObject:emailNode.value forKey:SP_EMAIL_TAG];
            }
        }
    }
    return retDict;
}

+(NSArray*) parseUploadFile:(NSData*) data
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NXXMLElement* contentNode = [root childNamed:SP_CONTENT_TAG];
    
    if (contentNode) {
        NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
        if (propertiesNode) {
            NXXMLElement* nameNode = [propertiesNode childNamed:SP_NAME_TAG];
            NXXMLElement* serverRelativeUrlNode = [propertiesNode childNamed:SP_SERV_RELT_URL_TAG];
            NXXMLElement* fileLength = [propertiesNode childNamed:SP_FILE_SIZE_TAG];
            NXXMLElement* timeLastModified = [propertiesNode childNamed:SP_TIME_LAST_MODIFY];
            
            if (nameNode.value && serverRelativeUrlNode.value && fileLength.value && timeLastModified.value) {
                NSDictionary *dic = [NSDictionary dictionaryWithObjects:@[nameNode.value, serverRelativeUrlNode.value, fileLength.value, SP_NODE_FILE, timeLastModified.value] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_RELATIVEPATH_TAG, SP_EXTERNAL_SIZE_TAG, SP_NODE_TYPE, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG]];
                [retArray addObject:dic];
            }
        }
    }
    
    if (!root) {
        return [self parseUploadFile:data];
    }
    
    return [retArray copy];
}

+(NSArray*) parseGetChildSites:(NSData*) data
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement* root = xmlDoc.root;
    NSArray* entryArray = [root childrenNamed:SP_ENTRY_TAG];
  
    for (NXXMLElement* entryNode in entryArray) {
        
        NXXMLElement* contentNode = [entryNode childNamed:SP_CONTENT_TAG];
        if (contentNode) {
            NXXMLElement* propertiesNode = [contentNode childNamed:SP_PROPERTY_TAG];
            if (propertiesNode) {
                
                NXXMLElement* titleNode = [propertiesNode childNamed:SP_TITLE_TAG];
                NXXMLElement* siteURLNode = [propertiesNode childNamed:SP_URL_TAG];
                NXXMLElement* modifiedTimeNode = [propertiesNode childNamed:SP_LAST_ITEM_MODIFID_DATE];
                NXXMLElement* siteRelativeURLNode = [propertiesNode childNamed:SP_SERV_RELT_URL_TAG];
                
                if (titleNode.value && siteURLNode.value && modifiedTimeNode.value && siteRelativeURLNode.value) {
                    NSDictionary* dic = [NSDictionary dictionaryWithObjects:@[titleNode.value, siteURLNode.value, SP_NODE_SITE, modifiedTimeNode.value, siteRelativeURLNode.value] forKeys:@[SP_EXTERNAL_NAME_TAG, SP_EXTERNAL_SITE_TAG, SP_NODE_TYPE, SP_EXTERNAL_LAST_MODIFIED_DATE_TAG, SP_EXTERNAL_RELATIVEPATH_TAG]];
                    [retArray addObject:dic];
                    
                }
            }
        }
    }
    
    // sometimes, NSXMLParser delegate method is not called by IOS.Why?(do not know).
    // so we should check root here(if delegate is called, root will not be nil)
    if (!root) {
        return [self parseGetChildSites:data];
    }

    return [retArray copy];
}

+(NSDictionary *) parseSiteQuota:(NSData *) data
{
    NSMutableDictionary *retDict = [[NSMutableDictionary alloc] init];
    NXXMLDocument *xmlDoc = [NXXMLDocument documentWithData:data error:nil];
    NXXMLElement *root = xmlDoc.root;
    NXXMLElement *siteStorage= [root childNamed:SP_STORAGE_TAG];
    NXXMLElement *siteStoragePercentageUsed = [root childNamed:SP_STORAGE_PERCENT_USAGE];
    
    NSNumberFormatter *numFormat = [[NSNumberFormatter alloc] init];
    numFormat.numberStyle = NSNumberFormatterDecimalStyle;
    if (siteStorage.value) {
        NSNumber *storage = [numFormat numberFromString:siteStorage.value];
        [retDict setObject:storage forKey:SP_STORAGE_TAG];
        
        if (siteStoragePercentageUsed.value) {
            NSNumber *percentageUsed = [numFormat numberFromString:siteStoragePercentageUsed.value];
            int usedStorage = storage.doubleValue * percentageUsed.doubleValue;
            NSNumber *usedStorageNum = [NSNumber numberWithInt:usedStorage];
            [retDict setObject:usedStorageNum forKey:SP_STORAGE_USED_TAG];
        }
    }
    return retDict;
}

+(NSArray*) parseContextInfo:(NSData*) data
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    
    NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:data error:nil];
   
    
    NXXMLElement* root = xmlDoc.root;
    if (root) {
        NXXMLElement* formDigestValue = [root childNamed:SP_FORM_DIGEST_TAG];
        if (formDigestValue.value) {
            NSDictionary* dic = [NSDictionary dictionaryWithObject:formDigestValue.value forKey:SP_FORM_DIGEST_TAG];
            [retArray addObject:dic];

        }
        return [retArray copy];
    }else
    {
        return [self parseContextInfo:data];
    }
    
}
@end
