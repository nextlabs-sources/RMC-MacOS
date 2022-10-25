//
//  NXHPSPrintUtil.m
//  skyDRM
//
//  Created by helpdesk on 4/7/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXHPSPrintUtil.h"

@implementation NXHPSPrintUtil
+(NSImage*) screenShot:(NSRect)rectd{
    CFArrayRef windowsRef = CGWindowListCreate(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    
    NSRect rect = [[NSScreen mainScreen] frame];
    NSRect mainRect = [NSScreen mainScreen].frame;
    for (NSScreen *subScreen in [NSScreen screens]) {
        if ((int) subScreen.frame.origin.x == 0 && (int) subScreen.frame.origin.y == 0) {
            mainRect = subScreen.frame;
        }
    }
    rect = NSMakeRect(rect.origin.x, (mainRect.size.height) - (rect.origin.y + rect.size.height), rect.size.width, rect.size.height);
    
    CGImageRef imgRef = CGWindowListCreateImageFromArray(rect, windowsRef, kCGWindowImageDefault);
    CFRelease(windowsRef);
    
    
    NSRect mainFrame = [[NSScreen mainScreen] frame];
    NSImage* originImage = [[NSImage alloc] initWithCGImage:imgRef size:mainFrame.size];
    CGImageRelease(imgRef);
    
    [originImage lockFocus];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rectd];
    [path addClip];
    [[NSColor redColor] set];
    
    NSBitmapImageRep *bits = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rectd];
    
    [originImage unlockFocus];
    
    NSDictionary *imageProps = @{NSImageCompressionFactor : @(1.0)};
    
    NSData *imageData = [bits representationUsingType:NSJPEGFileType properties:imageProps];
    NSImage *pasteImage = [[NSImage alloc] initWithData:imageData];
    return pasteImage;
}
@end
