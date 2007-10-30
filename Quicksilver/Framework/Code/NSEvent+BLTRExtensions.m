
#import <Carbon/Carbon.h>
#import "NSEvent+BLTRExtensions.h"

@implementation NSEvent (BLTRExtensions)

+ (NSTimeInterval)doubleClickTime{
	return (double)GetDblTime() / 60.0;
}
- (int)standardModifierFlags{
	int standardModifierFlags=[self modifierFlags] & (NSCommandKeyMask|NSAlternateKeyMask|NSControlKeyMask|NSShiftKeyMask|NSFunctionKeyMask);
	return standardModifierFlags;
}
@end