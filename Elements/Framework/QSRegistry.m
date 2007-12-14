//
//  QSRegistry.m
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import "QSRegistry.h"
#import "NSBundle+ExtendedLoading.h"

@implementation QSRegistry
- (NSArray *) pluginPathExtensions {
	return [NSArray arrayWithObjects:@"element", @"plugin", nil, @"qsplugin", nil];
}
- (NSURL *)pluginURLForBundle:(NSBundle *)bundle {
	NSString *path = [bundle pathForResource:@"element"
                                    ofType:@"xml"];
  if (!path) 
    path = [bundle pathForResource:@"plugin"
                          ofType:@"xml"];
	if (!path) return nil;
	return [NSURL fileURLWithPath:path];
}
- (void)registerForNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pluginWillLoad:)
												 name:kBPluginWillLoadNotification
											   object:nil];
}
- (void)pluginWillLoad:(NSNotification *)notif {
	BPlugin *plugin = [notif object];
	[[plugin bundle] registerDefaults];
}


- (void)pluginDidRegister:(NSNotification *)notif {
	BPlugin *plugin = [notif object];
	[[plugin bundle] registerDefaults];
	BLogDebug(@"didRegister %@", plugin);
}

- (void)scanPlugins {
	[self registerForNotifications];
	[super scanPlugins];
}

- (NSMutableArray *)pluginSearchPaths {
  NSMutableArray *pluginSearchPaths = [NSMutableArray array];
  NSString *applicationSupportSubpath = [NSString stringWithFormat:@"Application Support/Alchemy/Elements", [[NSProcessInfo processInfo] processName]];
  NSEnumerator *searchPathEnumerator = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES) objectEnumerator];
  NSString *eachSearchPath;
  
  while((eachSearchPath = [searchPathEnumerator nextObject])) {
		[pluginSearchPaths addObject:[eachSearchPath stringByAppendingPathComponent:applicationSupportSubpath]];
  }
  [pluginSearchPaths addObject:[[NSFileManager defaultManager] currentDirectoryPath]];
  
  NSArray *paths = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSElementSearchPaths"];

  if ([paths isKindOfClass:[NSString class]]) {
    [pluginSearchPaths addObject:paths];
  } else {
    [pluginSearchPaths addObjectsFromArray:paths];
  }
  
	
	NSEnumerator *bundleEnumerator = [[NSBundle allBundles] objectEnumerator];
	NSBundle *eachBundle;
	
	while ((eachBundle = [bundleEnumerator nextObject])) {
		[pluginSearchPaths addObject:[eachBundle builtInPlugInsPath]];
	}
	//BLogDebug(@"pluginSearchPaths %@", pluginSearchPaths);
  return pluginSearchPaths;
}


- (id)coreInstanceWithID:(NSString *)core {
	BElement *element = [self elementForPointID:@"com.blacktree.core" withID:core];	
	return [element elementInstance];
}

- (void)loadMainExtension {
	NSString *mainID = [[NSBundle mainBundle] bundleIdentifier];
	mainID = [mainID stringByAppendingPathExtension:@"main"];
  
  // For now just load any main functions to allow modification
  
  [self loadedInstancesForPointID:mainID];
  [self loadedInstancesForPointID:@"global.main"];
  
  //  NSArray *mainElements = [self elementsForPointID:mainID];
  //  BElement *mainElement= [mainElements lastObject];
  //  
  //  if ([mainElements count] > 1) {
  //		BLogWarn(([NSString stringWithFormat:@"found more then one plugin (%@) with a main extension point, loading only one from plugin %@", mainElements, [mainElement plugin]]));
  //  } else if ([mainElements count] == 0) {
  //		BLogWarn(([NSString stringWithFormat:@"failed to find any plugin with a main extension point %@", mainID]));
  //  }
  //  
  //  [mainElement elementInstance];
}




@end

