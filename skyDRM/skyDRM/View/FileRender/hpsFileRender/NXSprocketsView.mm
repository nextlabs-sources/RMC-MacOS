//
//  NXSprocketsView.m
//  skyDRM
//
//  Created by helpdesk on 3/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXSprocketsView.h"
#import "NXHPSProgressBarController.h"
#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "SkyDRM-Swift.h"
#import "NXHPSLoadingView.h"
#import "NXHPSExchangeImportController.h"
#import "NXLSDKDef.h"

//#define ENABLE_RETINA

@implementation SprocketsView

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

#pragma -mark Property
- (NSProgressIndicator *)activityIndicatorView
{
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[NSProgressIndicator alloc] initWithFrame:CGRectMake((self.bounds.size.width/2.0)-15.0, (self.bounds.size.height/2.0)-15.0, 30, 30)];
        _activityIndicatorView.style = NSProgressIndicatorSpinningStyle;
        [_activityIndicatorView setWantsLayer:true];
        [_activityIndicatorView.layer setBackgroundColor:[NSColor clearColor].CGColor];
    }
    return _activityIndicatorView;
}

#pragma -mark Private Method
- (void)showActivityView
{
    [self.activityIndicatorView setHidden:NO];
    [self.activityIndicatorView setIndeterminate:YES];
    [self.activityIndicatorView startAnimation:self];
}

- (void)hiddenActivityView {
    [self.activityIndicatorView stopAnimation:self];
    [self.activityIndicatorView setHidden:YES];
}


#ifdef ENABLE_RETINA
- (void)viewDidChangeBackingProperties {
    self.layer.contentsScale = [[self window] backingScaleFactor];
}
#endif

- (id)initWithCoder:(NSCoder *)decoder {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dispatchNotification:) name:@"renderHPSNotification" object:nil];
    
    self = [super initWithCoder:decoder];
    
    if (self){
        NSUInteger mask = NSViewWidthSizable | NSViewHeightSizable;
        [self setAutoresizingMask:mask];
        [[self window] makeFirstResponder: self];
        
#ifdef ENABLE_RETINA
        [self setWantsLayer:YES];
#endif
        
        HPS::ApplicationWindowOptionsKit awok;
        awok.SetDriver(HPS::Window::Driver::OpenGL2);
        
        canvas = HPS::Factory::CreateCanvas(reinterpret_cast<HPS::WindowHandle>(self), "Canvas1", awok);
        HPS::View view = HPS::Factory::CreateView();
        canvas.AttachViewAsLayout(view);
        
        // Set camera-relative, colorless, main distant light in the scene.
        HPS::DistantLightKit lightKit;
        lightKit.SetDirection(HPS::Vector(1, 0, -1.5f));
        lightKit.SetCameraRelative(true);
        distant_light = view.GetSegmentKey().InsertDistantLight(lightKit);
        
        HPS::Database::GetEventDispatcher().Subscribe(error_handler, HPS::Object::ClassID<HPS::ErrorEvent>());
        HPS::Database::GetEventDispatcher().Subscribe(warning_handler, HPS::Object::ClassID<HPS::WarningEvent>());
        
        // Set default operators.  Orbit is on top and will be replaced when the operator is changed.
        view.GetOperatorControl()
        .Push(new HPS::MouseWheelOperator(), HPS::Operator::Priority::Low)
        .Push(new HPS::ZoomOperator(HPS::MouseButtons::ButtonMiddle()))
        .Push(new HPS::PanOperator(HPS::MouseButtons::ButtonRight()))
        .Push(new HPS::OrbitOperator(HPS::MouseButtons::ButtonLeft()));
    }
    
    return self;
}

