//
//  NXHPSProgressBarView.h
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NXSprocketsView.h"
#import "hps.h"

//deprecated for now 5/3/2017
@interface NXHPSProgressBarView : NSView
{
    bool progress_bar_started;
}

-(void) CheckProgressBar;
-(void) UpdateProgressLabel: (NSString*)message progress:(int)percentage;
-(void) UpdateProgressLabel: (NSString*)message;


@property (strong) IBOutlet NSProgressIndicator* progress_bar;
@property (strong) IBOutlet NSTextField* label;

@end
