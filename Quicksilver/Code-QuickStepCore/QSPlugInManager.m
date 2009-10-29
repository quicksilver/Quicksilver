//
// QSPlugInManager.m
// Quicksilver
//
// Created by Alcor on 2/7/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSPlugInManager.h"
#import "QSNotifyMediator.h"

#import "QSRegistry.h"
#import "QSUpdateController.h"
#import "QSPlugIn.h"

#import "QSTaskController.h"
#import "QSPreferenceKeys.h"

#import "QSFoundation.h"

#import "QSURLDownloadWrapper.h"

#import "NSException_TraceExtensions.h"

#define pPlugInInfo QSApplicationSupportSubPath(@"PlugIns.plist", NO)
#define MAX_CONCURRENT_DOWNLOADS 2

@implementation QSPlugInManager
+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
	return _sharedInstance;
}
- (id)init {
	if (self = [super init]) {
		//	plugIns = [[NSMutableDictionary alloc] init];
		localPlugIns = [[NSMutableDictionary alloc] init];
		knownPlugIns = [[NSMutableDictionary alloc] init];
		loadedPlugIns = [[NSMutableDictionary alloc] init];

		receivedData = nil;
		oldPlugIns = [[NSMutableArray alloc] init];
		dependingPlugIns = [[NSMutableDictionary alloc] init];

		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plugInDidInstall:) name:QSPlugInInstalledNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plugInDidLoad:) name:QSPlugInLoadedNotification object:nil];
		showNotifications = YES;
	}
	return self;
}

- (QSPlugIn *)plugInWithBundle:(NSBundle *)bundle {
	QSPlugIn *plugin = [knownPlugIns objectForKey:[bundle bundleIdentifier]];
	if (plugin) {
		[plugin setBundle:bundle];
	} else {
		plugin = [QSPlugIn plugInWithBundle:bundle];
		[knownPlugIns setObject:plugin forKey:[bundle bundleIdentifier]];
	}
	return plugin;
}

- (QSPlugIn *)plugInWithID:(NSString *)identifier {
	return [knownPlugIns objectForKey:identifier];
}

- (QSPlugIn *)plugInBundleWasInstalled:(NSBundle *)bundle {
#warning should check if this plugin is already installed?
	QSPlugIn *plugin = [self plugInWithBundle:bundle];
	[localPlugIns setObject:plugin forKey:[plugin identifier]];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInstalledNotification object:plugin];
	return plugin;
}

- (void)plugInDidLoad:(NSNotification *)notif {
	QSPlugIn *plugin = [notif object];
	[loadedPlugIns setObject:plugin forKey:[plugin identifier]];

	// Load dependencies
	NSArray *deps = [dependingPlugIns objectForKey:[plugin identifier]];
	foreach(dep, deps) {
		if (![[dep unmetDependencies] count])
			[self liveLoadPlugIn:dep];
	}
	[dependingPlugIns removeObjectForKey:[plugin identifier]];
}

- (NSMutableArray *)oldPlugIns { return oldPlugIns; }

- (BOOL)startupLoadComplete {return startupLoadComplete;}
- (void)loadPlugInInfo {

	//	NSDictionary *dict = [QSReg identifierBundles];
	//	NSEnumerator *ke = [dict keyEnumerator];
	//	NSString *key;
	//	id value;
	//	while(key = [ke nextObject]) {
	//		value = [dict objectForKey:key];
	//		if (value == [NSBundle mainBundle]) continue;
	//		[plugIns setObject:[QSPlugIn plugInWithBundle:value] forKey:key];
	//	}

}
- (void)writeInfo {
	if (!plugInWebData) return;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:plugInWebData forKey:@"webData"];
	[dict setObject:plugInWebDownloadDate forKey:@"webDownloadDate"];
	[dict writeToFile:pPlugInInfo atomically:YES];
}
- (void)loadInfo {
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:pPlugInInfo];
	if (dict) {
		plugInWebData = [[dict objectForKey:@"webData"] mutableCopy];
		plugInWebDownloadDate = [[dict objectForKey:@"webDownloadDate"] retain];
	}
	if (!plugInWebData)
		plugInWebData = [[NSMutableDictionary alloc] init];
}

- (void)downloadWebPlugInInfo {
	[self downloadWebPlugInInfoFromDate:plugInWebDownloadDate forUpdateVersion:nil synchronously:NO];
}
- (void)downloadWebPlugInInfoIgnoringDate {
	[self downloadWebPlugInInfoFromDate:nil forUpdateVersion:nil synchronously:NO];
}
- (BOOL)supressRelaunchMessage {
	return supressRelaunchMessage;
}

- (void)setSupressRelaunchMessage:(BOOL)flag {
	supressRelaunchMessage = flag;
}

