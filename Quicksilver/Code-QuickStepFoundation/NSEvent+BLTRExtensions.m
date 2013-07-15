#import "NSEvent+BLTRExtensions.h"

@implementation NSEvent (BLTRExtensions)

+ (NSTimeInterval) doubleClickTime {
	return (double) [NSEvent doubleClickInterval] / 60.0;
}
- (NSInteger)standardModifierFlags {
	return [self modifierFlags] & (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask | NSShiftKeyMask | NSFunctionKeyMask);
}

@end
