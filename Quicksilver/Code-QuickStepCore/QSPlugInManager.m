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

#define pPlugInInfo QSApplicationSupportSubPath(@"PlugIns.plist", NO)
#define MAX_CONCURRENT_DOWNLOADS 2

@interface QSPlugInManager ()
@property (retain) QSTask *downloadTask;
@property (retain) QSTask *installTask;
@end

@implementation QSPlugInManager

+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:nil] init];
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

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plugInDidLoad:) name:QSPlugInLoadedNotification object:nil];
		showNotifications = YES;
		// force-update plugins now on launch, then schedule to update every 6 hrs using NSBackgroundActivityScheduler
		[self downloadWebPlugInInfoIgnoringDate:nil];
		[self setupPluginUpdateScheduler];
	}
	return self;
}

- (void)setupPluginUpdateScheduler {
	// background scheduler to update the plugins data every ~6 hrs
	NSBackgroundActivityScheduler *scheduler = [[NSBackgroundActivityScheduler alloc] initWithIdentifier:@"com.qsapp.Quicksilver.RefreshPluginsBackgroundTask"];
	scheduler.repeats = YES;
	scheduler.interval = 6*HOURS;
	[scheduler scheduleWithBlock:^(NSBackgroundActivityCompletionHandler  _Nonnull completionHandler) {
		if (!self->plugInWebData) {
			[self loadWebPlugInInfo];
		}
		QSPluginUpdateBlock block = ^(BOOL success) {
			self->lastCheck = [NSDate timeIntervalSinceReferenceDate];
			completionHandler(NSBackgroundActivityResultFinished);
		};
		if ([self->knownPlugIns count] <30) {
			[self downloadWebPlugInInfoIgnoringDate:block];
		} else {
			[self downloadWebPlugInInfo:block];
		}
	}];
}

- (QSPlugIn *)plugInWithBundle:(NSBundle *)bundle {
	QSPlugIn *plugin = [knownPlugIns objectForKey:[bundle bundleIdentifier]];
	if (plugin) {
		[plugin setBundle:bundle];
	} else {
		plugin = [QSPlugIn plugInWithBundle:bundle];
		if (!plugin) {
			NSLog(@"Failed to initialize plugin for bundle %@", bundle);
			return nil;
		}
		[knownPlugIns setObject:plugin forKey:[bundle bundleIdentifier]];
	}
	return plugin;
}

- (QSPlugIn *)plugInWithID:(NSString *)identifier {
	return [knownPlugIns objectForKey:identifier];
}

- (QSPlugIn *)plugInBundleWasInstalled:(NSBundle *)bundle {
    // FIXME tiennou should check if this plugin is already installed?
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
    // Bool to specify whether a plugin's dependencies can all be loaded
    BOOL allDependenciesLoaded = YES;
	for(QSPlugIn * dep in deps) {
		if (![[dep unmetDependencies] count])
			if (![self liveLoadPlugIn:dep]) {
                // Dependency couldn't be loaded
                allDependenciesLoaded = NO;
            }
	}
    if (allDependenciesLoaded) {
        // All the dependencies were correctly installed, so remove the 'Unmet Dependencies' load error
        [plugin setLoadError:nil];
    }
	[dependingPlugIns removeObjectForKey:[plugin identifier]];
	[self checkForObsoletes:plugin];
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
		plugInWebDownloadDate = [dict objectForKey:@"webDownloadDate"];
	}
	if (!plugInWebData)
		plugInWebData = [[NSMutableDictionary alloc] init];
}

