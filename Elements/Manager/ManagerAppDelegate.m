#import "ManagerAppDelegate.h"
#import "QSRegistry.h"

@implementation ManagerAppDelegate
+ (void)initialize {
  
  NSLog(@"Init");
	[BLogManager setLoggingLevel:BLoggingDebug];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification{
  
  NSLog(@"Load Registry");
	QSRegistry *registry = [QSRegistry sharedInstance];
  NSLog(@"Scan Plugins");
	[registry scanPlugins];
  
	[registry loadMainExtension];
  NSLog(@"Done");
	[registry logRegistry];
  
	
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
  [QSReg registerPluginWithPath:filename];
  return NO;
}


@end
