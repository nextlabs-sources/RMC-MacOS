#import "NXHPSExchangeImportView.h"
#import "NXHPSExchangeImportController.h"
#include "sprk.h"

#ifdef USING_EXCHANGE
#include "sprk_exchange.h"
#endif

@implementation ExchangeImportView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

-(void) UpdateImportLabel:(NSString *)message
{
    [self.import_label setStringValue:message];
}

-(void) UpdateLog:(const std::deque<HPS::UTF8> &)in_log_messages
{
    for (auto it = in_log_messages.begin(), e = in_log_messages.end(); it != e; ++it)
        [self.text_field setStringValue: [NSString stringWithFormat:@"%@ \nReading %@", [self.text_field stringValue],[NSString stringWithCString:*it encoding:NSASCIIStringEncoding]]];
}

-(void) EnableCancelButton:(bool)in_enable
{
    [self.cancel_button setEnabled:in_enable];
}

-(void) ChangeCancelButtonText:(NSString *)in_text
{
    [self.cancel_button setTitle:in_text];
}

-(void) MarkProgressAsComplete
{
    self.progress_bar.indeterminate = false;
    self.progress_bar.maxValue = 100;
    [self.progress_bar setDoubleValue:100.0];
}

@end