- (void)dispatchNotification:(NSNotification *)notification
{
    NSString* va = [notification.userInfo objectForKey:@"message"];
    fileLocalPath = objc_getAssociatedObject(self, NXHPSViewKey);
    if (fileLocalPath == va) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        const char *utf8 = [va UTF8String];
        
//        HPS::View view = canvas.GetFrontView();
//        HPS::Model model = view.GetAttachedModel();
//        view.DetachModel();
//        model.Delete();
//
//        NSString *ext = [va pathExtension];
//
//        if (model.Type() == HPS::Type::None)
//        {
//            model = HPS::Factory::CreateModel();
//        }
        
        HPS::View view = canvas.GetFrontView();
        if (view.Type() != HPS::Type::None)
        {
            HPS::Model model = view.GetAttachedModel();
            if (model.Type() != HPS::Type::None)
            {
                view.DetachModel();
                model.Delete();
            }
        }
        
        NSString *ext = [va pathExtension];
        
        HPS::Model model = HPS::Factory::CreateModel();
        
        if ([ext caseInsensitiveCompare:@"hsf"] == NSOrderedSame)
            [self importHSFFile:utf8 hps_model:model];
        else if ([ext caseInsensitiveCompare:@"stl"] == NSOrderedSame)
            [self importSTLFile:utf8 hps_model:model];
        else if ([ext caseInsensitiveCompare:@"obj"] == NSOrderedSame)
            [self importOBJFile:utf8 hps_model:model];
        else{
              [self importExchangeFile:utf8];
        }
    }
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL) becomeFirstResponder {
    return YES;
}

- (BOOL) resignFirstResponder {
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    canvas.Update(HPS::Window::UpdateType::Refresh);
}

- (void) dispatchKeyboardEvent:(NSEvent *)theEvent
{
    NSEventType type = [theEvent type];
    
    HPS::KeyboardEvent::Action action = HPS::KeyboardEvent::Action::None;
    HPS::ModifierKeys modifiers;
    
    unsigned long m = [theEvent modifierFlags];
    if ((m & NSEventModifierFlagShift) != 0)
        modifiers.Shift(true);
    if ((m & NSEventModifierFlagControl) != 0)
        modifiers.Control(true);
    
    switch(type)
    {
        case NSEventTypeKeyDown:
            action = HPS::KeyboardEvent::Action::KeyDown;
            break;
            
        case NSEventTypeKeyUp:
            action = HPS::KeyboardEvent::Action::KeyUp;
            break;
            
        default:
            printf("Not handling some keyboard event\n");
            break;
    }
    
    HPS::KeyboardCode code;
    if ([theEvent modifierFlags] & NSEventModifierFlagNumericPad)
    {
        if ([theEvent keyCode] == 126)
            code = HPS::KeyboardCode::Up;
        else if ([theEvent keyCode] == 125)
            code = HPS::KeyboardCode::Down;
        else if ([theEvent keyCode] == 124)
            code = HPS::KeyboardCode::Right;
        else if ([theEvent keyCode] == 123)
            code = HPS::KeyboardCode::Left;
    }
    else
    {
        NSString * c = [theEvent characters];
        char cc[5];
        strcpy(cc, [c cStringUsingEncoding:1]);
        code = (HPS::KeyboardCode)cc[0];
    }
    canvas.GetWindowKey().GetEventDispatcher().InjectEvent(HPS::KeyboardEvent(action, 1, &code, modifiers));
}

- (void) rightMouseDown:(NSEvent *)theEvent
{
    HPS::MouseButtons button;
    button.Right(true);
    HPS::MouseEvent::Action action;
    action = HPS::MouseEvent::Action::ButtonDown;
    
    [self injectLocatorEvent:theEvent buttons:button action:action wheel_delta:0];
}

- (void) rightMouseUp:(NSEvent *)theEvent
{
    HPS::MouseButtons button;
    button.Right(true);
    HPS::MouseEvent::Action action;
    action = HPS::MouseEvent::Action::ButtonUp;
    
    [self injectLocatorEvent:theEvent buttons:button action:action wheel_delta:0];
}

- (void) rightMouseDragged:(NSEvent *)theEvent
{
    HPS::MouseButtons button;
    button.Right(true);
    HPS::MouseEvent::Action action;
    action = HPS::MouseEvent::Action::Move;
    
    [self injectLocatorEvent:theEvent buttons:button action:action wheel_delta:0];
}

