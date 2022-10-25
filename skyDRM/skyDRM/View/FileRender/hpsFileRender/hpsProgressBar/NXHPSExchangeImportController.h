#import <Cocoa/Cocoa.h>
#import "NXHPSExchangeImportView.h"
#import "NXSprocketsView.h"
#include "hps.h"
#include "sprk.h"

@interface ExchangeimportWindow : NSWindow
@end

@class ExchangeImportController;

class ImportStatusEventHandler : public HPS::EventHandler
{
public:
    ImportStatusEventHandler()
    : HPS::EventHandler()
    , _progress_dlg(nullptr)
    {}
    
    void SetDialog(ExchangeImportController * in_dialog) { _progress_dlg = in_dialog; }
    
    virtual ~ImportStatusEventHandler() { Shutdown(); }
    virtual HandleResult Handle(HPS::Event const * in_event);
    
private:
    ExchangeImportController * _progress_dlg;

};

@interface ExchangeImportController : NSWindowController
{
    HPS::IONotifier notifier;
    bool keep_dialog_open;
    bool success;
    bool please_update_status;
    HPS::UTF8 message;
    std::deque<HPS::UTF8> log_messages;
    ImportStatusEventHandler import_status_handler;
}

@property (strong) NSTimer * repeating_timer;
@property (strong) SprocketsView * view;
@property (strong) ExchangeimportWindow * exchange_import_window;
-(IBAction)CancelImport:(id)sender;
-(IBAction)KeepWindowOpenClicked:(id)sender;

-(void) PerformInitialUpdate;
-(void) SetMessage:(HPS::UTF8 const &)in_message;
-(void) AddLogEntry:(HPS::UTF8 const &)in_log_entry;
-(void) SetNotifier:(HPS::IONotifier)in_notifier;
-(void) SetSprocketView:(SprocketsView *)in_view;
-(void) onTimerTick:(NSTimer *)theTimer;
-(void) UpdateStatus;

@end
