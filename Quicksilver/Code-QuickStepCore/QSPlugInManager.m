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
		obsoletePlugIns = [[NSMutableDictionary alloc] init];

        // download queues
		queuedDownloads = [[NSMutableArray alloc] init];
		activeDownloads = [[NSMutableSet alloc] init];

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
	for(QSPlugIn * dep in deps) {
		if (![[dep unmetDependencies] count])
			[self liveLoadPlugIn:dep];
	}
	[dependingPlugIns removeObjectForKey:[plugin identifier]];
	// store a list of obsolete plug-ins and the one that replaces it
	for (NSString *obsoletePlugIn in [plugin obsoletes]) {
		[obsoletePlugIns setObject:[plugin identifier] forKey:obsoletePlugIn];
	}
	[self removeObsoletePlugIns];
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
	NSString *fetchURLString = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSPluginInfoURL"];
    if (!fetchURLString)
        fetchURLString = kPluginInfoURL;
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
		[query addObject:[NSString stringWithFormat:@"sids=%@", [secretIdentifiers componentsJoinedByString:@","]]];
	}

	fetchURLString = [fetchURLString stringByAppendingFormat:@"?%@", [query componentsJoinedByString:@"&"]];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Get web info: %@", fetchURLString);
#endif
	return fetchURLString;
}

- (void)downloadWebPlugInInfoFromDate:(NSDate *)date forUpdateVersion:(NSString *)version synchronously:(BOOL)synchro {
	NSString *fetchURLString = [self webInfoURLFromDate:(NSDate *)date forUpdateVersion:(NSString *)version];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:5.0];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];

	NSLog(@"Fetching plugin data from %@", fetchURLString);

	if (synchro) { // || receivedData) {
		NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
		[self loadNewWebData:data];
	} else {
        if (receivedData) {
#ifdef DEBUG
            NSLog(@"Already checking %p", receivedData);
#endif
            return;
        }
        //   data must be retained here because it is needed for the callbacks
        receivedData = [[NSMutableData data] retain];
		
		// theConnection is released in connectionDidFinishLoading or connection:didFailWithError (p_j_r thinks...)
		NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest
																	 delegate:self];

		if (theConnection) {
			[QSTasks updateTask:@"UpdatePlugInInfo" status:@"Updating Plug-in Info" progress:0.0];
		} else {
			NSLog(@"Problem downloading plugin data. Perhaps an invalid URL");
            [receivedData release], receivedData = nil;
        }
	}
}

- (void)loadPlugInInfo:(NSArray *)array {
	id value;
	NSString *key;
	QSPlugIn *plugin;
	for(value in array) {
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
	[QSTasks updateTask:@"UpdatePlugInInfo" status:@"Updating Plug-in Info" progress:1.0];
    [connection release];
    [receivedData release];
	receivedData = nil;

	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInfoFailedNotification object:self userInfo:nil];
	[QSTasks removeTask:@"UpdatePlugInInfo"];
}