- (void) dispatchLocatorEvent:(NSEvent *) theEvent
{
    NSEventType type = [theEvent type];
    
    HPS::MouseButtons button;
    HPS::MouseEvent::Action action = HPS::MouseEvent::Action::Move;
    float wheelDelta = 0.0f;
    
    switch(type)
    {
        case NSEventTypeLeftMouseDown:
        {
            button.Left(true);
            action = HPS::MouseEvent::Action::ButtonDown;
        }break;
            
        case NSEventTypeLeftMouseUp:
        {
            button.Left(true);
            action = HPS::MouseEvent::Action::ButtonUp;
        }break;
            
        case NSEventTypeLeftMouseDragged:
        {
            button.Left(true);
            action = HPS::MouseEvent::Action::Move;
        }break;
            
        case NSEventTypeRightMouseDragged:
        {
            button.Right(true);
            action = HPS::MouseEvent::Action::Move;
        }break;
            
        case NSEventTypeMouseMoved:
        {
            action = HPS::MouseEvent::Action::Move;
        }break;
            
        case NSEventTypeScrollWheel:
        {
            wheelDelta = theEvent.deltaY * 80.0f;
            action = HPS::MouseEvent::Action::Scroll;
        }break;
            
        default: printf("not handling some input event \n"); break;
            
    }
    
    [self injectLocatorEvent:theEvent buttons:button action:action wheel_delta:wheelDelta];
    
}

- (void) injectLocatorEvent:(NSEvent *)theEvent buttons:(HPS::MouseButtons)button action:(HPS::MouseEvent::Action)action wheel_delta:(float)delta
{
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point.y = [self frame].size.height - local_point.y;
    local_point = [self convertPointToBacking:local_point];
    
    HPS::Point pixel_space = HPS::Point(local_point.x, local_point.y, 0);
    HPS::Point window_space;
    canvas.GetWindowKey().ConvertCoordinate(HPS::Coordinate::Space::Pixel, pixel_space, HPS::Coordinate::Space::Window, window_space);
    
    
    HPS::ModifierKeys modifierKeys;
    NSUInteger modifierFlags = theEvent.modifierFlags;
    if ((modifierFlags & NSEventModifierFlagShift) != 0)
        modifierKeys.Shift(true);
    if ((modifierFlags & NSEventModifierFlagControl) != 0)
        modifierKeys.Control(true);
    if ((modifierFlags & NSEventModifierFlagOption) != 0)
        modifierKeys.Alt(true);
    if ((modifierFlags & NSEventModifierFlagCommand) != 0)
        modifierKeys.Meta(true);
    
    HPS::MouseEvent event;
    if (action == HPS::MouseEvent::Action::Scroll)
        event = HPS::MouseEvent(action, delta, window_space, modifierKeys);
    else
        event = HPS::MouseEvent(action, window_space, button, modifierKeys);
    
    if (theEvent.type != NSEventTypeScrollWheel)
        event.ClickCount = theEvent.clickCount;
    
    canvas.GetWindowKey().GetEventDispatcher().InjectEvent(event);
}

- (void)mouseDown: (NSEvent *) theEvent {
    
    [self dispatchLocatorEvent : theEvent];
}

- (void)mouseUp: (NSEvent *) theEvent {
    [self dispatchLocatorEvent : theEvent];
}

