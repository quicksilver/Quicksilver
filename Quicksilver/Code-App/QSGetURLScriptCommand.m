#import "QSGetURLScriptCommand.h"

@implementation QSGetURLScriptCommand
- (id)performDefaultImplementation {
	[[NSApp delegate] openURL:[NSURL URLWithString:[self directParameter]]];
	return nil;
}
@end
