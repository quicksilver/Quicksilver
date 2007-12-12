// NTLocalizedString.h

#import <Cocoa/Cocoa.h>

@interface NTLocalizedString : NSObject
{
}

+ (NSString*)localize:(NSString*)str; // default table
+ (NSString*)localize:(NSString*)str table:(NSString*)table;

+ (void)localizeWindow:(NSWindow*)window; // default table
+ (void)localizeWindow:(NSWindow*)window table:(NSString*)table;

+ (void)localizeView:(NSView*)view;
+ (void)localizeView:(NSView*)view table:(NSString*)table;

@end
