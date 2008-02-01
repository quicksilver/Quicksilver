//
//  BRegistry.m
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import "BRegistry.h"
#import "BPlugin.h"
#import "BExtensionPoint.h"
#import "BExtension.h"
#import "BRequirement.h"
#import "BLog.h"

#import "BElement.h"

@interface BRegistry (BPrivate)
- (NSMutableArray *)pluginSearchPaths;
- (void)validatePluginConnections;
- (NSMutableDictionary *)pluginIDsToPlugins;
- (NSString *)applicationSupportFolder;
@end

@implementation BRegistry

#pragma mark Class Methods

NSTimeInterval ti;
+ (void)initialize {
	ti = [NSDate timeIntervalSinceReferenceDate];
	//BLog(@"init ");
	
	[self setKeys:[NSArray arrayWithObject:@"plugins"] triggerChangeNotificationsForDependentKey:@"extensions"];
	[self setKeys:[NSArray arrayWithObject:@"plugins"] triggerChangeNotificationsForDependentKey:@"elements"];
	[self setKeys:[NSArray arrayWithObject:@"plugins"] triggerChangeNotificationsForDependentKey:@"extensionPoints"];
}

static id sharedInstance = nil;
+ (id)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

+ (void)performSelector:(SEL)selector forExtensionPoint:(NSString *)extensionPointID protocol:(Protocol *)protocol {
    BRegistry *pluginRegistry = [BRegistry sharedInstance];
    NSEnumerator *enumerator = [[pluginRegistry loadedElementsForPointID:extensionPointID] objectEnumerator];
    BElement *each;
    
    while ((each = [enumerator nextObject])) {
		@try {
			[[each elementInstance] performSelector:selector];
		} @catch ( NSException *exception ) {
			BLogErrorWithException(exception,([NSString stringWithFormat:@"exception while processing extension point %@ \n %@", extensionPointID, nil]));
		}
    }
}