- (NSString *)webInfoURLFromDate:(NSDate *)date forUpdateVersion:(NSString *)version {
	NSString *fetchURLString = @"http://qs0.blacktree.com/quicksilver/plugins/plugininfo.php?";
	NSMutableArray *query = [NSMutableArray array];
	if (date) {
		[query addObject:[NSString stringWithFormat:@"asOfDate=%@",
			[date descriptionWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil locale:nil]]];
	}
	if (version) {
		[query addObject:[NSString stringWithFormat:@"updateVersion=%d", [version hexIntValue]]];
	} else {
		[query addObject:[NSString stringWithFormat:@"qsversion=%d", [[NSApp buildVersion] hexIntValue]]];
	}
	NSArray *webPlugIns = [[knownPlugIns allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isSecret == 1"]];
	NSArray *secretIdentifiers = [webPlugIns valueForKey:@"identifier"];
	if ([secretIdentifiers count]) {
		[query addObject:[NSString stringWithFormat:@"sids=%@", [secretIdentifiers componentsJoinedByString:@", "]]];
	}

	fetchURLString = [fetchURLString stringByAppendingString:[query componentsJoinedByString:@"&"]];
	if (VERBOSE) NSLog(@"Get web info: %@", fetchURLString);
	return fetchURLString;
}

- (void)downloadWebPlugInInfoFromDate:(NSDate *)date forUpdateVersion:(NSString *)version synchronously:(BOOL)synchro {
	NSString *fetchURLString = [self webInfoURLFromDate:(NSDate *)date forUpdateVersion:(NSString *)version];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:20.0];
	//if (VERBOSE)
	NSLog(@"Fetching plugin data from %@", fetchURLString);

	//	[[localPlugIns allValues]
	//	[theRequest setHTTPMethod:@"POST"];
	//setting the headers:
	//	[theRequest setHTTPMethod:@"POST"];
	//	NSString *boundary = [NSString stringWithString:@"------------0xKhTmLbOuNdArY"];
	//	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary = %@", boundary];
	//	[theRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
	//
	//	//adding the body:
	//	NSMutableData *postBody = [NSMutableData data];
	//	[postBody appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	//
	//	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name = \"properties\"; filename = \"properties.plist\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	//	[postBody appendData:[[NSString stringWithString: @"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	//	[postBody appendData:[@"blah"];
	//		[postBody appendData:[[NSString stringWithFormat:@"\r\n%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	//
	//
	//	[theRequest setValue:@"multipart/form-data, boundary = AaB03x" forHTTPHeaderField:@"Content-Type"];
	//	[theRequest setHTTPBody:postBody];
	//	[theRequest setHTTPMethod:@"POST"];

	if (synchro) { // || receivedData) {
		NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
		[self loadNewWebData:data];
	} else {
        if (receivedData) {
            NSLog(@"Already checking %p", receivedData);
            return;
        }

		NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest
																	 delegate:self];

		if (theConnection) {
			receivedData = [[NSMutableData data] retain];
			[QSTasks updateTask:@"UpdatePlugInInfo" status:@"Updating Plug-in Info" progress:0.0];
		}
	}
}

- (void)loadPlugInInfo:(NSArray *)array {
	NSEnumerator *e = [array objectEnumerator];
	id value;
	NSString *key;
	QSPlugIn *plugin;
	while(value = [e nextObject]) {
		key = [value objectForKey:@"CFBundleIdentifier"];
		if (!key) continue;
		[plugInWebData setObject:value forKey:key];
		if (plugin = [knownPlugIns objectForKey:key]) {
			[plugin setData:value];
			//[availablePlugIns addObject:plugin];
			//if (VERBOSE) NSLog(@"Bind Old %@ to %@", key, [plugin bundle]);
		} else {
			plugin = [QSPlugIn plugInWithWebInfo:value];
			[knownPlugIns setObject:plugin forKey:key];
			//if (VERBOSE) NSLog(@"Created New %@", key);
			//		NSLog(@"known %@", knownPlugIns);
		}
	}

}

- (void)loadWebPlugInInfo {
	//	NSLog(@"known %@", knownPlugIns);
	if (!plugInWebData)
		[self loadInfo];

	[self loadPlugInInfo:[plugInWebData allValues]];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [connection release];
    [receivedData release];
	receivedData = nil;

	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInfoFailedNotification object:self userInfo:nil];
	[QSTasks removeTask:@"UpdatePlugInInfo"];
}

