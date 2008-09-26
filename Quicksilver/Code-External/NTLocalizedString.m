#import "NTLocalizedString.h"
#import "NTViewLocalizer.h"

@implementation NTLocalizedString

+ (NSString*)localize:(NSString*)str {
	return [self localize:str table:nil];
}

+ (NSString*)localize:(NSString*)str table:(NSString*)table {
	return NSLocalizedStringFromTableInBundle(str, table ? table : @"default", [self bundle] , @"");
}

+ (void)localizeWindow:(NSWindow*)window {
	[NTViewLocalizer localizeWindow:window table:@"default" bundle:[self bundle]];
}

+ (void)localizeWindow:(NSWindow*)window table:(NSString*)table {
	[NTViewLocalizer localizeWindow:window table:table bundle:[self bundle]];
}

+ (void)localizeView:(NSView*)view {
	[NTViewLocalizer localizeView:view table:@"default" bundle:[self bundle]];
}

+ (void)localizeView:(NSView*)view table:(NSString*)table {
	[NTViewLocalizer localizeView:view table:table bundle:[self bundle]];
}

@end
