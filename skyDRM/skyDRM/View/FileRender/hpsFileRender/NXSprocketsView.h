//
//  NXSprocketsView.h
//  skyDRM
//
//  Created by helpdesk on 3/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#include "hps.h"
#include "sprk.h"
#include "sprk_ops.h"
#import "NXHPSPrintUtil.h"
#ifdef USING_EXCHANGE
#include "sprk_exchange.h"
#endif

// Class to handle errors
class MyErrorHandler: public HPS::EventHandler
{
public:
    MyErrorHandler() : HPS::EventHandler() {}
    
    virtual ~MyErrorHandler() { Shutdown(); }
    
    // Override to provide behavior for an error event
    virtual HandleResult Handle(HPS::Event const * in_event)
    {
        assert(in_event!=NULL);
        HPS::ErrorEvent const * error = static_cast<HPS::ErrorEvent const *>(in_event);
        const char* msg = error->message.GetBytes();
        if(msg)
            NSLog(@"%s", msg);
        else
            NSLog(@"An error occurred but there was no specific message regarding this event");
        return HandleResult::Handled;
    }
};


// Class to handle warnings
class MyWarningHandler: public HPS::EventHandler
{
public:
    MyWarningHandler() : HPS::EventHandler() {}
    
    virtual ~MyWarningHandler() { Shutdown(); }
    
    // Override to provide behavior for a warning event
    virtual HandleResult Handle(HPS::Event const * in_event)
    {
        assert(in_event!=NULL);
        HPS::WarningEvent const * warning = static_cast<HPS::WarningEvent const *>(in_event);
        const char* msg = warning->message.GetBytes();
        if(msg)
            NSLog(@"%s", msg);
        else
            NSLog(@"A warning occurred but there was no specific message regarding this event");
        return HandleResult::Handled;
    }
};

@interface SprocketsView : NSView
{
    HPS::Canvas canvas;
    HPS::CADModel cad_model;
    HPS::DistantLightKey distant_light;
    MyErrorHandler error_handler;
    MyWarningHandler warning_handler;
    
    bool enableSimpleShadows;
    bool enableFrameRate;
    
    NSString* fileLocalPath;
    NSProgressIndicator *_activityIndicatorView;
}

- (HPS::Canvas)GetCanvas;
- (HPS::CADModel)GetCADModel;
- (void)SetCADModel:(HPS::CADModel)in_cad_model;

- (IBAction)orbitButtonClicked:(id)pId;
- (IBAction)panButtonClicked:(id)pId;
- (IBAction)zoomAreaButtonClicked:(id)pId;
- (IBAction)zoomFitButtonClicked:(id)pId;
- (IBAction)flyButtonClicked:(id)pId;
- (IBAction)pointButtonClicked:(id)pId;
- (IBAction)areaButtonClicked:(id)pId;

- (IBAction)toggleSimpleShadows:(id)pId;
- (IBAction)smoothRendition:(id)pId;
- (IBAction)hiddenLineRendition:(id)pId;
- (IBAction)toggleFrameRate:(id)pId;

- (void)importHSFFile:(const char *)filename hps_model:(HPS::Model const &)model;
- (void)importSTLFile:(const char *)filename hps_model:(HPS::Model const &)model;
- (void)importOBJFile:(const char *)filename hps_model:(HPS::Model const &)model;
#ifdef USING_EXCHANGE
- (void)importExchangeFile:(const char *)filename;
- (void)attachView:(HPS::View const &)in_view;
#endif

- (void) dispatchKeyboardEvent:(NSEvent *)theEvent;

- (void) dispatchLocatorEvent:(NSEvent *) theEvent;
- (void) rightMouseDown:(NSEvent *)theEvent;
- (void) rightMouseUp:(NSEvent *)theEvent;
- (void) rightMouseDragged:(NSEvent *)theEvent;
- (void) injectLocatorEvent:(NSEvent *)theEvent buttons:(HPS::MouseButtons)button action:(HPS::MouseEvent::Action)action wheel_delta:(float)delta;

@end