- (void)clearOldWebData {
	NSArray *webPlugIns = [[knownPlugIns allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isInstalled == 0"]];
	webPlugIns = [webPlugIns valueForKey:@"identifier"];
	if (VERBOSE) NSLog(@"Invalidating %@", webPlugIns);
	[knownPlugIns removeObjectsForKeys:webPlugIns];
	[plugInWebData removeAllObjects];
	[[knownPlugIns allValues] makeObjectsPerformSelector:@selector(clearWebData)];

#warning allow remote invalidation of installed web plugin data
}

- (void)loadNewWebData:(NSData *)data {
	NSString *errorString;
	NSDictionary *prop = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&errorString];
	if (!prop) {
	errorCount++;
	} else {
		NSLog(@"Downloaded info for %d plug-in(s) ", [[prop objectForKey:@"plugins"] count]);
		//	NSEnumerator *e = [prop objectEnumerator];
		if ([prop count] && [[prop objectForKey:@"fullIndex"] boolValue])
			[self clearOldWebData];

		[self loadPlugInInfo:[prop objectForKey:@"plugins"]];

		plugInWebDownloadDate = [[NSDate date] retain];
		[self writeInfo];

		[self willChangeValueForKey:@"knownPlugInsWithWebInfo"];
		[self didChangeValueForKey:@"knownPlugInsWithWebInfo"];
	}
	[QSTasks removeTask:@"UpdatePlugInInfo"];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInfoLoadedNotification object:knownPlugIns];

}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self loadNewWebData:receivedData];
	[connection release];
	[receivedData release];
	receivedData = nil;
}

- (NSArray *)knownPlugInsWithWebInfo {
	if (!plugInWebData) {
		[self loadWebPlugInInfo];
	}
	//	NSLog(@"%f last", -[plugInWebDownloadDate timeIntervalSinceNow]);
	if (!plugInWebDownloadDate || (-[plugInWebDownloadDate timeIntervalSinceNow] > 3*HOURS) ) {
		if (lastCheck - [NSDate timeIntervalSinceReferenceDate] > 3*HOURS && errorCount < 21) {
			if ([knownPlugIns count] <30) {
				[self downloadWebPlugInInfoIgnoringDate];
			} else {
				[self downloadWebPlugInInfo];
			}
			lastCheck = [NSDate timeIntervalSinceReferenceDate];
		}
	}
	//NSLog(@"knownPlugIns %@", knownPlugIns);
	//availablePlugIns = [[plugIns allValues] retain];
	return [knownPlugIns allValues];
}

- (void)deletePlugIns:(NSArray *)deletePlugIns fromWindow:(NSWindow *)window {
	NSArray *loaded = [[self loadedPlugIns] allValues];
	BOOL needsRelaunch = nil != [deletePlugIns firstObjectCommonWithArray:loaded];

	int result;
	if (needsRelaunch)
		result = NSRunCriticalAlertPanel(@"Delete plug-ins?", @"Would you like to delete the selected plug-ins? A relaunch will be required", @"Delete and Relaunch", @"Cancel", nil, window);
	else
		result = NSRunCriticalAlertPanel(@"Delete plug-ins?", @"Would you like to delete the selected plug-ins?", @"Delete", @"Cancel", nil, window);

	if (result) {
		BOOL success = 1;
		foreach(plugin, deletePlugIns) {
			success = success && [plugin delete];
		}
		//	[self reloadPlugInsList:nil];
		if (!success) NSBeep();
		if (needsRelaunch) [NSApp relaunch:nil];
	}

}
- (void)bundleDidLoad:(NSNotification *)aNotif {
	if (DEBUG_PLUGINS)
		NSLog(@"Loaded Bundle: %@ Classes: %@", [[[aNotif object] bundlePath] lastPathComponent] , [[[aNotif userInfo] objectForKey:@"NSLoadedClasses"] componentsJoinedByString:@", "]);
}

- (BOOL)liveLoadPlugIn:(QSPlugIn *)plugin {
	if ([plugin isKindOfClass:[NSBundle class]]) {
		NSLog(@"asked to load bundle instead of plugin");
		plugin = [QSPlugIn plugInWithBundle:(NSBundle *)plugin];
	}
	if (![plugin enabled]) {
		NSLog(@"Enabled Prerequisite: %@", plugin);
		[plugin setEnabled:YES];
	}

	if (![self plugInIsMostRecent:plugin inGroup:nil]) return NO; 	//Skip if not most recent
	if (![self plugInMeetsRequirements:plugin]) return NO; 						//Skip if does not meet requirements
	if (![self plugInMeetsDependencies:plugin]) return NO; 						//Skip if does not meet dependencies

	return [plugin registerPlugIn];
}

- (void)checkForUnmetDependencies {
    if (VERBOSE) NSLog(@"Unmet Dependencies: %@", dependingPlugIns);
	NSMutableArray *array = [NSMutableArray array];
	NSMutableSet *dependingNames = [NSMutableSet set];
	foreachkey(ident, plugins, dependingPlugIns) {
		if ([plugins count]) {
			NSArray *dependencies = [[plugins lastObject] dependencies];
			[array addObject:[dependencies objectWithValue:ident forKey:@"id"]];

			[dependingNames addObjectsFromArray:[plugins valueForKey:@"name"]];
		}
	}
	//	NSLog(@"installing! %@", array);
	if (![array count]) return;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSAlwaysInstallPrerequisites"]) {
		[self installPlugInsForIdentifiers:[array valueForKey:@"id"] version:nil];

	} else {
		//[NSApp activateIgnoringOtherApps:YES];
		int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Plug-in Requirements", nil] ,
												  @"Using [%@] requires installation of [%@] .", @"Install", @"Disable", @"Always Install Requirements",
												  [[dependingNames allObjects] componentsJoinedByString:@", "] ,
												  [[array valueForKey:@"name"] componentsJoinedByString:@", "]);
		if (selection == 1) {
			[self installPlugInsForIdentifiers:[array valueForKey:@"id"] version:nil];
		} else if (selection == -1) {  //Go to web site
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"QSAlwaysInstallPrerequisites"];
			[self installPlugInsForIdentifiers:[array valueForKey:@"id"] version:nil];

		}
	}

}

