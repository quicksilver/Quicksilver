

#import "QSComputerSource.h"

#import "QSLibrarian.h"

#import "QSResourceManager.h"

@implementation QSComputerProxy
+ (id)sharedInstance{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}
- (NSString *)label{return [[NSProcessInfo processInfo] hostName];}
- (NSString *)name{return @"Computer";}

- (NSImage *)icon{return [QSResourceManager imageNamed:@"ComputerIcon"];}
- (bool)hasChildren{return YES;}
- (NSArray *)children {
    QSCatalogEntry *theEntry=[QSLib entryForID:@"QSPresetVolumes"];
    return [theEntry contents];
}

@end