#pragma mark -
#pragma mark Lifetime
- (id) init {
	self = [super init];
	if (self != nil) {
		BLogInfo(@"Registry loaded with %d plugin(s) from %@", [[self plugins] count], [self applicationSupportFolder]);
        extensionPointCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)awakeFromNib {
	if (!sharedInstance) sharedInstance = self;	
}

- (void)dealloc {
    [self saveAction:self];
    
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [extensionPointCache release], extensionPointCache = nil;
    
    [super dealloc];
}

#pragma mark Plugin loading

- (NSArray *) pluginPathExtensions {
	return [NSArray arrayWithObject:@"plugin"];
}

- (NSURL *)pluginURLForBundle:(NSBundle *)bundle {
	NSString *path = [bundle pathForResource:@"plugin"
                                      ofType:@"xml"];
	if (!path) return nil;
	return [NSURL fileURLWithPath:path];
}

- (void)registerPluginWithPath:(NSString *)thisPath {
    [self willChangeValueForKey:@"plugins"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSBundle *bundle = [NSBundle bundleWithPath:thisPath];
    
    NSURL *url = [NSURL fileURLWithPath:thisPath];
    if (bundle) url = [self pluginURLForBundle:bundle];
    if (!url) return;
    
    
    BPlugin *plugin = nil; 
    if (bundle) plugin = [self pluginWithID:[bundle bundleIdentifier]];
    if (!plugin) plugin = [self pluginWithURL:url];
// TODO: compare versions    
//    NSString *version = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]; // plain plugins won't check version?
    
    if (plugin) {
        NSDate *modDate = [[fileManager fileAttributesAtPath:[url path] traverseLink:YES] fileModificationDate];
        BOOL isValid = [(NSDate *)[plugin valueForKey:@"registrationDate"] compare: modDate] != NSOrderedAscending;	

        if (isValid) {
            BLogDebug(@"Using cache for %p %@", plugin, [(bundle!=nil ? [bundle bundlePath] : [url absoluteString]) stringByAbbreviatingWithTildeInPath]);
            return;
        }
        
        if ([plugin isLoaded] && ![bundle isEqual:[NSBundle mainBundle]]) {
            BLogInfo(@"Trying to replace loaded plugin %@", plugin);
            NSAlert *alert = [NSAlert alertWithMessageText:@"Plugin already loaded"
                                             defaultButton:@"Relaunch"
                                           alternateButton:@"Later" 
                                               otherButton:nil 
                                 informativeTextWithFormat:@"An earlier version of this plugin is already loaded. You must relaunch to use the new version"];
            int result = [alert runModal];
            
            if (result == 1) [NSApp terminate:nil];
            return;
        }
        
        BLogInfo(@"Replacing %@", plugin);
        
        [[self managedObjectContext] deleteObject:plugin];
        plugin = nil;
    }
    
    plugin = [[BPlugin alloc] initWithPluginURL:url
                                         bundle:bundle
                 insertIntoManagedObjectContext:[self managedObjectContext]];
    
    [plugin registerPlugin];
    
    if (!plugin) {
        BLogError(([NSString stringWithFormat:@"failed to create plugin for path: %@", [bundle bundlePath]]));
    } 
    
    [self didChangeValueForKey:@"plugins"];
}

- (void)releaseCaches {
    [[self extensionPoints] makeObjectsPerformSelector:@selector(releaseCaches)];  
}

- (void)validateExistingPlugins {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Delete missing plugins
    NSArray *existingPlugins = [self plugins];
    BPlugin *thisPlugin;
    NSEnumerator *pluginEnumerator = [existingPlugins objectEnumerator];
    
    while((thisPlugin = [pluginEnumerator nextObject])) {
        NSString *path = [[thisPlugin pluginURL] path];
        if (![fileManager fileExistsAtPath:path]) {
            QSLogDebug(@"Deleting plugin at path %@", path);
			[[self managedObjectContext] deleteObject:thisPlugin];  
        }
    }
}


- (void)scanPlugins {
    if (scannedPlugins) {
		BLogWarn(@"scan plugins can only be run once.");
		return;
    } else {
        scannedPlugins = YES;
    }
	
    [self validateExistingPlugins];
    
	NSMutableSet *foundPluginPaths = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableArray *pluginSearchPaths = [self pluginSearchPaths];
	NSString *eachSearchPath;
	NSString *thisPath;
    
    // Add our default paths to the list
	[foundPluginPaths addObject:[[NSBundle mainBundle] bundlePath]];
	[foundPluginPaths addObject:[[NSBundle bundleForClass:[self class]] bundlePath]];
	
	// Find plugin paths
    while ((eachSearchPath = [pluginSearchPaths lastObject])) {
		[pluginSearchPaths removeLastObject];
		
        NSArray *pathContents = [fileManager directoryContentsAtPath:eachSearchPath];
        pathContents = [pathContents pathsMatchingExtensions:[self pluginPathExtensions]];
		NSEnumerator *directoryEnumerator = [pathContents objectEnumerator];
        
		while ((thisPath = [directoryEnumerator nextObject])) {
            
            thisPath = [eachSearchPath stringByAppendingPathComponent:thisPath];
            [foundPluginPaths addObject:thisPath];
            NSBundle *bundle = [NSBundle bundleWithPath:thisPath];
            if (bundle) [pluginSearchPaths addObject:[bundle builtInPlugInsPath]]; // search within plugin for more
        }
	}
	
	// scan plugin paths
	NSEnumerator *foundPluginPathEnumerator = [foundPluginPaths objectEnumerator];
	while ((thisPath = [foundPluginPathEnumerator nextObject])) {
        [self registerPluginWithPath:thisPath];
	}
	
	// [self validatePluginConnections];
	[self willChangeValueForKey:@"plugins"];
	[self didChangeValueForKey:@"plugins"];
	
	[self saveAction:nil];
	//BLogAssert(pluginIDsToPlugins != nil && extensionPointIDsToExtensionPoints != nil && extensionPointIDsToExtensions != nil, @"failed to load plugins into plugin Registry");
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

#pragma mark -
#pragma mark Accessors
- (NSArray *)objectsForEntityName:(NSString *)name {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:[self managedObjectContext]]];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
    //BLog(error);
	return array;
}

- (id)objectForEntityName:(NSString *)name identifier:(NSString *)identifier{
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:[self managedObjectContext]]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"id = %@", identifier]];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if ([array count] == 1) return [array lastObject];
	return nil;
}