- (void)loadPlugInsAtLaunch {
	//NSDate *date = [NSDate date];

	// load main bundle
	[[QSPlugIn plugInWithBundle:[NSBundle mainBundle]]registerPlugIn];

	// Get all locally installed plugins
	NSMutableArray *newLocalPlugIns = [NSBundle performSelector:@selector(bundleWithPath:) onObjectsInArray:[self allBundles]];
    [newLocalPlugIns removeObject:[NSNull null]];
	newLocalPlugIns = [QSPlugIn performSelector:@selector(plugInWithBundle:) onObjectsInArray:newLocalPlugIns];
	[newLocalPlugIns removeObject:[NSNull null]];

	NSMutableDictionary	*plugInsToLoadByID = [NSMutableDictionary dictionary];

    NSArray *disabledBundles = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSDisabledPlugIns"];
     
    // !!! Andre Berg 20091013: Changed the objectEnumerators below to 10.5's fast enumeration    
	//NSLog(@"toload %@ %@", [newLocalPlugIns valueForKey:@"bundlePath"] , newLocalPlugIns);
    // !!! Andre Berg 20091017: change to foreach macro
    // QSPlugIn * plugin;
    // If plugin should be loaded, add it to the list
    foreach(plugin, newLocalPlugIns) {
        if (![self plugInIsMostRecent:plugin inGroup:plugInsToLoadByID]) continue;      //Skip if not most recent
		if (![plugin identifier]) continue;
		[localPlugIns setObject:plugin forKey:[plugin identifier]];
		[knownPlugIns setObject:plugin forKey:[plugin identifier]];
		if ([disabledBundles containsObject:[plugin identifier]]) continue; 			//Skip if disabled
		if (![self plugInMeetsRequirements:plugin]) continue;                           //Skip if does not meet requirements
		if (![self plugInMeetsDependencies:plugin]) continue;                           //Skip if does not meet dependencies
		[plugInsToLoadByID setObject:plugin forKey:[plugin identifier]];
    }

	//	NSLog(@"toload %@", plugInsToLoadByID);
	// load all valid plugins    
    NSArray * plugInsToLoad = [plugInsToLoadByID allValues];
    NSArray * localPlugins = [localPlugIns allValues];
    foreach (plugin, localPlugins) {
        if ([plugInsToLoad containsObject:plugin])
			[plugin registerPlugIn];
    }

	[self checkForUnmetDependencies];
	[self suggestOldPlugInRemoval];
	//if (DEBUG_STARTUP) NSLog(@"PlugIn Load Complete (%dms) ", (int)(-[date timeIntervalSinceNow] *1000));
	startupLoadComplete = YES;
}

#define appSupportSubpath @"Application Support/Quicksilver/PlugIns"

