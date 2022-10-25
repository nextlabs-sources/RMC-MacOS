//
//  NXHPSLoadingView.m
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/3/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXHPSLoadingView.h"

@implementation NXHPSLoadingView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [[NSColor lightGrayColor] set];
    
    NSRectFill([self bounds]);
    
    if (self) {
        self.repeating_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
    }
    
    is_export = false;
    was_canceled = false;
}

+ (NSView*)createLoadingView:(NSView*)superView{
    NSArray* views = nil;
    [[NSBundle mainBundle] loadNibNamed:@"NXHPSLoadingView" owner:nil topLevelObjects:&views];
    for (id object in views) {
        if ([object isKindOfClass:[NXHPSLoadingView class]]) {
            ((NSView*)object).frame = CGRectMake(0,0, superView.frame.size.width, superView.frame.size.height);
            [superView addSubview:object];
            return object;
        }
    }
    return nil;
}

-(void) viewDidMoveToSuperview{
    [super viewDidMoveToSuperview];
    [_progress_bar startAnimation:nil];
    [self setAlphaValue:0.5];
}

-(void) mouseDown:(NSEvent *)event{

}

- (void) PerformInitialUpdate{
#ifdef USING_EXCHANGE
    if (self->is_hsf) {
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
        canvas.UpdateWithNotifier(HPS::Window::UpdateType::Exhaustive).Wait();
    }else{
        HPS::CADModel caModel;
        caModel = static_cast<HPS::Exchange::ImportNotifier>(self->notifier).GetCADModel();
        if (!caModel.Empty()) {
            caModel.GetModel().GetSegmentKey().GetPerformanceControl().SetStaticModel(HPS::Performance::StaticModel::Attribute);
            [self.view attachView:caModel.ActivateDefaultCapture().FitWorld()];
        }
        HPS::UpdateNotifier updateNotifier = [self.view GetCanvas].UpdateWithNotifier(HPS::Window::UpdateType::Exhaustive);
        updateNotifier.Wait();
    }
#else
    [self.repeating_timer invalidate];

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
    
    canvas.UpdateWithNotifier(HPS::Window::UpdateType::Exhaustive).Wait();
#endif
}

- (void) onTimerTick:(NSTimer *)theTimer{
    if (notifier.Type() != HPS::Type::None) {
        float complete;
        HPS::IOResult status;
        status = notifier.Status(complete);
        
        if (status != HPS::IOResult::InProgress) {
            if (status == HPS::IOResult::Success && !is_export){
                [self PerformInitialUpdate];
            }
            
            NSString* value = @"success";
            
            
            if (status == HPS::IOResult::Failure) {
                value = @"fail";
            }else if(status == HPS::IOResult::Success){
                value = @"success";
            }
            
            NSDictionary * dict = [[NSDictionary alloc] initWithObjectsAndKeys:self->path, @"local_path", value, @"status", nil];
            
            NSNotification* notification = [NSNotification notificationWithName:@"hpsProgressNotification" object:nil userInfo:dict];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            //stop repeating timer. add by eric.
            [self.repeating_timer invalidate];
            
            [self removeFromSuperview];
        }
    }
}

-(bool) wasCanceled{
    return self.wasCanceled;
}

-(void) setIsExport:(bool)in_is_export{
    self->is_export = in_is_export;
}

-(void)SetNotifier:(HPS::IONotifier)in_notifier{
    self->notifier = in_notifier;
}

-(void)SetSprocketView:(SprocketsView *)in_view{
    self.view = in_view;
}

-(void)SetHPSModel:(HPS::Model)in_model{
    self->model = in_model;
}

-(void)SetIsExport:(bool)in_is_export{
    self->is_export = in_is_export;
    if (in_is_export) {
        [self.window setTitle:NSLocalizedString(@"HOOPS_SAVING_FILE", "")];
    }else{
        [self.window setTitle:NSLocalizedString(@"HOOPS_SAVING_LODING", "")];
    }
}

-(void) SetIsHsf:(bool)is_hsf
{
    self->is_hsf = is_hsf;
}

-(void) setFilePath: (NSString*) file_path{
    NSString* filePath = file_path.lastPathComponent;
    self->path = filePath;
}

@end