- (void)downloadWebPlugInInfo:(QSPluginUpdateBlock)block {
	[self downloadWebPlugInInfoFromDate:plugInWebDownloadDate forUpdateVersion:nil completionHandler:block];
}
- (void)downloadWebPlugInInfoIgnoringDate:(QSPluginUpdateBlock)block {
	[self downloadWebPlugInInfoFromDate:nil forUpdateVersion:nil completionHandler:block];
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
		[query addObject:[NSString stringWithFormat:@"updateVersion=%lu", (long)[version hexIntValue]]];
	} else {
		[query addObject:[NSString stringWithFormat:@"qsversion=%lu", (long)[[NSApp buildVersion] hexIntValue]]];
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

- (void)downloadWebPlugInInfoFromDate:(NSDate *)date forUpdateVersion:(NSString *)version completionHandler:(QSPluginUpdateBlock)block {
	NSString *fetchURLString = [self webInfoURLFromDate:(NSDate *)date forUpdateVersion:(NSString *)version];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fetchURLString]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:5.0];
    [theRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];

	NSLog(@"Fetching plugin data from %@", fetchURLString);

	NSURLSession *session = [NSURLSession sharedSession];
	NSURLSessionDataTask *task = [session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		QSGCDMainAsync(^{
			if (error) {
				self.downloadTask.status = NSLocalizedString(@"Download failed", @"");
				[self.downloadTask stop];
				self.downloadTask = nil;
				
				[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInfoFailedNotification object:self userInfo:nil];
				if (block) {
					block(NO);
				}
				return;
			}
			self.downloadTask.status = NSLocalizedString(@"Updating Plugin info", @"");
			NSError *error = nil;
			NSDictionary *prop = nil;
			prop = [NSPropertyListSerialization propertyListWithData:data
															 options:NSPropertyListImmutable
															  format:NULL
															   error:&error];
			if (!prop) {
				NSLog(@"Could not load new plugins data: %@", error);
			} else {
				NSLog(@"Downloaded info for %ld plugin%@ ", (long)[(NSArray *)[prop objectForKey:@"plugins"] count], ([(NSArray *)[prop objectForKey:@"plugins"] count] > 1 ? @"s" : @""));
				//	NSEnumerator *e = [prop objectEnumerator];
				if ([prop count] && [[prop objectForKey:@"fullIndex"] boolValue])
					[self clearOldWebData];

				[self loadPlugInInfo:[prop objectForKey:@"plugins"]];

				self->plugInWebDownloadDate = [NSDate date];
				[self writeInfo];

				[self willChangeValueForKey:@"knownPlugInsWithWebInfo"];
				[self didChangeValueForKey:@"knownPlugInsWithWebInfo"];
			}
			[self.downloadTask stop];
			self.downloadTask = nil;
			[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInfoLoadedNotification object:nil];
		});
		if (block) {
			block(YES);
		}
	}];
	QSGCDMainAsync(^{
		self.downloadTask = [QSTask taskWithIdentifier:@"PluginUpdateInfo"];
		self.downloadTask.name = NSLocalizedString(@"Updating Plugin Info", @"");
		self.downloadTask.icon = [QSResourceManager imageNamed:@"QSPlugIn"];
		self.downloadTask.cancelBlock = ^{
			[task cancel];
		};
		[self.downloadTask start];
	});
	[task resume];
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
		[self checkForObsoletes:plugin];
	}
}

- (void)loadWebPlugInInfo {
	//	NSLog(@"known %@", knownPlugIns);
	if (!plugInWebData)
		[self loadInfo];

	[self loadPlugInInfo:[plugInWebData allValues]];
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
}

- (NSArray *)knownPlugInsWithWebInfo {
	//NSLog(@"knownPlugIns %@", knownPlugIns);
	//availablePlugIns = [[plugIns allValues] retain];
	return [knownPlugIns allValues];
}