- (NSMutableArray *)allBundles {

	NSEnumerator *searchPathEnum = nil;
	NSString *currPath = nil;
	NSMutableSet *bundleSearchPaths = [NSMutableSet set];
	NSMutableArray *allBundles = [NSMutableArray array];
	//[allBundles addObject:[[NSBundle mainBundle] bundlePath]];

	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];

	if ((int) getenv("QSDisableExternalPlugIns")) {
		NSLog(@"External PlugIns Disabled");
	} else {
		NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
        
// 		searchPathEnum = [librarySearchPaths objectEnumerator];
// 		while(currPath = [searchPathEnum nextObject])
// 			[bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];
        
        // !!! Andre Berg 20091017: change to foreach macro
		foreach(currPath, librarySearchPaths) {
            [bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];
        }
		[bundleSearchPaths addObject:QSApplicationSupportSubPath(@"PlugIns", NO)];
		[bundleSearchPaths addObject:[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]];
		[bundleSearchPaths addObject:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"PlugIns"]];
		[bundleSearchPaths addObject:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Embedded/PlugIns"]];
		[bundleSearchPaths addObject:[[NSFileManager defaultManager] currentDirectoryPath]];
		[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PlugIns"]];
		[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"Embedded/PlugIns"]];
		//[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PrivatePlugIns"]];

		NSArray *paths = [[NSUserDefaults standardUserDefaults] arrayForKey:@"QSAdditionalPlugInPaths"];
		paths = [paths valueForKey:@"stringByStandardizingPath"];
		[bundleSearchPaths addObjectsFromArray:paths];

		[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PrivatePlugIns"]];
	}

// 	searchPathEnum = [bundleSearchPaths objectEnumerator];
// 	while(currPath = [searchPathEnum nextObject]) {
// 		NSEnumerator *bundleEnum;
// 		NSString *curPlugInPath;
// 		bundleEnum = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:nil] objectEnumerator];
// 		if (bundleEnum) {
// 			while(curPlugInPath = [bundleEnum nextObject]) {
// 				if ([[curPlugInPath pathExtension] caseInsensitiveCompare:@"qsplugin"] == NSOrderedSame) {
// 					[allBundles addObject:[currPath stringByAppendingPathComponent:curPlugInPath]];
// 				}
// 			}
// 		}
// 	}
    
    // !!! Andre Berg 20091017: change to foreach macro
	foreach(currPath, bundleSearchPaths) {
		NSString *curPlugInPath;
        NSArray * dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:nil];
		if (dirContents) {
			foreach(curPlugInPath, dirContents) {
				if ([[curPlugInPath pathExtension] caseInsensitiveCompare:@"qsplugin"] == NSOrderedSame) {
					[allBundles addObject:[currPath stringByAppendingPathComponent:curPlugInPath]];
				}
			}
		}
	}

	return allBundles;
}
- (BOOL)plugInMeetsRequirements:(QSPlugIn *)plugIn; {
	NSString *error;
	if (![plugIn meetsRequirements:&error]) {
		if (error) [plugIn setLoadError:error];
		if (DEBUG_PLUGINS) NSLog(@"Requirements not met %@:\r%@", plugIn, error);
		return NO;
	}
	return YES;
}
/*!
@method
 @abstract  (brief description)
 @discussion (comprehensive description)
 */

- (BOOL)plugInMeetsDependencies:(QSPlugIn *)plugIn; {
	NSArray *unmet = [plugIn unmetDependencies];

	if ([unmet count]) {

		//NSLog(@"unmet? %@", unmet);
		foreach(dependency, unmet) {
			NSString *iden = [dependency objectForKey:@"id"];
			NSMutableArray *depending = [dependingPlugIns objectForKey:iden];
			if (!depending) [dependingPlugIns setObject:(depending = [NSMutableArray array]) forKey:iden];
			[depending addObject:plugIn];
			//NSLog(@"depends %@", depending);
		}
		return NO;
	}
	return YES;
}

- (BOOL)plugInIsMostRecent:(QSPlugIn *)plugIn inGroup:(NSDictionary *)loadingBundles; {
	//	if (![bundle isKindOfClass:[NSBundle class]]) return NO;
	NSString *ident = [plugIn bundleIdentifier];
	QSPlugIn *dupPlugIn = nil;
	//NSString *error;

#warning should detect installation of a disabled plugin
	if (dupPlugIn = [loadedPlugIns objectForKey:ident]) {// check if the bundle is already loaded. if so need to restart.
													 //NSLog(@"Bundle already loaded: %@", dupPlugIn);
		return NO;

	} else if ((dupPlugIn = [loadingBundles objectForKey:ident]) && ![plugIn isEqual:dupPlugIn]) {
		//	NSLog(@"Loading Duplicate %@ %@", dupPlugIn, plugIn);
		NSFileManager *manager = [NSFileManager defaultManager];
		NSComparisonResult sorting = [[dupPlugIn buildVersion] versionCompare:[plugIn buildVersion]];
		if (sorting == NSOrderedSame) {
			sorting	 = [[[manager fileAttributesAtPath:[dupPlugIn bundlePath] traverseLink:YES] fileModificationDate]
							compare:[[manager fileAttributesAtPath:[plugIn bundlePath] traverseLink:YES] fileModificationDate]];
		}
		if (sorting >= 0) {
			[oldPlugIns addObject:plugIn];
			return NO; // a newer version of this plugin has already been seen
		}
		[oldPlugIns addObject:dupPlugIn];
	}

	return YES;
}

- (void)suggestOldPlugInRemoval {
	//NSLog(@"old: %@", oldPlugIns);
	if ([oldPlugIns count]) {
		if (1) {//DEBUG || [[NSUserDefaults standardUserDefaults] boolForKey:@"QSIgnoreOldPlugIns"]) {
			  //	if (VERBOSE) NSLog(@"Ignored Old Plugins: %@", [[oldPlugIns valueForKeyPath:@"path"] componentsJoinedByString:@"\r"]);
		} else {
			foreach(plugIn, oldPlugIns) {
				NSLog(@"Deleting Old Duplicate Plug-in:\r%@", [plugIn path]);
				[[NSFileManager defaultManager] removeItemAtPath:[plugIn path] error:nil];
			}
		}
	}
}

- (NSMutableDictionary *)localPlugIns {
	return localPlugIns;
}
- (void)setLocalPlugIns:(NSMutableDictionary *)newLocalPlugIns {
	[localPlugIns release];
	localPlugIns = [newLocalPlugIns retain];
}