- (NSArray *)extensionPoints {
	return [self objectsForEntityName:@"extensionPoint"];
}

- (NSArray *)extensions {
	return [self objectsForEntityName:@"extension"];
}

- (NSArray *)elements {
	return [self objectsForEntityName:@"element"];
}

- (NSArray *)plugins {
    return [self objectsForEntityName:@"plugin"];
}

- (void)logRegistry {
    // FIXME ?
    //	NSLog(@"Plugins %@", [self plugins]);
    //	NSLog(@"Points %@", [self extensionPoints]);	
    //	NSLog(@"Elements %@", [self elements]);	
}


#pragma mark Registry Lookup
- (BPlugin *)pluginWithID:(NSString *)pluginID {
    return [self objectForEntityName:@"plugin" identifier:pluginID];
}

- (BPlugin *)pluginWithURL:(NSURL *)pluginURL {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"plugin" inManagedObjectContext:[self managedObjectContext]]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"url = %@", [pluginURL absoluteString]]];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if ([array count]) return [array lastObject];
	return nil;
}

- (void)fetchExtensionPoint:(NSString *)extensionPointID {
    BExtensionPoint *point = [self objectForEntityName:@"extensionPoint" identifier:extensionPointID];
    [extensionPointCache setValue:point forKey:extensionPointID];
}

- (BExtensionPoint *)extensionPointWithID:(NSString *)extensionPointID {
    BExtensionPoint *point = [extensionPointCache objectForKey:extensionPointID];
    if (!point) {
        [self performSelectorOnMainThread:@selector(fetchExtensionPoint:) withObject:extensionPointID waitUntilDone:YES];
        point = [extensionPointCache objectForKey:extensionPointID];
    }
    return point;
}

- (NSDictionary *)elementsByIDForPointID:(NSString *)extensionPointID {
    return [[self extensionPointWithID:extensionPointID] elementsByID];
}

- (NSArray *)elementsForPointID:(NSString *)extensionPointID {
    return [[self extensionPointWithID:extensionPointID] elements];
}

- (BElement *)elementForPointID:(NSString *)extensionPointID withID:(NSString *)elementID {
    BExtensionPoint *point = [self extensionPointWithID:extensionPointID];
    BElement *element = [point elementWithID:elementID];
    return element;
}

- (BElement *)instanceForPointID:(NSString *)extensionPointID withID:(NSString *)elementID {
    BElement *element = [self elementForPointID:extensionPointID withID:elementID];
	return [element elementInstance];
}

- (NSArray *)loadedValidOrderedExtensionsFor:(NSString *)extensionPointID protocol:(Protocol *)protocol {
	return [self loadedElementsForPointID:(NSString *)extensionPointID];
}

- (NSArray *)loadedInstancesForPointID:(NSString *)extensionPointID {
	return [[self loadedElementsForPointID:extensionPointID] valueForKey:@"elementInstance"];
}

- (NSArray *)loadedElementsForPointID:(NSString *)extensionPointID {
	return [[self extensionPointWithID:extensionPointID] loadedElements];
}

- (NSArray *)loadedElementsByIDForPointID:(NSString *)extensionPointID{
    NSArray *elements = [self loadedElementsForPointID:extensionPointID];
    
	return [NSDictionary dictionaryWithObjects:elements forKeys:[elements valueForKey:@"id"]];
}

- (NSDictionary *)loadedInstancesByIDForPointID:(NSString *)extensionPointID {
	NSArray *elements = [self loadedElementsForPointID:extensionPointID];
	NSArray *instances = [elements valueForKey:@"elementInstance"];
    
	return [NSDictionary dictionaryWithObjects:instances forKeys:[elements valueForKey:@"id"]];
}

