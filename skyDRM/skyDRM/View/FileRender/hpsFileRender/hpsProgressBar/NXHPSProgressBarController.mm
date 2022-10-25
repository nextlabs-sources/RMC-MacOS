//
//  NXHPSProgressBarController.m
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXHPSProgressBarController.h"
//deprecated for now 5/3/2017
@interface NXHPSProgressBarController ()

@end

@implementation NXHPSProgressBarController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.repeating_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
    }
    
    self.is_export = false;
    self.was_canceled = false;
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (void) PerformInitialUpdate
{
    [self.repeating_timer invalidate];
    //[self.repeating_timer release];
    HPS::Canvas canvas = [self.view GetCanvas];
    HPS::View view = canvas.GetFrontView();
    
    model.GetSegmentKey().GetPerformanceControl().SetStaticModel(HPS::Performance::StaticModel::Attribute);
    view.AttachModel(model);
    
    if (notifier.Type() == HPS::Type::StreamImportNotifier) {
        HPS::CameraKit default_camera;
        HPS::Stream::ImportResultsKit stream_import_results = static_cast<HPS::Stream::ImportNotifier>(notifier).GetResults();
        
        if (stream_import_results.ShowDefaultCamera(default_camera)) {
            view.GetSegmentKey().SetCamera(default_camera);
        }else{
            view.FitWorld();
        }
    }else{
        view.FitWorld();
    }

    [[self.window contentView] UpdateProgressLabel:@"Performing Initial Update..."];
    canvas.UpdateWithNotifier(HPS::Window::UpdateType::Exhaustive).Wait();
    canvas.UpdateWithNotifier(HPS::Window::UpdateType::Exhaustive).Wait();
}

- (void) onTimerTick:(NSTimer *)theTimer
{
    if (notifier.Type() != HPS::Type::None) {
        [[self.window contentView] CheckProgressBar];
        
        float complete;
        HPS::IOResult status;
        status = notifier.Status(complete);
        
        int progress = static_cast<int>(complete * 100.0f + 0.5f);
        [[self.window contentView] UpdateProgressLabel:@"Percentage Complete" progress:progress];
        
        if (status != HPS::IOResult::InProgress) {
            if (status == HPS::IOResult::Success && !_is_export)
            {
                [self PerformInitialUpdate];
            }
            
            if (status == HPS::IOResult::Failure) {
                
                NSDictionary * dict = [[NSDictionary alloc] initWithObjectsAndKeys:self->path, @"local_path", nil];
                NSNotification* notification = [NSNotification notificationWithName:@"hpsProgressNotification" object:nil userInfo:dict];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }
        
            if (self.clickBlock) {
                self.clickBlock(nil);
            }
            //stop repeating timer. add by eric.
            [self.repeating_timer invalidate];
            [[self window] close];
        }
    }
}

- (IBAction)CancelImport:(id)sender {
    notifier.Cancel();
    _was_canceled = true;
    
    [self.repeating_timer invalidate];

    [self.window close];
}

-(bool) wasCanceled
{
    return self.wasCanceled;
}

-(void) setIsExport:(bool)in_is_export
{
    self->_is_export = in_is_export;
}

-(void)SetNotifier:(HPS::IONotifier)in_notifier
{
    self->notifier = in_notifier;
}
-(void)SetSprocketView:(SprocketsView *)in_view
{
    self.view = in_view;
}
-(void)SetHPSModel:(HPS::Model)in_model
{
    self->model = in_model;
}
-(void)SetIsExport:(bool)in_is_export
{
    self->_is_export = in_is_export;
    if (in_is_export) {
        [self.window setTitle:NSLocalizedString(@"HOOPS_SAVING_FILE", "")];
    }else{
        [self.window setTitle:NSLocalizedString(@"HOOPS_SAVING_LODING", "")];
    }
}

-(void) setFilePath: (NSString*) file_path
{
    self->path = file_path;
}

@end