- (NSMutableDictionary *)knownPlugIns {
	return knownPlugIns;
}
- (void)setKnownPlugIns:(NSMutableDictionary *)newKnownPlugIns {
	[knownPlugIns release];
	knownPlugIns = [newKnownPlugIns retain];
}

- (NSMutableDictionary *)loadedPlugIns {
	return loadedPlugIns;
}
- (void)setLoadedPlugIns:(NSMutableDictionary *)newLoadedPlugIns {
	[loadedPlugIns release];
	loadedPlugIns = [newLoadedPlugIns retain];
}

- (BOOL)checkForPlugInUpdates {
	return [self checkForPlugInUpdatesForVersion:nil];
}

- (BOOL)checkForPlugInUpdatesForVersion:(NSString *)version {
	if (!plugInWebData)
		[self loadWebPlugInInfo];

	int newPlugInsAvailable = 0;
	//NSDictionary *bundleIDs = [QSReg identifierBundles];

	if (!updatedPlugIns) updatedPlugIns = [[NSMutableArray array] retain];
	else [updatedPlugIns removeAllObjects];

	[self downloadWebPlugInInfoFromDate:plugInWebDownloadDate forUpdateVersion:version synchronously:YES];

	NSEnumerator *e = [knownPlugIns objectEnumerator];
	QSPlugIn *thisPlugIn;
	while(thisPlugIn = [e nextObject]) {
		if ([thisPlugIn needsUpdate]) {
			[updatedPlugIns addObject:thisPlugIn];
			newPlugInsAvailable++;
		}
	}

	if (newPlugInsAvailable) {
		NSArray *names = [updatedPlugIns valueForKey:@"name"];
		int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Plug-in Updates are available", nil] ,
												  @"%@", @"Install", @"Cancel", nil, [names componentsJoinedByString:@", "]);
		if (selection == 1) {
			updatingPlugIns = YES;
			[self installPlugInsForIdentifiers:[updatedPlugIns valueForKey:@"identifier"] version:version];
			return YES;
		}
		return NO;
	}
	return NO;
}

- (BOOL)updatePlugInsForNewVersion:(NSString *)version {
	supressRelaunchMessage = YES;
	return [self checkForPlugInUpdatesForVersion:version];
}

- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory {
	if (!path) return nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/ditto"];

	[task setArguments:[NSArray arrayWithObjects:@"-x", @"-rsrc", path, tempDirectory, nil]];
	[task launch];
	[task waitUntilExit];
	int status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:nil];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		return [manager contentsOfDirectoryAtPath:tempDirectory error:nil];
	} else {
		return nil;
	}

}

- (NSArray *)installPlugInFromCompressedFile:(NSString *)path {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *destination = psMainPlugInsLocation;
	NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
	[manager createDirectoryAtPath:tempDirectory withIntermediateDirectories:NO attributes:nil error:nil];

	NSArray *extracted = [self extractFilesFromQSPkg:path toPath:tempDirectory];

	//NSLog(@"extra %@", extracted);
	NSMutableArray *installedPlugIns = [NSMutableArray array];
	NSEnumerator *e = [extracted objectEnumerator];
	NSString *file = nil;
	while (file = [e nextObject]) {
		NSString *outFile = [tempDirectory stringByAppendingPathComponent:file];
		NSString *destination = [self installPlugInFromFile:outFile];
		if (destination) [installedPlugIns addObject:destination];
	}
	//NSLog(@"installed %@", installedPlugIns);
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	[manager removeItemAtPath:tempDirectory error:nil];
	return installedPlugIns;

}

- (NSString *)installPlugInFromFile:(NSString *)path {
	NSString *destinationFolder = psMainPlugInsLocation;
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createDirectoriesForPath:destinationFolder];
	NSString *destinationPath = [destinationFolder stringByAppendingPathComponent: [path lastPathComponent]];
	if (![destinationPath isEqualToString:path]) {
		if (![manager removeItemAtPath:destinationPath error:nil]);
	}
	if (![manager moveItemAtPath:path toPath:destinationPath error:nil]) NSLog(@"move failed, %@, %@", path, destinationPath);
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destinationFolder];
	return destinationPath;
}

- (NSMutableArray *)updatedPlugIns { return updatedPlugIns;  }

- (void)updateDownloadCount {
	if (![[self downloadsQueue] count]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSPlugInUpdatesFinished" object:self];
		[self setInstallStatus:nil];
		[[QSTaskController sharedInstance] removeTask:@"QSPlugInInstalling"];

		[self setIsInstalling:NO];
	} else {
		NSString *status = [NSString stringWithFormat:@"Installing %d Plug-in(s)", [[self downloadsQueue] count]];
		//NSString *status = [NSString stringWithFormat:@"Installing %@ (%d of %d) ", [[self currentDownload] name] , [[self downloadsQueue] count] , downloadsCount];
		[self setInstallStatus:status];
		//[self setInstallProgress:[self downloadProgress]];
		[[QSTaskController sharedInstance] updateTask:@"QSPlugInInstalling" status:status progress:-1];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"QSUpdateControllerStatusChanged" object:self];
}

