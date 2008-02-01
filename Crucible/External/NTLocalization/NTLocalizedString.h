// NTLocalizedString.h

#import <Cocoa/Cocoa.h>

@interface NTLocalizedString : NSObject
{
}

+ (NSString*)localize:(NSString*)str; // default table
+ (NSString*)localize:(NSString*)str table:(NSString*)table;

@end