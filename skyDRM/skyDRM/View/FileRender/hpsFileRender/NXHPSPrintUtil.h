//
//  NXHPSPrintUtil.h
//  skyDRM
//
//  Created by helpdesk on 4/7/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
static const void* NXHPSViewKey = "NXHPSViewKey";

@interface NXHPSPrintUtil : NSObject
+(NSImage*) screenShot:(NSRect)rect;
@end