- (void)mouseDragged: (NSEvent *) theEvent {
    [self dispatchLocatorEvent : theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [self dispatchLocatorEvent : theEvent];
}

- (void) scrollWheel:(NSEvent *)theEvent {
    [self dispatchLocatorEvent : theEvent];
}

-(void) keyDown:(NSEvent *)theEvent {
    [self dispatchKeyboardEvent: theEvent];
}

-(void) keyUp:(NSEvent *)theEvent {
    [self dispatchKeyboardEvent: theEvent];
}

- (void)importHSFFile:(const char *)filename hps_model:(const HPS::Model &)model
{
    HPS::Stream::ImportNotifier	notifier;
    try
    {
        HPS::Stream::ImportOptionsKit import;
        import.SetSegment(model.GetSegmentKey());
        import.SetAlternateRoot(model.GetLibraryKey());
        import.SetPortfolio(model.GetPortfolioKey());
        notifier = HPS::Stream::File::Import(filename, import);
        
        NXHPSLoadingView *loadingView = (NXHPSLoadingView*)[NXHPSLoadingView createLoadingView:self];
        [loadingView SetSprocketView:self];
        [loadingView SetIsHsf:YES];
        [loadingView SetNotifier:notifier];
        [loadingView SetHPSModel:model];
        NSString* temp = [[NSString alloc] initWithUTF8String:filename];
        [loadingView setFilePath:temp];
    }
    catch (HPS::IOException e)
    {
        /* catch Stream I/O Errors here */
    }
}

- (void)importSTLFile:(const char *)filename hps_model:(const HPS::Model &)model
{
    [self addSubview:self.activityIndicatorView positioned:NSWindowAbove relativeTo:nil];
    [self showActivityView];
    
    HPS::STL::ImportNotifier    notifier;
    try
    {
        HPS::STL::ImportOptionsKit import = HPS::STL::ImportOptionsKit::GetDefault();
        import.SetSegment(model.GetSegmentKey());
        notifier = HPS::STL::File::Import(filename, import);
        
        NXHPSProgressBarController * progress_bar_window = [[NXHPSProgressBarController alloc] initWithWindowNibName:@"NXHPSProgressBarController"];
        [progress_bar_window SetSprocketView:self];
        [progress_bar_window SetNotifier:notifier];
        [progress_bar_window SetHPSModel:model];
        [progress_bar_window showWindow:self];
        WeakObj(self)
        progress_bar_window.clickBlock = ^(id sender) {
            StrongObj(self)
            [self hiddenActivityView];
        };
    }
    catch (HPS::IOException e)
    {
        /* catch STL I/O Errors here */
    }
}

- (void)importOBJFile:(const char *)filename hps_model:(const HPS::Model &)model
{
    [self addSubview:self.activityIndicatorView positioned:NSWindowAbove relativeTo:nil];
    [self showActivityView];
    
    HPS::OBJ::ImportNotifier    notifier;
    try
    {
        HPS::OBJ::ImportOptionsKit import;
        import.SetSegment(model.GetSegmentKey());
        import.SetPortfolio(model.GetPortfolioKey());
        notifier = HPS::OBJ::File::Import(filename, import);
        
        NXHPSProgressBarController * progress_bar_window = [[NXHPSProgressBarController alloc] initWithWindowNibName:@"NXHPSProgressBarController"];
        [progress_bar_window SetSprocketView:self];
        [progress_bar_window SetNotifier:notifier];
        [progress_bar_window SetHPSModel:model];
        [progress_bar_window showWindow:self];
        WeakObj(self)
        progress_bar_window.clickBlock = ^(id sender) {
            StrongObj(self)
            [self hiddenActivityView];
        };
    }
    catch (HPS::IOException e)
    {
        /* catch OBJ I/O Errors here */
    }
}

#ifdef USING_EXCHANGE
- (void)attachView:(const HPS::View &)in_view
{
    HPS::View old_view = canvas.GetFrontView();
    
    canvas.AttachViewAsLayout(in_view);
    
    HPS::OperatorPtrArray operators;
    auto oldViewOperatorCtrl = old_view.GetOperatorControl();
    auto newViewOperatorCtrl = in_view.GetOperatorControl();
    oldViewOperatorCtrl.Show(HPS::Operator::Priority::Low, operators);
    newViewOperatorCtrl.Set(operators, HPS::Operator::Priority::Low);
    oldViewOperatorCtrl.Show(HPS::Operator::Priority::Default, operators);
    newViewOperatorCtrl.Set(operators, HPS::Operator::Priority::Default);
    oldViewOperatorCtrl.Show(HPS::Operator::Priority::High, operators);
    newViewOperatorCtrl.Set(operators, HPS::Operator::Priority::High);
    
    HPS::DistantLightKit light;
    light.SetDirection(HPS::Vector(1, 0, -1.5f));
    light.SetCameraRelative(true);
    
    // Delete previous light before inserting new one
    if (distant_light.Type() != HPS::Type::None)
        distant_light.Delete();
    distant_light = canvas.GetFrontView().GetSegmentKey().InsertDistantLight(light);
    
    old_view.Delete();
}

- (void)importExchangeFile:(const char *)filename
{
    HPS::Exchange::ImportNotifier notifier;
    try
    {
        HPS::Exchange::ImportOptionsKit import;
        import.SetBRepMode(HPS::Exchange::BRepMode::BRepAndTessellation);
        notifier = HPS::Exchange::File::Import(filename, import);
        
        
        NXHPSLoadingView *loadingView = (NXHPSLoadingView*)[NXHPSLoadingView createLoadingView:self];
        [loadingView SetSprocketView:self];
        [loadingView SetNotifier:notifier];
        [loadingView SetIsHsf:NO];
        NSString *name = [NSString stringWithCString:filename encoding:NSUTF8StringEncoding];
        [loadingView.window setTitle:name.lastPathComponent];
        NSString* temp = [[NSString alloc] initWithUTF8String:filename];
        [loadingView setFilePath:temp];
    }
    catch (HPS::IOException e)
    {
        /* catch Exchange I/O Errors here */
    }
}
#endif

- (IBAction)orbitButtonClicked:(id)pId{
    canvas.GetFrontView().GetOperatorControl().Pop();
    canvas.GetFrontView().GetOperatorControl().Push(new HPS::PanOrbitZoomOperator());
}

- (IBAction)panButtonClicked:(id)pId{
    canvas.GetFrontView().GetOperatorControl().Pop();
    canvas.GetFrontView().GetOperatorControl().Push(new HPS::PanOperator());
}

- (IBAction)zoomAreaButtonClicked:(id)pId{
    canvas.GetFrontView().GetOperatorControl().Pop();
    canvas.GetFrontView().GetOperatorControl().Push(new HPS::ZoomBoxOperator());
}

- (IBAction)flyButtonClicked:(id)pId{
    canvas.GetFrontView().GetOperatorControl().Pop();
    canvas.GetFrontView().GetOperatorControl().Push(new HPS::FlyOperator());
}

- (IBAction)zoomFitButtonClicked:(id)pId{
    canvas.GetFrontView().FitWorld().Update();
}

-(IBAction)pointButtonClicked:(id)pId{
    canvas.GetFrontView().GetOperatorControl().Pop();
    canvas.GetFrontView().GetOperatorControl().Push(new HPS::HighlightOperator());
}

-(IBAction)areaButtonClicked:(id)pId{
    canvas.GetFrontView().GetOperatorControl().Pop();
    canvas.GetFrontView().GetOperatorControl().Push(new HPS::HighlightAreaOperator());
}

- (IBAction)toggleSimpleShadows:(id)pId{
    const float					opacity = 0.3f;
    const unsigned int			resolution = 512;
    const unsigned int			blurring = 20;
    
    HPS::SegmentKey				viewSegment = canvas.GetFrontView().GetSegmentKey();
    
    // Toggle state and bail early if we're disabling
    enableSimpleShadows = !enableSimpleShadows;
    
    if (enableSimpleShadows == false){
        canvas.GetFrontView().SetSimpleShadow(false);
    }else{
        canvas.GetFrontView().SetSimpleShadow(true);
        // Set opacity in simple shadow color
        HPS::RGBAColor				color(0.4f, 0.4f, 0.4f, opacity);
        if (viewSegment.GetVisualEffectsControl().ShowSimpleShadowColor(color))
            color.alpha = opacity;
        
        // Enable/disable shadow and pass in shadow settings
        viewSegment.GetVisualEffectsControl()
        .SetSimpleShadow(true, resolution, blurring)
        .SetSimpleShadowColor(color);
    }
    
    canvas.Update();
    
}

- (IBAction)smoothRendition:(id)pId{
    canvas.GetFrontView().SetRenderingMode(HPS::Rendering::Mode::Phong);
    canvas.Update();
}

- (IBAction)hiddenLineRendition:(id)pId{
    canvas.GetFrontView().SetRenderingMode(HPS::Rendering::Mode::FastHiddenLine);
    canvas.SetFrameRate(0);
    canvas.Update();
}

- (IBAction)toggleFrameRate:(id)pId{
    const float                 frameRate = 20.0f;
    
    // Toggle frame rate and set.  Note that 0 disables frame rate.
    enableFrameRate = !enableFrameRate;
    if (enableFrameRate){
        canvas.SetFrameRate(frameRate);
        if (canvas.GetFrontView().GetRenderingMode() == HPS::Rendering::Mode::FastHiddenLine){
            canvas.GetFrontView().SetRenderingMode(HPS::Rendering::Mode::Phong);
        }
    }else{
        canvas.SetFrameRate(0);
    }
    
    canvas.Update();
}

-(HPS::Canvas)GetCanvas{
    return self->canvas;
}

-(HPS::CADModel)GetCADModel{
    return self->cad_model;
}

-(void)SetCADModel:(HPS::CADModel)in_cad_model{
    self->cad_model = in_cad_model;
}

@end