- (void)clearOldWebData {
	NSArray *webPlugIns = [[knownPlugIns allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isInstalled == 0"]];
	webPlugIns = [webPlugIns valueForKey:@"identifier"];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Invalidating %@", webPlugIns);
#endif
	[knownPlugIns removeObjectsForKeys:webPlugIns];
	[plugInWebData removeAllObjects];
	[[knownPlugIns allValues] makeObjectsPerformSelector:@selector(clearWebData)];

#warning allow remote invalidation of installed web plugin data
}

- (void)loadNewWebData:(NSData *)data {
	NSString *errorString;
	NSDictionary *prop = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&errorString];
	if (!prop) {
		NSLog(@"Could not load new plugins data");
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
	[QSTasks updateTask:@"UpdatePlugInInfo" status:@"Updating Plug-in Info" progress:1.0];
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
		result = NSRunCriticalAlertPanel(@"Delete plug-ins?", @"Would you like to delete the selected plug-ins? A relaunch will be required", @"Delete and Relaunch", @"Cancel", nil);
	else
		result = NSRunCriticalAlertPanel(@"Delete plug-ins?", @"Would you like to delete the selected plug-ins?", @"Delete", @"Cancel", nil);

	if (result) {
		BOOL success = YES;
		for(QSPlugIn * plugin in deletePlugIns) {
			success = success && [plugin delete];
		}
		//	[self reloadPlugInsList:nil];
		if (!success) NSBeep();
		if (needsRelaunch) [NSApp relaunch:nil];
	}

}
- (void)bundleDidLoad:(NSNotification *)aNotif {
	
#ifdef DEBUG
	if (DEBUG_PLUGINS)
		NSLog(@"Loaded Bundle: %@ Classes: %@", [[[aNotif object] bundlePath] lastPathComponent] , [[[aNotif userInfo] objectForKey:@"NSLoadedClasses"] componentsJoinedByString:@", "]);
#endif
	
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

	if (![self plugInIsMostRecent:plugin inGroup:localPlugIns]) return NO; 	//Skip if not most recent
	if (![self plugInMeetsRequirements:plugin]) return NO; 						//Skip if does not meet requirements
	if (![self plugInMeetsDependencies:plugin]) return NO; 						//Skip if does not meet dependencies

	return [plugin registerPlugIn];
}

- (void)checkForUnmetDependencies {
#ifdef DEBUG
    if (VERBOSE) NSLog(@"Unmet Dependencies: %@", dependingPlugIns);
#endif
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

- (void)removeObsoletePlugIns
{
	if (![obsoletePlugIns count]) {
		return;
	}
	NSSet *currentlyLoaded = [NSSet setWithArray:[loadedPlugIns allKeys]];
	for (NSString *oplugin in [obsoletePlugIns allKeys]) {
		if ([currentlyLoaded containsObject:oplugin]) {
			QSPlugIn *obsolete = (QSPlugIn *)[loadedPlugIns objectForKey:oplugin];
			NSLog(@"removing obsolete plug-in: %@", [obsolete name]);
			[obsolete delete];
		}
	}
}

- (void)loadPlugInsAtLaunch {

#ifdef DEBUG
	NSDate *date = [NSDate date];
#endif
	
	// load main bundle
	[[QSPlugIn plugInWithBundle:[NSBundle mainBundle]]registerPlugIn];

	// Get all locally installed plugins
	NSMutableArray *newLocalPlugIns = [NSBundle performSelector:@selector(bundleWithPath:) onObjectsInArray:[self allBundles]];
    [newLocalPlugIns removeObject:[NSNull null]];
	newLocalPlugIns = [QSPlugIn performSelector:@selector(plugInWithBundle:) onObjectsInArray:newLocalPlugIns];
	[newLocalPlugIns removeObject:[NSNull null]];

	NSMutableDictionary	*plugInsToLoadByID = [NSMutableDictionary dictionary];

    NSArray *disabledBundles = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSDisabledPlugIns"];
     
	//NSLog(@"toload %@ %@", [newLocalPlugIns valueForKey:@"bundlePath"] , newLocalPlugIns);
    // !!! Andre Berg 20091017: change to foreach macro
    // QSPlugIn * plugin;
    // If plugin should be loaded, add it to the list
    for (QSPlugIn * plugin in newLocalPlugIns) {
        if (![self plugInIsMostRecent:plugin inGroup:localPlugIns]) continue;      //Skip if not most recent
		if (![plugin identifier]) continue;
		[localPlugIns setObject:plugin forKey:[plugin identifier]];
		[knownPlugIns setObject:plugin forKey:[plugin identifier]];
		if ([disabledBundles containsObject:[plugin identifier]]) continue; 			//Skip if disabled
		if (![self plugInMeetsRequirements:plugin]) continue;                           //Skip if does not meet requirements
		if (![self plugInMeetsDependencies:plugin]) continue;                           //Skip if does not meet dependencies
		[plugInsToLoadByID setObject:plugin forKey:[plugin identifier]];
    }
	// load all valid plugins    
    NSArray * plugInsToLoad = [plugInsToLoadByID allValues];
    NSArray * localPlugins = [localPlugIns allValues];
    
        for (QSPlugIn *plugin in localPlugins) {
            if ([plugInsToLoad containsObject:plugin])
                [plugin registerPlugIn];
        }
	[self checkForUnmetDependencies];
	[self suggestOldPlugInRemoval];
	
	startupLoadComplete = YES;
	
#ifdef DEBUG
	NSLog(@"PlugIn Load Complete (%dms) ", (int)(-[date timeIntervalSinceNow] *1000));
#endif
	
}

#define appSupportSubpath @"Application Support/Quicksilver/PlugIns"

- (NSMutableArray *)allBundles {
	NSMutableSet *bundleSearchPaths = [NSMutableSet set];
	NSMutableArray *allBundles = [NSMutableArray array];
	//[allBundles addObject:[[NSBundle mainBundle] bundlePath]];

	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];

	if ((int) getenv("QSDisableExternalPlugIns")) {
		NSLog(@"External PlugIns Disabled");
	} else {
        /* Build our plugin search path */
		NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);

		for (NSString *currPath in librarySearchPaths) {
            [bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];
        }
        
		[bundleSearchPaths addObject:QSApplicationSupportSubPath(@"PlugIns", NO)];
		//[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PrivatePlugIns"]];

		NSArray *paths = [[NSUserDefaults standardUserDefaults] arrayForKey:@"QSAdditionalPlugInPaths"];
		if(paths) {
			paths = [paths valueForKey:@"stringByStandardizingPath"];
			[bundleSearchPaths addObjectsFromArray:paths];
		}

	}
	
	for (NSString *currPath in bundleSearchPaths) {
		NSString *curPlugInPath = nil;
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:nil];
		if (dirContents) {
			for (curPlugInPath in dirContents) {
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
		
#ifdef DEBUG
		if (DEBUG_PLUGINS) NSLog(@"Requirements not met %@:\r%@", plugIn, error);
#endif
		
		return NO;
	}
	return YES;
}

/** Check if a plugin's dependencies have been met
 * Returns NO if a plugin has unmet dependencies, YES otherwise
 * 
 * @note The dependency will be registered in dependingPlugIns, in case the
 * missing plugin ever loads.
 */
- (BOOL)plugInMeetsDependencies:(QSPlugIn *)plugIn; {
	NSArray *unmet = [plugIn unmetDependencies];

	if ([unmet count]) {

		//NSLog(@"unmet? %@", unmet);
		for(NSDictionary * dependency in unmet) {
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

/** Check if a plugin is the most recent one in a list of bundles */
- (BOOL)plugInIsMostRecent:(QSPlugIn *)plugIn inGroup:(NSDictionary *)loadingBundles; {
	//	if (![bundle isKindOfClass:[NSBundle class]]) return NO;
    
	NSString *ident = [plugIn bundleIdentifier];
	QSPlugIn *dupPlugIn = nil;
	//NSString *error;

#warning should detect installation of a disabled plugin
	if (/*dupPlugIn = */[loadedPlugIns objectForKey:ident]) { // check if the bundle is already loaded. if so need to restart.
        //NSLog(@"Bundle already loaded: %@", dupPlugIn);
		return NO;

	} else if ((dupPlugIn = [loadingBundles objectForKey:ident]) && ![plugIn isEqual:dupPlugIn]) {
		//	NSLog(@"Loading Duplicate %@ %@", dupPlugIn, plugIn);
        // If the plugin's already in the list of plugins to delete, don't check it (set below in sorting >=0)
        if ([oldPlugIns containsObject:plugIn]) {
            return NO;
        }
		NSFileManager *manager = [NSFileManager defaultManager];
		NSComparisonResult sorting = [[dupPlugIn buildVersion] versionCompare:[plugIn buildVersion]];
		if (sorting == NSOrderedSame) {
			sorting	 = [[[manager attributesOfItemAtPath:[dupPlugIn bundlePath] error:nil] fileModificationDate]
						compare:[[manager attributesOfItemAtPath:[plugIn bundlePath] error:nil] fileModificationDate]];
		}
		if (sorting >= 0) {
            // Don't delete the plugin if it's in Quicksilver.app
            if ([[plugIn bundlePath] rangeOfString:[[NSBundle mainBundle] bundlePath]].location == NSNotFound) {
			[oldPlugIns addObject:plugIn];
			return NO; // a newer version of this plugin has already been seen
            }
            else {
                NSLog(@"Denying removal of %@ from Application (.app) folder.\nRemoving %@ instead",[plugIn bundlePath], [dupPlugIn bundlePath]);
            }
		}
		[oldPlugIns addObject:dupPlugIn];
	}

	return YES;
}

- (void)suggestOldPlugInRemoval {
	if ([oldPlugIns count]) {
        NSError *error = nil;
        for (QSPlugIn * plugIn in oldPlugIns) {
            NSLog(@"Deleting Old Duplicate Plug-in:\r%@", [plugIn path]);
            if (![[NSFileManager defaultManager] removeItemAtPath:[plugIn path] error:&error])
                NSLog(@"Error deleting old plugin: %@, %@", [plugIn path], error);
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

- (NSMutableDictionary *)obsoletePlugIns
{
	return obsoletePlugIns;
}

- (BOOL)checkForPlugInUpdates {
	return [self checkForPlugInUpdatesForVersion:nil];
}

/** Start a plugin check with a specific application version
 *
 * If plugin updates are available, the user is presented with a dialog,
 * then installation proceeds
 */
- (BOOL)checkForPlugInUpdatesForVersion:(NSString *)version {
	if (!plugInWebData)
		[self loadWebPlugInInfo];

	//NSDictionary *bundleIDs = [QSReg identifierBundles];

	if (!updatedPlugIns) {
		updatedPlugIns = [[NSMutableSet alloc] init];
	} else {
		[updatedPlugIns removeAllObjects];
	}

	[self downloadWebPlugInInfoFromDate:nil forUpdateVersion:version synchronously:YES];

	NSMutableArray *names = [NSMutableArray arrayWithCapacity:1];
	for (QSPlugIn *thisPlugIn in [self knownPlugInsWithWebInfo]) {
		// don't update obsolete plug-ins, but list them when alerting the user
		if ([thisPlugIn isObsolete] && [thisPlugIn isLoaded]) {
			NSString *replacementID = [obsoletePlugIns objectForKey:[thisPlugIn identifier]];
			[updatedPlugIns addObject:replacementID];
			QSPlugIn *replacement = [self plugInWithID:replacementID];
			[names addObject:[NSString stringWithFormat:@"%@ (replaced by %@)", [thisPlugIn name], [replacement name]]];
		} else if ([thisPlugIn needsUpdate]) {
			[updatedPlugIns addObject:[thisPlugIn identifier]];
			[names addObject:[thisPlugIn name]];
		}
	}
	
	if ([updatedPlugIns count]) {
		int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Plug-in Updates are available", nil] ,
												  @"%@", @"Install", @"Cancel", nil, [names componentsJoinedByString:@", "]);
		if (selection == 1) {
			updatingPlugIns = YES;
			[self installPlugInsForIdentifiers:[updatedPlugIns allObjects] version:version];
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
	// if task was successful, returns 0
	int status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:nil];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		return [manager contentsOfDirectoryAtPath:tempDirectory error:nil];
	} else {
		NSRunInformationalAlertPanel(@"Failed to Extract Plugin", @"There was a problem extracting the QSPkg.\nThe file is most likely corrupt.", nil, nil, nil);
		return nil;
	}

}

- (NSArray *)installPlugInFromCompressedFile:(NSString *)path {
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
	[fm createDirectoryAtPath:tempDirectory withIntermediateDirectories:NO attributes:nil error:nil];

	// use ditto to extract QSPkg
	NSArray *extracted = [self extractFilesFromQSPkg:path toPath:tempDirectory];

	NSMutableArray *installedPlugIns = [NSMutableArray array];
	NSString *file = nil;
	for (file in extracted) {
		NSString *outFile = [tempDirectory stringByAppendingPathComponent:file];
		NSString *destination = [self installPlugInFromFile:outFile];
		if (destination) [installedPlugIns addObject:destination];
	}
#ifdef DEBUG	
	NSLog(@"installed %@", installedPlugIns);
#endif
	// remove the temporary file
	[fm removeItemAtPath:tempDirectory error:nil];
	[fm release];
	return installedPlugIns;

}

/**
 Copy specified path to plugins folder and install the plugin.
 @param	path	File system path to the .qsplugin folder to copy then install
 @return 			Path of the installed plugin, or nil if unreadable.
 */
- (NSString *)installPlugInFromFile:(NSString *)path {
  NSString *bundleID, *bundleVersion;
  bundleID = [QSPlugIn bundleIDForPluginAt:path andVersion:&bundleVersion];
  if (!bundleID) {
    NSLog(@"Failed to install plugin %@, no bundle ID", path);
    return nil;
  }
  if (!bundleVersion) {
    NSLog(@"Warning installing plugin %@, no version string found", path);
    bundleVersion = @"0";
  }
	NSString *destinationFolder = psMainPlugInsLocation;
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createDirectoriesForPath:destinationFolder];
	NSString *destinationPath = [destinationFolder stringByAppendingPathComponent:
                               [NSString stringWithFormat:@"%@.%@.qsplugin", bundleID, bundleVersion]];
	if (![destinationPath isEqualToString:path]) {
		if ([manager fileExistsAtPath:destinationPath] && ![manager removeItemAtPath:destinationPath error:nil])
             NSLog(@"failed to remove %@ for installation of %@", destinationPath, path);
	}
	if (![manager moveItemAtPath:path toPath:destinationPath error:nil]) NSLog(@"move failed, %@, %@", path, destinationPath);
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destinationFolder];
	return destinationPath;
}

- (NSMutableSet *)updatedPlugIns { return updatedPlugIns;  }

- (void)updateDownloadCount {
	if (![queuedDownloads count]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSPlugInUpdatesFinished" object:self];
		[self setInstallStatus:nil];
		[[QSTaskController sharedInstance] removeTask:@"QSPlugInInstalling"];

		[self setIsInstalling:NO];
	} else {
		NSString *status = [NSString stringWithFormat:@"Installing %d Plug-in(s)", [queuedDownloads count]];
		//NSString *status = [NSString stringWithFormat:@"Installing %@ (%d of %d) ", [[self currentDownload] name] , [queuedDownloads count] , downloadsCount];
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

	if (![queuedDownloads count]) {
        [manager checkForUnmetDependencies];
        //[self updateDownloadCount];
    }

	if (!liveLoaded && (updatingPlugIns || !warnedOfRelaunch) && ![queuedDownloads count] && !supressRelaunchMessage) {
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
		for(path in fileList) {
			if ([[path pathExtension] caseInsensitiveCompare:@"qspkg"] == NSOrderedSame)
				newPlugIn = [[self installPlugInFromCompressedFile:path] lastObject];
			else if ([[path pathExtension] caseInsensitiveCompare:@"qsplugin"] == NSOrderedSame)
				newPlugIn = [self installPlugInFromFile:path];
			if (newPlugIn)
        [self plugInWasInstalled:newPlugIn];
		}

	}
	return YES;
}

- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs {
	return [self installPlugInsForIdentifiers:bundleIDs version:nil];
}

- (NSString *)urlStringForPlugIn:(NSString *)ident version:(NSString *)version {
    NSString *downloadURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSPluginDownloadURL"];
    if (!downloadURL)
        downloadURL = kPluginDownloadURL;

	if (!version)
        version = [NSApp buildVersion];
	return [NSString stringWithFormat:@"%@?qsversion=%d&id=%@", downloadURL, [version hexIntValue], ident];
}

- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs version:(NSString *)version {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Update: %@", bundleIDs);
#endif
	NSString *ident = nil;
	if (!version) version = [NSApp buildVersion];
	for(ident in bundleIDs) {
		NSString *url = [self urlStringForPlugIn:ident version:version];
		NSLog(@"Downloading %@", url);
		[self performSelectorOnMainThread:@selector(installPlugInWithInfo:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:ident, @"id", url, @"url", nil] waitUntilDone:YES];
	}

	NSString *status = [NSString stringWithFormat:@"Installing %d Plug-in(s) ", [queuedDownloads count]];
	[[QSTaskController sharedInstance] updateTask:@"QSPlugInInstalling" status:status progress:-1];
	[self setInstallStatus:status];
	[self setIsInstalling:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSUpdateControllerStatusChanged" object:self];
	[self performSelectorOnMainThread:@selector(startDownloadQueue) withObject:nil waitUntilDone:YES];
	return YES;
}

- (void)installPlugInWithInfo:(NSDictionary *)info {
    QSURLDownload *download = [QSURLDownload downloadWithURL:[NSURL URLWithString:[info objectForKey:@"url"]] delegate:self];
    [download setUserInfo:[info objectForKey:@"id"]];
	[queuedDownloads addObject:download];
	[self updateDownloadProgressInfo];
}

- (void)startDownloadQueue {
    int queuedCount = [queuedDownloads count];
    int activeCount = [activeDownloads count];
    if (activeCount < MAX_CONCURRENT_DOWNLOADS && queuedCount != 0) {
        NSArray* array = [queuedDownloads objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, (queuedCount < MAX_CONCURRENT_DOWNLOADS ? queuedCount : MAX_CONCURRENT_DOWNLOADS))]];
        for (QSURLDownload *download in array) {
            [activeDownloads addObject:download];
            [download start];
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
	return [NSString stringWithFormat:@"%d remaining", [queuedDownloads count]];
}

- (void)updateDownloadProgressInfo {
	//NSLog(@"count %d %d %f", [queuedDownloads count], downloadsCount, [[queuedDownloads objectAtIndex:0] progress]);
    float progress = 1.0;
    for (QSURLDownload *download in queuedDownloads) {
        progress *= [download progress];
    }
	[self setInstallProgress:progress];
}

- (float) downloadProgress {return [self installProgress];}

- (void)downloadDidUpdate:(QSURLDownload *)download {
	[self updateDownloadProgressInfo];
}

- (void)downloadDidFinish:(QSURLDownload *)download {
	//NSLog(@"path %@", download);
	//NSLog(@"FINISHED %@ %@", download, currentDownload);
	NSString *path = [download destination];
    NSString *plugInPath = nil;
	if (path && (plugInPath = [[self installPlugInFromCompressedFile:path] lastObject])) {
		[self plugInWasInstalled:plugInPath];
    } else {
        NSLog(@"Failed installing plugin at path %@ from url %@", path, [download URL]);
#warning tiennou: Report ! ATM the checkbox will just blink...
        [[self plugInWithID:[download userInfo]] downloadFailed];
    }
    
    [queuedDownloads removeObject:download];
    [activeDownloads removeObject:download];
    [download cancel];
    
	[self startDownloadQueue];
	[self updateDownloadCount];
}

- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
	[[self plugInWithID:[download userInfo]] downloadFailed];
    NSLog(@"Download failed! Error - %@ %@ %@", [download URL], [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
    NSRunInformationalAlertPanel(@"Download Failed", @"Unfortunately something went wrong with the download.\nCheck Console.app for more information", nil, nil, nil);

    [queuedDownloads removeObject:download];
    [activeDownloads removeObject:download];
    [download cancel];
}

- (void)cancelPlugInInstall {
	for (QSURLDownload *download in queuedDownloads)
		[download cancel];
	[queuedDownloads removeAllObjects];
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
