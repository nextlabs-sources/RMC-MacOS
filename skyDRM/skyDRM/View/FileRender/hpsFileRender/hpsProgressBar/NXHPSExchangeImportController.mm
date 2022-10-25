
#import "NXHPSExchangeImportController.h"
#include <string>
#include <mutex>

std::mutex mtx;

namespace
{
    bool isAbsolutePath(char const * path)
    {
        bool starts_with_drive_letter = strlen(path) >= 3
        && isalpha(path[0])
        && path[1] == ':'
        && strchr("/\\", path[2]);
        
        bool starts_with_network_drive_prefix = strlen(path) >= 2
        && strchr("/\\", path[0])
        && strchr("/\\", path[1]);
        
        bool starts_with_root = strlen(path) > 1
        && strchr("/\\", path[0]);
        
        return starts_with_drive_letter || starts_with_network_drive_prefix || starts_with_root;
    }
}

HPS::EventHandler::HandleResult ImportStatusEventHandler::Handle(HPS::Event const * in_event)
{
    if (_progress_dlg)
    {
        HPS::UTF8 message = static_cast<HPS::ImportStatusEvent const *>(in_event)->import_status_message;
        if (message.IsValid())
        {
            bool update_message = true;
            
            if (message == HPS::UTF8("Import and Tessellation"))
                [_progress_dlg SetMessage:HPS::UTF8("Stage 1/3 : Import and Tessellation")];
            else if (message == HPS::UTF8("Creating Graphics Database"))
                [_progress_dlg SetMessage:HPS::UTF8("Stage 2/3 : Creating Graphics Database")];
            else if (isAbsolutePath(message))
            {
                std::string path(message);
                message = path.substr(path.find_last_of("/\\") + 1).c_str();
                [_progress_dlg AddLogEntry:HPS::UTF8(message)];
                update_message = false;
            }
            else
                update_message = false;
            
            if (update_message)
                [_progress_dlg UpdateStatus];
        }
    }
    return HPS::EventHandler::HandleResult::Handled;
}

@interface ExchangeImportController ()

@end

@implementation ExchangeImportController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self->success = false;
        self->keep_dialog_open = false;
        self->please_update_status = false;
        import_status_handler.SetDialog(self);
        
        [[self.window contentView] UpdateImportLabel:@"Stage 1/3 : Import and Tessellation"];
        HPS::Database::GetEventDispatcher().Subscribe(import_status_handler, HPS::Object::ClassID<HPS::ImportStatusEvent>());
        
        self.repeating_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
        
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

-(void) UpdateStatus
{
    self->please_update_status = true;
}

-(IBAction)CancelImport:(id)sender
{
    if (self->success == true)
        [self.window close];
    else
    {
        self->notifier.Cancel();
        [self.repeating_timer invalidate];

        [self.window close];
    }
}

-(IBAction)KeepWindowOpenClicked:(id)sender
{
    self->keep_dialog_open = !self->keep_dialog_open;
}

-(void) onTimerTick:(NSTimer *)theTimer
{
    try
    {
        if (self->please_update_status)
        {
            if (self->message.IsValid())
            {
                [[self.window contentView] UpdateImportLabel:[NSString stringWithCString:message encoding:NSASCIIStringEncoding]]   ;
                message = HPS::UTF8();
            }
            self->please_update_status = false;
        }
    
        {
            //update the import log
            std::lock_guard<std::mutex> lock(mtx);
        
            if (!log_messages.empty())
            {
                [[self.window contentView] UpdateLog:log_messages];
                log_messages.clear();
            }
        }
    
        HPS::IOResult status;
        status = notifier.Status();
    
        if (status != HPS::IOResult::InProgress)
        {
            HPS::Database::GetEventDispatcher().UnSubscribe(import_status_handler);
            [self.repeating_timer invalidate];

        
            if (status == HPS::IOResult::Success)
                [self PerformInitialUpdate];
        
            if (!keep_dialog_open)
                [self.window close];
        }
    
    }
    catch (HPS::IOException const &)
    {

    }
}

-(void) AddLogEntry:(const HPS::UTF8 &)in_log_entry
{
    std::lock_guard<std::mutex> lock(mtx);
    log_messages.push_back(in_log_entry);
}

-(void) PerformInitialUpdate
{
#ifdef USING_EXCHANGE
    [[self.window contentView] EnableCancelButton:false];
    [[self.window contentView] UpdateImportLabel:@"Stage 3/3 : Performing Initial Update"];
    
    HPS::CADModel cadModel;
    cadModel = static_cast<HPS::Exchange::ImportNotifier>(self->notifier).GetCADModel();
    
    if (!cadModel.Empty())
    {
        cadModel.GetModel().GetSegmentKey().GetPerformanceControl().SetStaticModel(HPS::Performance::StaticModel::Attribute);
        [self.view attachView:cadModel.ActivateDefaultCapture().FitWorld()];
    }
    
    HPS::UpdateNotifier updateNotifier = [self.view GetCanvas].UpdateWithNotifier(HPS::Window::UpdateType::Exhaustive);
    updateNotifier.Wait();
    
    [[self.window contentView] EnableCancelButton:true];
    [[self.window contentView] ChangeCancelButtonText:@"Close Dialog"];
    [[self.window contentView] MarkProgressAsComplete];
    [[self.window contentView] UpdateImportLabel:@"Import Complete"];
    
    success = true;
#endif
}

-(void) SetNotifier:(HPS::IONotifier)in_notifier
{
    self->notifier = in_notifier;
}

-(void) SetMessage:(const HPS::UTF8 &)in_message
{
    self->message = in_message;
}

-(void) SetSprocketView:(SprocketsView *)in_view
{
    self.view = in_view;
}

@end

