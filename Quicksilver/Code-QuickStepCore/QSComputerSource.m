#import "QSComputerSource.h"
#import "QSLibrarian.h"
#import "QSResourceManager.h"

@implementation QSComputerProxyProvider
- (NSString*)detailsOfObject:(QSObject*)object {
    if ([[object identifier] isEqualToString:@"QSComputerProxy"]) {
        return [[NSProcessInfo processInfo] hostName];
    }
    return nil;
}

- (BOOL)loadChildrenForObject:(QSObject*)proxy {
    if ([[proxy identifier] isEqualToString:@"QSComputerProxy"]) {
        [proxy setChildren:[[QSLib entryForID:@"QSPresetVolumes"] contents]];
        return YES;
    }
    return NO;
}

@end
