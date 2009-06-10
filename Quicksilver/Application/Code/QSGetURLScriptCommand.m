#import "QSGetURLScriptCommand.h"
#import "QSController.h"

@implementation QSGetURLScriptCommand
- (id)performDefaultImplementation {
    NSString *urlString = [self directParameter];
    [(QSController*)[NSApp delegate] openURL:[NSURL URLWithString: urlString]];
    return nil;
}
@end