- (void)deletePlugIns:(NSArray *)deletePlugIns fromWindow:(NSWindow *)window {
	NSArray *loaded = [[self loadedPlugIns] allValues];
	BOOL needsRelaunch = nil != [deletePlugIns firstObjectCommonWithArray:loaded];

	QSAlertResponse response;
	if (needsRelaunch) {
		response = [NSAlert runAlertWithTitle:NSLocalizedString(@"Delete plugins?", @"Delete & relaunch alert title")
									  message:NSLocalizedString(@"Would you like to delete the selected plugins? A relaunch will be required", @"Delete & relaunch alert message")
									  buttons:@[
										  NSLocalizedString(@"Delete and Relaunch", @"Delete & relaunch alert default button"),
										  NSLocalizedString(@"Cancel", @"Delete & relaunch alert cancel button")
									  ]
										style:NSAlertStyleWarning];
	} else {
		response = [NSAlert runAlertWithTitle:NSLocalizedString(@"Delete plugins?", @"Delete & relaunch alert title")
									  message:NSLocalizedString(@"Would you like to delete the selected plugins?", @"Delete & relaunch alert message (alternate)")
									  buttons:@[
										  NSLocalizedString(@"Delete", @"Delete & relaunch alert default button (alternate)"),
										  NSLocalizedString(@"Cancel", @"Delete & relaunch alert cancel button")
									  ]
										style:NSAlertStyleWarning];
	}

	if (response == QSAlertResponseOK) {
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
	NSMutableSet *dependingNamesSet = [NSMutableSet set];
	for (NSString *ident in dependingPlugIns) {
		NSArray *plugins = dependingPlugIns[ident];

		if (![plugins count]) continue;

		// ignore dependencies for plug-ins that won't load under the current architecture
		BOOL loadDependencies = NO;
		for (QSPlugIn *plugin in plugins) {
			if ([plugin isSupported]) {
				// if any one of the depending plug-ins is supported, get the prerequisite
				loadDependencies = YES;
				break;
			}
		}
		if (!loadDependencies) continue;

		QSPlugIn *plugin = plugins.lastObject;
		NSArray *dependencies = [plugin dependencies];
		NSDictionary *supportingPlugIn = [dependencies objectWithValue:ident forKey:@"id"];
		if (supportingPlugIn == nil) {
			NSLog(@"invalid dependency for %@ in plugin %@", ident, plugin.identifier);
			continue;
		}

		if (![[localPlugIns allKeys] containsObject:[supportingPlugIn objectForKey:@"id"]]) {
			// supporting plug-in is not yet installed
			[array addObject:supportingPlugIn];
			[dependingNamesSet addObjectsFromArray:[plugins valueForKey:@"name"]];
		}
	}

	//	NSLog(@"installing! %@", array);
	if (![array count]) return;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSAlwaysInstallPrerequisites"]) {
		[self installPlugInsForIdentifiers:[array valueForKey:@"id"] version:nil];
		return;
	}

	NSString *dependingNames = [[dependingNamesSet allObjects] componentsJoinedByString:@", "];
	NSString *unmetPluginNames = [[array valueForKey:@"name"] componentsJoinedByString:@", "];

	NSString *message = [NSString stringWithFormat:NSLocalizedString(@"There are missing dependencies: %@\n\nThe following plugins will not work until those plugins are installed: %@", @"Missing dependencies alert - message (depending plugin names, unmet plugin names)"), dependingNames, unmetPluginNames];
	NSArray *buttons = @[
						 NSLocalizedString(@"Install", @"Missing dependencies alert - button 1"),
						 NSLocalizedString(@"Disable", @"Missing dependencies alert - button 2"),
						 NSLocalizedString(@"Always Install Requirements", @"Missing dependencies alert - button 3")
						 ];

	QSAlertResponse response = [NSAlert runAlertWithTitle:NSLocalizedString(@"Plugin requirements", @"Missing dependencies alert - title")
												  message:message
												  buttons:buttons
													style:NSAlertStyleWarning];
	
	if (response == QSAlertResponseCancel) {
		return;
		
	}
	
	if (response == QSAlertResponseThird) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"QSAlwaysInstallPrerequisites"];
	}
	[self installPlugInsForIdentifiers:[array valueForKey:@"id"] version:nil];
}

- (void)checkForObsoletes:(QSPlugIn *)plugin
{
	// store a list of obsolete plugins and the one that replaces it
	for (NSString *obsoletePlugIn in [plugin obsoletes]) {
		[obsoletePlugIns setObject:[plugin identifier] forKey:obsoletePlugIn];
	}
}