- (NSArray *)nameSortDescriptors {
	return [NSArray arrayWithObjects:
            [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease],
            [[[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES] autorelease],
            nil];
}

#pragma mark -
#pragma mark Private
- (NSMutableArray *)pluginSearchPaths {
    NSMutableArray *pluginSearchPaths = [NSMutableArray array];
    NSString *applicationSupportSubpath = [NSString stringWithFormat:@"Application Support/%@/PlugIns", [[NSProcessInfo processInfo] processName]];
    NSEnumerator *searchPathEnumerator = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES) objectEnumerator];
    NSString *eachSearchPath;
    
    while((eachSearchPath = [searchPathEnumerator nextObject])) {
		[pluginSearchPaths addObject:[eachSearchPath stringByAppendingPathComponent:applicationSupportSubpath]];
    }
    
	NSEnumerator *bundleEnumerator = [[NSBundle allBundles] objectEnumerator];
	NSBundle *eachBundle;
	
	while ((eachBundle = [bundleEnumerator nextObject])) {
		[pluginSearchPaths addObject:[eachBundle builtInPlugInsPath]];
	}
    
    return pluginSearchPaths;
}

- (void)validatePluginConnections {
    NSEnumerator *pluginEnumerator = [[self plugins] objectEnumerator];
    BPlugin *eachPlugin;
    
    while ((eachPlugin = [pluginEnumerator nextObject])) {
		NSEnumerator *requirementsEnumerator = [[eachPlugin requirements] objectEnumerator];
		BRequirement *eachRequirement;
		
		while ((eachRequirement = [requirementsEnumerator nextObject])) {
			if (![[eachRequirement valueForKey:@"optional"]boolValue]) {
				if (![NSBundle bundleWithIdentifier:[eachRequirement valueForKey:@"bundle"]]) {
					BLogWarn(([NSString stringWithFormat:@"requirement bundle %@ not found for plugin %@", eachRequirement, eachPlugin]));
				}
			}
		}
    }
    
    NSEnumerator *extensionsEnumerator = [[self extensions] objectEnumerator];
    BExtension *eachExtension;
    
    while ((eachExtension = [extensionsEnumerator nextObject])) {
		NSString *eachExtensionID = [eachExtension extensionPointID];
		BExtensionPoint *extensionPoint = [self extensionPointWithID:eachExtensionID];
		if (!extensionPoint) {
			BLogWarn(([NSString stringWithFormat:@"no extension point found for plugin %@'s extension %@", [eachExtension plugin], eachExtension]));
		}
    }
}

#pragma mark -
#pragma mark Core Data

/**
 *  Returns the support folder for the application, used to store the Core Data
 *  store file.  This code uses a folder named "coredata" for
 *  the content, either in the NSApplicationSupportDirectory location or (if the
 *  former cannot be found), the system's temporary directory.
 */
- (NSString *)applicationSupportFolder {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:[[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension]];
}

/*
 *  Creates, retains, and returns the managed object model for the application 
 *  by merging all of the models found in the application bundle and all of the 
 *  framework bundles.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    NSMutableSet *allBundles = [[NSMutableSet alloc] init];
    [allBundles addObject: [NSBundle mainBundle]];
    [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}


/**
 *  Returns the persistent store coordinator for the application.  This 
 *  implementation will create and return a coordinator, having added the 
 *  store for the application to it.  (The folder for the store is created, 
 *  if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    NSString *path = [applicationSupportFolder stringByAppendingPathComponent: @"registry.cache"];
    url = [NSURL fileURLWithPath: path];
    
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        // If an error occurs, try to destroy the store.
        NSLog(@"Removing store: %@", error);
        [fileManager removeFileAtPath:path handler:nil];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
            [[NSApplication sharedApplication] presentError:error];
        }
    }    
	
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
 *  Returns the NSUndoManager for the application.  In this case, the manager
 *  returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id)sender {
	
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        BLogError(@"Error %@", error);
        //[[NSApplication sharedApplication] presentError:error];
    }
}


/**
 *  Implementation of the applicationShouldTerminate: method, used here to
 *  handle the saving of changes in the application managed object context
 *  before the application terminates.
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.
				
                // Typically, this process should be altered to include application-specific 
                // recovery steps.  
				
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 
				
                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}


- (IBAction) clearAllCaches:(id)sender {
    
    NSLog(@"clearall");
    [extensionPointCache removeAllObjects];
}

- (IBAction) clearOldCaches:(id)sender {
    [[extensionPointCache allValues] makeObjectsPerformSelector:@selector(clearOldCaches:)];
}

@end