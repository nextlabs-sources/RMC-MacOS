//
//  NXHPSLoadingView.h
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/3/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NXSprocketsView.h"
#include "hps.h"
#include "sprk.h"
@interface NXHPSLoadingView : NSView
{
    HPS::IONotifier notifier;
    bool is_export;
    bool was_canceled;
    bool is_hsf;
    HPS::Model model;
    
    NSString* path;
}

+ (NSView*)createLoadingView:(NSView*)superView;

-(void) PerformInitialUpdate;
-(void) onTimerTick:(NSTimer *)theTimer;
-(bool) wasCanceled;
-(void) setIsExport:(bool)in_is_export;

-(void) SetNotifier:(HPS::IONotifier)in_notifier;
-(void) SetSprocketView:(SprocketsView *)in_view;
-(void) SetHPSModel: (HPS::Model)in_model;
-(void) SetIsExport:(bool)in_is_export;
-(void) SetIsHsf:(bool)is_hsf;

-(void) setFilePath: (NSString*) file_path;

@property (strong) NSTimer* repeating_timer;
@property (strong) SprocketsView* view;
@property (strong) IBOutlet NSProgressIndicator *progress_bar;

@end
