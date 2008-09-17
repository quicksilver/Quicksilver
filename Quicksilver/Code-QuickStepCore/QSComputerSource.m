#import "QSComputerSource.h"
#import "QSLibrarian.h"
#import "QSResourceManager.h"

#warning TODO: Merge this inside QSProxyObject/QSProxyObjectSource

@implementation QSComputerProxy
+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
	return _sharedInstance;
}
- (NSString *)label {return [[NSProcessInfo processInfo] hostName];}
- (NSString *)name {return @"Computer";}
- (NSImage *)icon {return [QSResourceManager imageNamed:@"ComputerIcon"];}
- (BOOL)hasChildren {return YES;}
- (NSArray *)children { return [[QSLib entryForID:@"QSPresetVolumes"] contents]; }
- (void)dealloc {
	[name release];
	[super dealloc];
}
@end
