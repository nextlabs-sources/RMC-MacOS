//
//  NXLSDKDef.h
//  skyDRM
//
//  Created by qchen on 2020/2/6.
//  Copyright © 2020 nextlabs. All rights reserved.
//

#ifndef NXLSDKDef_h
#define NXLSDKDef_h

#define WeakObj(obj) __weak typeof(obj) obj##Weak = obj;
#define StrongObj(obj) __strong typeof(obj) obj = obj##Weak;

#endif /* NXLSDKDef_h */
