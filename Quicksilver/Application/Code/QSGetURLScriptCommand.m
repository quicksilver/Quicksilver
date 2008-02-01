#import "QSGetURLScriptCommand.h"

@implementation QSGetURLScriptCommand
- (id)performDefaultImplementation {
    NSString *urlString = [self directParameter];
    [[NSApp delegate] openURL:[NSURL URLWithString: urlString]];
    return nil;
}
@end