- (void)removeObsoletePlugIns
{
	if (![obsoletePlugIns count]) {
		return;
	}
	for (QSPlugIn *plugin in [[self localPlugIns] allValues]) {
		if ([plugin isObsolete] && [[localPlugIns allKeys] containsObject:[obsoletePlugIns objectForKey:[plugin identifier]]]) {
			// plugin is obsolete AND the one that replaces it is currently installed
			NSLog(@"removing obsolete plugin: %@", [plugin name]);
			[plugin delete];
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
	NSMutableArray *newLocalPlugInBundles = [[NSMutableArray alloc] init];
    [[self allBundles] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [newLocalPlugInBundles addObject:[NSBundle bundleWithPath:obj]];
    }];
    
    [newLocalPlugInBundles removeObject:[NSNull null]];
    NSMutableArray *newLocalPlugIns = [[NSMutableArray alloc] init];
    [newLocalPlugInBundles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [newLocalPlugIns addObject:[QSPlugIn plugInWithBundle:obj]];
    }];
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
	[self removeObsoletePlugIns];
	
	startupLoadComplete = YES;
	
#ifdef DEBUG
	NSLog(@"PlugIn Load Complete (%.0fms) ", (-[date timeIntervalSinceNow] *1000));
#endif
	
}


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
- (BOOL)plugInMeetsRequirements:(QSPlugIn *)plugIn {
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
- (BOOL)plugInMeetsDependencies:(QSPlugIn *)plugIn {
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
		NSArray *unmetNames = [unmet arrayByEnumeratingArrayUsingBlock:^NSString *(NSDictionary *dict) {
			return [dict objectForKey:@"name"];
		}];
		[plugIn setLoadError:[NSString stringWithFormat:@"The following plugins must be enabled for this plugin to work: %@", [unmetNames componentsJoinedByString:@", "]]];
		return NO;
	}
	return YES;
}

/** Check if a plugin is the most recent one in a list of bundles */
- (BOOL)plugInIsMostRecent:(QSPlugIn *)plugIn inGroup:(NSDictionary *)loadingBundles {
	//	if (![bundle isKindOfClass:[NSBundle class]]) return NO;
    
	NSString *ident = [plugIn bundleIdentifier];
	QSPlugIn *dupPlugIn = nil;
	//NSString *error;

    // FIXME tiennou should detect installation of a disabled plugin
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
            NSLog(@"Deleting Old Duplicate Plugin:\r%@", [plugIn path]);
            if (![[NSFileManager defaultManager] removeItemAtPath:[plugIn path] error:&error])
                NSLog(@"Error deleting old plugin: %@, %@", [plugIn path], error);
        }
	}
}

- (NSMutableDictionary *)localPlugIns {
	return localPlugIns;
}
- (void)setLocalPlugIns:(NSMutableDictionary *)newLocalPlugIns {
	localPlugIns = newLocalPlugIns;
}

- (NSMutableDictionary *)knownPlugIns {
	return knownPlugIns;
}
- (void)setKnownPlugIns:(NSMutableDictionary *)newKnownPlugIns {
	knownPlugIns = newKnownPlugIns;
}

- (NSMutableDictionary *)loadedPlugIns {
	return loadedPlugIns;
}
- (void)setLoadedPlugIns:(NSMutableDictionary *)newLoadedPlugIns {
	loadedPlugIns = newLoadedPlugIns;
}

- (NSMutableDictionary *)obsoletePlugIns
{
	return obsoletePlugIns;
}

- (void)checkForPlugInUpdates:(QSPluginUpdatePromptBlock)block {
	[self checkForPlugInUpdatesForVersion:nil completionHandler:block];
}

/** Start a plugin check with a specific application version
 *
 * If plugin updates are available, the user is presented with a dialog,
 * then installation proceeds
 */
- (void)checkForPlugInUpdatesForVersion:(NSString *)version completionHandler:(QSPluginUpdatePromptBlock)block {
	if (!plugInWebData)
		[self loadWebPlugInInfo];

	//NSDictionary *bundleIDs = [QSReg identifierBundles];

	if (!updatedPlugIns) {
		updatedPlugIns = [[NSMutableSet alloc] init];
	} else {
		[updatedPlugIns removeAllObjects];
	}

	[self downloadWebPlugInInfoFromDate:nil forUpdateVersion:version completionHandler:^(BOOL success) {
		QSPluginUpdateStatus status = 0;
		// An array of mutable dictionaries that contain information on the plugin(s) requiring an update
		NSMutableArray *plugins = [NSMutableArray arrayWithCapacity:1];
		// don't update obsolete plugins, but list them when alerting the user
		for (QSPlugIn *thisPlugIn in [[self localPlugIns] allValues]) {
			if ([thisPlugIn isObsolete]) {
				NSString *replacementID = [self->obsoletePlugIns objectForKey:[thisPlugIn identifier]];
				[self->updatedPlugIns addObject:replacementID];
				QSPlugIn *replacement = [self plugInWithID:replacementID];
				[plugins addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@ (replaced by %@)", [thisPlugIn name], [replacement name]],@"name",thisPlugIn,@"plugin",nil]];
			}
		}
		// compare to plugins that are availble for download
		for (QSPlugIn *thisPlugIn in [self knownPlugInsWithWebInfo]) {
			if ([thisPlugIn needsUpdate]) {
				[self->updatedPlugIns addObject:[thisPlugIn identifier]];
				[plugins addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:thisPlugIn,@"plugin",nil]];
			}
		}
		
		if ([self->updatedPlugIns count]) {
			__block NSArray *arr;
			QSGCDMainSync(^{
				QSPluginUpdaterWindowController *c = [[QSPluginUpdaterWindowController alloc] initWithPlugins:plugins];
				arr = [c showModal];
			});
			if (!arr) {
				status = QSPluginUpdateStatusUpdateCancelled;
			} else {
				self->updatingPlugIns = YES;
				[self installPlugInsForIdentifiers:arr version:version];
				status = QSPluginUpdateStatusPluginsUpdated;
			}
			
		} else {
		 status = QSPluginUpdateStatusNoUpdates;
		}
		if (block) {
			block(status);
		}
	}];
}

