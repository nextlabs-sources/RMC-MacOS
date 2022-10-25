//
//  NXHPSProgressBarController.h
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NXHPSProgressBarView.h"
#import "NXSprocketsView.h"
#include "hps.h"
#include "sprk.h"

typedef void(^progressLoadingCompletedBlock)(id sender);

@interface NXHPSProgressBarWindow : NSWindow
@end

//deprecated for now 5/3/2017
@interface NXHPSProgressBarController : NSWindowController
{
    HPS::IONotifier notifier;
    HPS::Model model;
    
    NSString* path;
}
    
    @property(nonatomic,assign) bool is_export;
    @property(nonatomic,assign) bool was_canceled;

-(void) PerformInitialUpdate;
-(void) onTimerTick:(NSTimer *)theTimer;
-(bool) wasCanceled;
-(void) setIsExport:(bool)in_is_export;
- (IBAction)CancelImport:(id)sender;

-(void) SetNotifier:(HPS::IONotifier)in_notifier;
-(void) SetSprocketView:(SprocketsView *)in_view;
-(void) SetHPSModel: (HPS::Model)in_model;
-(void) SetIsExport:(bool)in_is_export;

-(void) setFilePath: (NSString*) file_path;

@property (strong) NSTimer* repeating_timer;
@property (strong) SprocketsView* view;
@property (strong) NXHPSProgressBarWindow *progress_bar_window;

@property(nonatomic, strong) progressLoadingCompletedBlock clickBlock;

@end