- (BOOL)plugInWasInstalled:(NSString *)plugInPath {
	NSBundle *bundle = [NSBundle bundleWithPath:plugInPath];
    if (bundle == nil) {
        NSLog(@"Failed to get bundle for plugin at path %@", plugInPath);
        return NO;
    }
	NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
	QSPlugInManager *manager = [QSPlugInManager sharedInstance];

	QSPlugIn *plugin = [manager plugInBundleWasInstalled:bundle];

	BOOL liveLoaded = [manager liveLoadPlugIn:plugin];

	if (![[self downloadsQueue] count])
		[manager checkForUnmetDependencies];
	//[self updateDownloadCount];

	if (!liveLoaded && (updatingPlugIns || !warnedOfRelaunch) && ![[self downloadsQueue] count] && !supressRelaunchMessage) {
		int selection = NSRunInformationalAlertPanel(@"Install complete", @"Some plug-ins will not be available until Quicksilver is relaunched.", @"Relaunch", @"Later", nil);

		if (selection == 1) {
			[NSApp relaunch:self];
		}
		updatingPlugIns = NO;
		warnedOfRelaunch = YES;
		return YES;
	}
	NSString *title = [NSString stringWithFormat:@"%@ Installed", (name?name:@"Plug-in")];

	NSImage *image = [NSImage imageNamed:@"QSPlugIn"];
	[image setSize:NSMakeSize(128, 128)];

	if (showNotifications)
		QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"QSPlugInInstalledNotification", QSNotifierType, image, QSNotifierIcon, title, QSNotifierTitle, (liveLoaded?nil:@"Relaunch required"), QSNotifierText, nil]);
	return YES;
}

- (BOOL)installPlugInsFromFiles:(NSArray *)fileList {
	//NSBeep();

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	int selection = [defaults boolForKey:kClickInstallWithoutAsking];

	if (!selection) {//[NSApp activateIgnoringOtherApps:YES];
		selection = NSRunInformationalAlertPanel(@"Install plug-ins?", @"Do you wish to move selected items to Quicksilver's plug-in folder?", @"Install", @"Cancel", @"Always Install Plug-ins");
	}
	if (selection) {
		if (selection<0) {
			[defaults setBool:YES forKey:kClickInstallWithoutAsking];
			[defaults synchronize];
		}

		//NSString *destination = psMainPlugInsLocation;
		NSString *newPlugIn = nil;

		NSString *path;
		NSEnumerator *enumerator = [fileList objectEnumerator];
		while(path = [enumerator nextObject]) {
			if ([[path pathExtension] caseInsensitiveCompare:@"qspkg"] == NSOrderedSame)
				newPlugIn = [[self installPlugInFromCompressedFile:path] lastObject];
			else if ([[path pathExtension] caseInsensitiveCompare:@"qsplugin"] == NSOrderedSame)
				newPlugIn = [self installPlugInFromFile:path];

			[self plugInWasInstalled:newPlugIn];
		}

	}
	return YES;
}

- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs {
	return [self installPlugInsForIdentifiers:bundleIDs version:nil];
}

- (NSString *)urlStringForPlugIn:(NSString *)ident version:(NSString *)version {
	if (!version) version = [NSApp buildVersion];
	return [NSString stringWithFormat:@"http://qs0.blacktree.com/quicksilver/plugins/download.php?qsversion=%d&id=%@", [version hexIntValue] , ident];
}

- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs version:(NSString *)version {
	if (VERBOSE) NSLog(@"Update: %@", bundleIDs);
	NSEnumerator *e = [bundleIDs objectEnumerator];
	NSString *ident = nil;
	if (!version) version = [NSApp buildVersion];
	while(ident = [e nextObject]) {
		NSString *url = [self urlStringForPlugIn:ident version:version];
		NSLog(@"Downloading %@", url);
		[self performSelectorOnMainThread:@selector(installPlugInWithInfo:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:ident, @"id", url, @"url", nil] waitUntilDone:YES];
	}

	NSString *status = [NSString stringWithFormat:@"Installing %d Plug-in(s) ", [[self downloadsQueue] count]];
	[[QSTaskController sharedInstance] updateTask:@"QSPlugInInstalling" status:status progress:-1];
	[self setInstallStatus:status];
	[self setIsInstalling:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSUpdateControllerStatusChanged" object:self];
	[self performSelectorOnMainThread:@selector(startDownloadQueue) withObject:nil waitUntilDone:YES];
	return YES;
}

- (void)installPlugInWithInfo:(NSDictionary *)info {
	[[self downloadsQueue] addObject:[QSURLDownload downloadWithURL:[NSURL URLWithString:[info objectForKey:@"url"]] delegate:self]];
	[self updateDownloadProgressInfo];
}

- (void)startDownloadQueue {
    int queuedCount = [[self downloadsQueue] count];
    if (currentDownloads < MAX_CONCURRENT_DOWNLOADS && queuedCount != 0) {
        NSArray* array = [[self downloadsQueue] objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, (queuedCount < MAX_CONCURRENT_DOWNLOADS ? queuedCount : MAX_CONCURRENT_DOWNLOADS))]];
        foreach(download, array) {
            [download start];
            currentDownloads++;
        }
	}
}

