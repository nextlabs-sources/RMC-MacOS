//
//  NXSPAuthViewController.h
//  SharepointOnlineSDK
//
//  Created by nextlabs on 22/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NXSharePointManager.h"
#import "NXSharepointOnlineAuthentication.h"

@interface NXSPAuthViewController : NSViewController
- (id)init:(NSString *)keychain
    completion:(void(^)(NXSharePointManager *, NXSharePointOnlineUser *, NSError *error))handler;
+ (NXSharePointManager *)authFromKeychain:(NSString *)keychain;
+ (void)removeFromKeyChain:(NSString *)keychain;
+ (void)saveAuthToKeyChain:(NSString *)keychain
                       url:(NSString *)url
                   fedAuth:(NSString *)fedAuth
                      rtfa:(NSString *)rtfa;
@end