- (void)updatePlugInsForNewVersion:(NSString *)version completionHandler:(QSPluginUpdatePromptBlock)block {
	supressRelaunchMessage = YES;
	[self checkForPlugInUpdatesForVersion:version completionHandler:block];
}

- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory {
	if (!path) return nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/ditto"];

	[task setArguments:[NSArray arrayWithObjects:@"-x", @"-rsrc", path, tempDirectory, nil]];
	[task launch];
	[task waitUntilExit];
	// if task was successful, returns 0
	NSInteger status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:nil];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		return [manager contentsOfDirectoryAtPath:tempDirectory error:nil];
	} else {
		NSString *pluginName = [path lastPathComponent];
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSAlertStyleInformational;
		alert.messageText = NSLocalizedString(@"Failed to Extract Plugin", @"Plugin extraction failed - title");
		alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"There was a problem extracting the QSPkg %@.\nThe file is most likely corrupt.", @"Plugin extraction failed - message"), pluginName];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		NSLog(@"There was a problem extracting the QSPkg: %@.\nFull Path: %@\nThe file is most likely corrupt.", pluginName, path);

		[alert runAlert];
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
	NSUInteger dlCount = [queuedDownloads count];
	if (!dlCount) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"QSPlugInUpdatesFinished" object:self];
		[self setInstallStatus:nil];
		self.installTask.status = NSLocalizedString(@"Installation complete", @"");
		self.installTask.showProgress = NO;
		[self.installTask stop];

		[self setIsInstalling:NO];
	} else {
		NSString *status = nil;
		if (dlCount > 1) {
			status = [NSString stringWithFormat:NSLocalizedString(@"Installing %ld Plugins", @""), dlCount];
		} else {
			status = NSLocalizedString(@"Installing Plugin", @"");
		}
		[self setInstallStatus:status];
		self.installTask = [QSTask taskWithIdentifier:@"QSPlugInInstallation"];
		self.installTask.name = status;
		self.installTask.icon = [QSResourceManager imageNamed:@"QSPlugIn"];
		if (!self.installTask.isRunning) {
			[self.installTask start];
		}
    }

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
        [self removeObsoletePlugIns];
    }

	if (!liveLoaded && (updatingPlugIns || !warnedOfRelaunch) && ![queuedDownloads count] && !supressRelaunchMessage) {
//	if (YES) {
        BOOL relaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateWithoutAsking"];
        if (!relaunch) {
			NSAlert *alert = [[NSAlert alloc] init];
			alert.alertStyle = NSAlertStyleInformational;
			alert.messageText = NSLocalizedString(@"Install complete", @"QSPlugin manager - Plugin requires relaunch alert - title");
			alert.informativeText = NSLocalizedString(@"Some plugins will not be available until Quicksilver is relaunched.", @"QSPlugin manager - Plugin requires relaunch alert - message");
			[alert addButtonWithTitle:NSLocalizedString(@"Relaunch", @"QSPlugin manager - Plugin requires relaunch alert - default button")];
			[alert addButtonWithTitle:NSLocalizedString(@"Later", @"QSPlugin manager - Plugin requires relaunch alert - cancel button")];

			relaunch = ([alert runAlert] == QSAlertResponseOK);
        }
		if (relaunch) {
			[NSApp relaunch:self];
		}
		updatingPlugIns = NO;
		warnedOfRelaunch = YES;
		return YES;
	}
	NSString *title = [NSString stringWithFormat:@"%@ Installed", (name?name:@"Plugin")];

	NSImage *image = [QSResourceManager imageNamed:@"QSPlugIn"];
	[image setSize:QSSizeMax];

	if (showNotifications) {
		// see if this obsoletes an installed plugin
		BOOL relaunchForObsoletes = NO;
		for (NSString *obsolete in [plugin obsoletes]) {
			if ([[localPlugIns allKeys] containsObject:obsolete]) {
				relaunchForObsoletes = YES;
			}
		}
		// only suggest relaunch if not live loaded, we're removing an obsolete and we're not in the middle of an update
		BOOL suggestRelaunch = (!liveLoaded || relaunchForObsoletes) && ![QSTask taskWithIdentifier:@"QSAppUpdateInstalling"];
		QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"QSPlugInInstalledNotification", QSNotifierType, image, QSNotifierIcon, title, QSNotifierTitle, suggestRelaunch?@"Relaunch required (⌘⌃Q)":nil, QSNotifierText, nil]);
	}
	return YES;
}

