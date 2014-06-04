#import "QSGetURLScriptCommand.h"
#import "QSController.h"

@implementation QSGetURLScriptCommand
- (id)performDefaultImplementation {
	[(QSController *)[NSApp delegate] openURL:[NSURL URLWithString:[self directParameter]]];
	return nil;
}
@end
