//
//  NXHPSProgressBarView.m
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXHPSProgressBarView.h"
#import "sprk.h"
#ifdef USING_EXCHANGE
#include "sprk_exchange.h"
#endif
//deprecated for now 5/3/2017
@implementation NXHPSProgressBarView

-(void) CheckProgressBar
{
    if (!progress_bar_started)
    {
        [self.progress_bar setIndeterminate:YES];
        [self.progress_bar setUsesThreadedAnimation:YES];
        [self.progress_bar startAnimation:self.progress_bar];
        progress_bar_started = true;
    }
}

-(void) UpdateProgressLabel:(NSString *)message progress:(int)percentage
{
    [self.label setStringValue:[NSString stringWithFormat:@"%@ %d", message, percentage]];
}

-(void) UpdateProgressLabel:(NSString *)message
{
    [self.label setStringValue:message];
}

-(id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        progress_bar_started = false;
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

@end
