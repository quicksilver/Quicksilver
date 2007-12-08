// NTLocalizedString.m

#import "NTLocalizedString.h"
#import "NTViewLocalizer.h"

//#import <OmniFoundation/OmniFoundation.h>

@implementation NTLocalizedString

+ (NSString*)localize:(NSString*)str;
{
    return [self localize:str table:nil];
}

+ (NSString*)localize:(NSString*)str table:(NSString*)table;
{
    // if table is nil, use the default
    if (!table)
        table = @"default";
    
    return NSLocalizedStringFromTableInBundle(str, table, [self bundle], @"");
}

+ (void)localizeWindow:(NSWindow*)window;
{
    [NTViewLocalizer localizeWindow:window table:@"default" bundle:[self bundle]];
}

+ (void)localizeWindow:(NSWindow*)window table:(NSString*)table;
{
    [NTViewLocalizer localizeWindow:window table:table bundle:[self bundle]];
}

+ (void)localizeView:(NSView*)view;
{
    [NTViewLocalizer localizeView:view table:@"default" bundle:[self bundle]];
}

+ (void)localizeView:(NSView*)view table:(NSString*)table;
{
    [NTViewLocalizer localizeView:view table:table bundle:[self bundle]];
}

@end