- (void)handleURL:(NSURL *)url {

}
- (NSImage *)image {
	NSLog(@"eep");
	return nil;
}

- (BOOL)handleInstallURL:(NSURL *)url {
	NSString *specifier = [url resourceSpecifier];
	if ([specifier hasPrefix:@"//"])
		specifier = [specifier substringFromIndex:2];
	NSArray *components = [specifier componentsSeparatedByString:@"&"];
	//NSLog(@"PlugIn %@", components);
	//	url = [NSURL URLWithString:[NSString stringWithFormat:@"http://qs0.blacktree.com/quicksilver/download.php?%@", specifier]];
	NSString *idString = [components objectAtIndex:0];
	if ([idString hasPrefix:@"id="])
		idString = [idString substringFromIndex:3];

	NSString *nameString = [components lastObject];
	NSString *name = @"<Unknown Plug-in>";
	if ([nameString hasPrefix:@"name="])
		name = [[nameString substringFromIndex:5] URLDecoding];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	int selection = [defaults boolForKey:kWebInstallWithoutAsking];
	if (!selection)
		selection = NSRunInformationalAlertPanel(name, @"Do you wish to install the %@?", @"Install", @"Cancel", @"Always Install Plug-ins", name);
	if (selection) {
		if (selection<0) {
			[defaults setBool:YES forKey:kWebInstallWithoutAsking];
			[defaults synchronize];
		}
		[self installPlugInsForIdentifiers:[idString componentsSeparatedByString:@", "] version:nil];
		//		[self installPlugInFromURL:url];
	}
	return YES;
}

- (NSString *)currentStatus {
	return [NSString stringWithFormat:@"%d remaining", [[self downloadsQueue] count]];
}

- (void)updateDownloadProgressInfo {
	//NSLog(@"count %d %d %f", [[self downloadsQueue] count], downloadsCount, [[[self downloadsQueue] objectAtIndex:0] progress]);
    float progress = 0;
    foreach(download, [self downloadsQueue]) {
        progress *= [download progress];
    }
	[self setInstallProgress:progress];
}

- (float) downloadProgress {return [self installProgress];}

- (NSMutableArray *)downloadsQueue {
	if (!queuedDownloads)
		queuedDownloads = [[NSMutableArray alloc] init];
	return queuedDownloads;
}

- (void)downloadDidUpdate:(QSURLDownload *)download {
	[self updateDownloadProgressInfo];
}

- (void)downloadDidFinish:(QSURLDownload *)download {
	//NSLog(@"path %@", download);
	//NSLog(@"FINISHED %@ %@", download, currentDownload);
	NSString *path = [download destination];
	if (path) {
		NSString *plugInPath = [[self installPlugInFromCompressedFile:path] lastObject];
        [download cancel];
		[[self downloadsQueue] removeObject:download];
		[self plugInWasInstalled:plugInPath];
    }
    else
        NSLog(@"Failed getting path of download at url %@", [download URL]);
    currentDownloads--;
    
    [self startDownloadQueue];
    [self updateDownloadCount];
}

- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
	[[self plugInWithID:[download userInfo]] downloadFailed];
 //NSLog(@"Download failed! Error - %@ %@", [[[download request] URL] absoluteString] , [error localizedDescription] , [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	NSRunInformationalAlertPanel(@"Download Failed", @"%@\r%@", nil, nil, nil, [[download URL] absoluteString], [error localizedDescription]);
    [download cancel];
    [[self downloadsQueue] removeObject:download];
    currentDownloads--;
    
	[self startDownloadQueue];
	[self updateDownloadCount];
}

- (void)cancelPlugInInstall {
    foreach(download, [self downloadsQueue])
        [download cancel];
	[[self downloadsQueue] removeAllObjects];
	[self updateDownloadCount];
}


- (NSString *)installStatus {
	return installStatus;
}
- (void)setInstallStatus:(NSString *)newInstallStatus {
	if (installStatus != newInstallStatus) {
		[installStatus release];
		installStatus = [newInstallStatus retain];
	}
}

- (float) installProgress {
	return installProgress;
}
- (void)setInstallProgress:(float)newInstallProgress {
	//NSLog(@"prof %f", newInstallProgress);
	installProgress = newInstallProgress;
}

- (BOOL)isInstalling {
	return isInstalling;
}
- (void)setIsInstalling:(BOOL)flag {
	isInstalling = flag;
}

- (BOOL)showNotifications { return showNotifications;  }
- (void)setShowNotifications: (BOOL)flag {
	showNotifications = flag;
}

@end