- (BOOL)installPlugInsFromFiles:(NSArray *)fileList {
	//NSBeep();

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	BOOL installWithoutAsking = [defaults boolForKey:kClickInstallWithoutAsking];
	BOOL shouldInstall = YES;

	if (!installWithoutAsking) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSAlertStyleInformational;
		alert.messageText = NSLocalizedString(@"Install plugins?", @"QSPlugin manager - Plugin install alert - title");
		alert.informativeText = NSLocalizedString(@"Do you wish to move selected items to Quicksilver's plugin folder?", @"QSPlugin manager - Plugin installed alert - message");
		[alert addButtonWithTitle:NSLocalizedString(@"Install", @"QSPlugin manager - Plugin install alert - default button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"QSPlugin manager - Plugin install alert - cancel button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Always Install", @"QSPlugin manager - Plugin install alert - other button")];

		QSAlertResponse response = [alert runAlert];
		if (response == QSAlertResponseThird) {
			[defaults setBool:YES forKey:kClickInstallWithoutAsking];
			[defaults synchronize];
		}
		if (response == QSAlertResponseCancel) {
			shouldInstall = NO;
		}
	}

	if (shouldInstall) {
		for (NSString *path in fileList) {
			NSString *newPlugIn = nil;
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
	NSDictionary *target = [plugInWebData objectForKey:ident];
	NSUInteger pluginVersion = [[target objectForKey:@"CFBundleVersion"] hexIntValue];
	return [NSString stringWithFormat:@"%@?qsversion=%lu&id=%@&version=%lu", downloadURL, (long)[version hexIntValue], ident, (long)pluginVersion];
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
		[self installPlugInWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:ident, @"id", url, @"url", nil]];
	}
	return YES;
}

- (void)installPlugInWithInfo:(NSDictionary *)info {
    QSURLDownload *download = [QSURLDownload downloadWithURL:[NSURL URLWithString:[info objectForKey:@"url"]] delegate:self];
    [download setUserInfo:[info objectForKey:@"id"]];
	[queuedDownloads addObject:download];
	[self updateDownloadCount];
	[self setIsInstalling:YES];
	[self updateDownloadProgressInfo];
	QSGCDAsync(^{
		[download start];
	});
}

- (void)startDownloadQueue {
    NSInteger queuedCount = [queuedDownloads count];
    NSInteger activeCount = [activeDownloads count];
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

	NSString *idString = [components objectAtIndex:0];
	if ([idString hasPrefix:@"id="])
		idString = [idString substringFromIndex:3];

	NSString *nameString = [components lastObject];
	NSString *name = @"<Unknown Plugin>";
	if ([nameString hasPrefix:@"name="])
		name = [[nameString substringFromIndex:5] URLDecoding];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	BOOL shouldInstall = NO;
	BOOL installWithoutAsking = [defaults boolForKey:kWebInstallWithoutAsking];
	if (!installWithoutAsking) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSAlertStyleInformational;
		alert.messageText = name;
		NSString *message = NSLocalizedString(@"Do you wish to install the %@?", @"");
		message = [NSString stringWithFormat:message, name];
		alert.informativeText = message;
		[alert addButtonWithTitle:NSLocalizedString(@"Install", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Always Install Plugins", @"")];

		QSAlertResponse response = [alert runAlert];
		if (response == QSAlertResponseThird) {
			[defaults setBool:YES forKey:kWebInstallWithoutAsking];
			[defaults synchronize];
		}
		shouldInstall = (response != QSAlertResponseCancel);
	}
	if (shouldInstall) {
		[self installPlugInsForIdentifiers:[idString componentsSeparatedByString:@", "] version:nil];
	}
	return YES;
}

- (NSString *)currentStatus {
	return [NSString stringWithFormat:@"%ld remaining", (long)[queuedDownloads count]];
}

- (void)updateDownloadProgressInfo {
	//NSLog(@"count %d %d %f", [queuedDownloads count], downloadsCount, [[queuedDownloads objectAtIndex:0] progress]);
	
    CGFloat progress = 1.0;
    for (QSURLDownload *download in queuedDownloads) {
		NSLog(@"%f", [download progress]);
        progress *= [download progress];
    }
	QSGCDMainAsync(^{
		[self willChangeValueForKey:@"installProgress"];
		self->installProgress = progress;
		[self didChangeValueForKey:@"installProgress"];
	});
	self.installTask.progress = progress;
}

- (void)downloadDidUpdate:(QSURLDownload *)download {
	[self updateDownloadProgressInfo];
}

- (void)downloadDidFinish:(QSURLDownload *)download {
	QSGCDMainAsync(^{
		//NSLog(@"path %@", download);
		//NSLog(@"FINISHED %@ %@", download, currentDownload);
		[self->queuedDownloads removeObject:download];
		[self->activeDownloads removeObject:download];
		NSString *path = [download destination];
		NSString *plugInPath = nil;
		if (path && (plugInPath = [[self installPlugInFromCompressedFile:path] lastObject])) {
			[self plugInWasInstalled:plugInPath];
		} else {
			NSLog(@"Failed installing plugin at path %@ from url %@", path, [download URL]);
			// FIXME tiennou Report ! ATM the checkbox will just blink...
			[[self plugInWithID:[download userInfo]] downloadFailed];
		}
		[download cancel];
		
		[self startDownloadQueue];
		[self updateDownloadCount];
	});
}

- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
	QSGCDMainAsync(^{
		[[self plugInWithID:[download userInfo]] downloadFailed];
		NSLog(@"Download failed! Error - %@ %@ %@", [download URL], [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
		// -1009 means no internet connection, don't bother the user in this case
		if ([error code] != -1009) {
			QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"Download Failed",QSNotifierTitle,@"Plugin Download Failed",QSNotifierText,[QSResourceManager imageNamed:kQSBundleID],QSNotifierIcon,nil]);
		}
		self.installTask.status = NSLocalizedString(@"Plugin download failed", @"");
		
		[self->queuedDownloads removeObject:download];
		[self->activeDownloads removeObject:download];
		[download cancel];
	});
}

- (void)cancelPlugInInstall {
	QSGCDMainAsync(^{
		for (QSURLDownload *download in self->queuedDownloads)
			[download cancel];
		[self->queuedDownloads removeAllObjects];
		[self updateDownloadCount];
	});
}


- (NSString *)installStatus {
	return installStatus;
}
- (void)setInstallStatus:(NSString *)newInstallStatus {
	if (installStatus != newInstallStatus) {
		QSGCDMainAsync(^{
			[self willChangeValueForKey:@"installStatus"];
			self->installStatus = newInstallStatus;
			[self didChangeValueForKey:@"installStatus"];
		});
	}
}

- (CGFloat) installProgress {
	return installProgress;
}

- (BOOL)isInstalling {
	return isInstalling;
}
- (void)setIsInstalling:(BOOL)flag {
	QSGCDMainAsync(^{
		[self willChangeValueForKey:@"isInstalling"];
		self->isInstalling = flag;
		[self didChangeValueForKey:@"isInstalling"];
	});
}

- (BOOL)showNotifications { return showNotifications;  }
- (void)setShowNotifications: (BOOL)flag {
	QSGCDMainAsync(^{
		[self willChangeValueForKey:@"showNotifications"];
		self->showNotifications = flag;
		[self didChangeValueForKey:@"showNotifications"];
	});
}

@end
