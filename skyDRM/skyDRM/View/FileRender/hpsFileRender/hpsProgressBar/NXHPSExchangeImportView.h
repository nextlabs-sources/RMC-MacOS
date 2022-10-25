#import <Cocoa/Cocoa.h>
#import "NXSprocketsView.h"
#include "hps.h"



@interface ExchangeImportView : NSView

-(void) UpdateImportLabel:(NSString *)message;
-(void) UpdateLog:(std::deque<HPS::UTF8> const &)in_log_messages;
-(void) EnableCancelButton:(bool)in_enable;
-(void) ChangeCancelButtonText:(NSString *)in_text;
-(void) MarkProgressAsComplete;

@property (strong) IBOutlet NSButton * keep_open_button;
@property (strong) IBOutlet NSButton * cancel_button;
@property (strong) IBOutlet NSTextField * text_field;
@property (strong) IBOutlet NSTextField * import_label;
@property (strong) IBOutlet NSProgressIndicator * progress_bar;

@end
