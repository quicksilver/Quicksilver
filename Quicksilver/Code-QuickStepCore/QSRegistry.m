#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "QSLibrarian.h"

#import "QSExecutor.h"
#import "QSMacros.h"

#import "QSNotifications.h"

#import <QSFoundation/QSFoundation.h>

#import "NSException_TraceExtensions.h"

id QSReg = nil;

@implementation QSRegistry

+ (NSBundle *)bundleWithIdentifier:(NSString *)identifier {
	NSBundle *bundle = [[self sharedInstance] bundleWithIdentifier:identifier];
	if (!bundle)
		bundle = [NSBundle bundleWithIdentifier:identifier];
	return bundle;
}

+ (void)initialize {
	[self sharedInstance];
}

+ (id)sharedInstance {
	if (!QSReg) QSReg = [[[self class] allocWithZone:[self zone]] init];
	//NSLog(@"lib instance:%@", _sharedInstance);
	return QSReg;
}

- (id)init {
	if (self = [super init]) {
		//stringclassRegistry = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		classRegistry = [[NSMutableDictionary alloc] init];
		tableInstances = [[NSMutableDictionary alloc] init];
		classInstances = [[NSMutableDictionary alloc] init];
		classBundles = [[NSMutableDictionary alloc] init];
		identifierBundles = [[NSMutableDictionary alloc] init];
		prefInstances = [[NSMutableDictionary alloc] init];

		infoRegistry = [[NSMutableDictionary alloc] init];

		[self objectSources];
		[self objectHandlers];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:) name:NSBundleDidLoadNotification object:nil];

		//	[self retainedTableNamed:kQSFSParsers];
	}
	return self;
}
/*
 - (BOOL)registerModule: {
	 if (self = [super init]) {
		 classRegistry = [[NSMutableDictionary dictionaryWithCapacity:1] retain]
	 }
	 return self;
 } */

- (NSMutableDictionary *)tableNamed:(NSString *)key {
	NSMutableDictionary *table = [classRegistry objectForKey:key];
	if (!table) {
		table = [NSMutableDictionary dictionaryWithCapacity:1];
		[classRegistry setObject:table forKey:key];
	}
	return table;
}

- (NSMutableDictionary *)instancesForTable:(NSString *)key {
	NSDictionary *sourceTable = [self tableNamed:key];
	NSMutableDictionary *instances = [NSMutableDictionary dictionaryWithCapacity:[sourceTable count]];
	NSString *entry;
	NSEnumerator *e = [sourceTable keyEnumerator];
	id instance;
	while(entry = [e nextObject]) {
		if (instance = [self getClassInstance:[sourceTable objectForKey:entry]])
			[instances setObject:instance forKey:entry];
	}
	return instances;
}

- (NSMutableDictionary *)retainedTableNamed:(NSString *)key {
	NSMutableDictionary *table = [tableInstances objectForKey:key];
	if (!table) {
		table = [NSMutableDictionary dictionaryWithCapacity:1];

		[tableInstances setObject:table forKey:key];

		//	NSLog(@"regist %@", [classRegistry objectForKey:key]);
	}

	return table;
}

- (void)retainItemsInTable:(NSString *)table {
	NSDictionary *sourceTable = [self tableNamed:table];
	NSMutableDictionary *retainedItems = [self retainedTableNamed:table];

	NSString *entry;
	NSEnumerator *e = [sourceTable keyEnumerator];
	id instance;
	while(entry = [e nextObject]) {
		if (instance = [self getClassInstance:[sourceTable objectForKey:entry]])
			[retainedItems setObject:instance forKey:entry];
	}
}
- (NSBundle *)bundleForClassName:(NSString *)className {
	return [classBundles objectForKey:className];
}

- (void)registerBundle:(NSBundle *)bundle {
	[identifierBundles setObject:bundle forKey:[bundle bundleIdentifier]];
}

- (NSBundle *)bundleWithIdentifier:(NSString *)ident {
	//	NSLog(@"%@", identifierBundles);
	return [identifierBundles objectForKey:ident];
}

- (Class) getClass:(NSString*)className {
	Class providerClass = NSClassFromString(className);
	if (!providerClass) {
		NSBundle *bundle = [classBundles objectForKey:className];
		if (bundle) {
			[bundle load];
			providerClass = NSClassFromString(className);
			return providerClass;
		} else {
			NSLog(@"Could not find bundle for class: %@", className);
		}
	}
	return providerClass;
}

- (id)getClassInstance:(NSString *)className {

	if (!className) {
		NSLog(@"Null class requested");
		return nil;
	}
	id instance;
	if (instance = [classInstances objectForKey:className]) return instance;

	Class providerClass = NSClassFromString(className);
	//NSLog(@"Class <%@>", NSStringFromClass(providerClass) );
	if (!providerClass) {

		[[classBundles objectForKey:className] load]; //performSelectorOnMainThread:@selector(load) withObject:nil waitUntilDone:YES];

		providerClass = NSClassFromString(className);
	}
	if (providerClass) {
		if ([providerClass respondsToSelector:@selector(sharedInstance)])

			instance = [providerClass sharedInstance];
		else
			instance = [[[providerClass alloc] init] autorelease];
		[classInstances setObject:instance forKey:className];
		//NSLog(@"get instance %@", instance);
		return instance;
	} else {
		if (VERBOSE) NSLog(@"Can't find class %@ %@", className, [classBundles objectForKey:className]);
	}
	return nil;
}

- (NSMutableDictionary *)identifierBundles { return identifierBundles;  }

+ (void)setObject:(id)object forKey:(NSString *)inTable:(NSString *)table {[[self sharedInstance] setObject:(id)object forKey:(NSString *)inTable:(NSString *)table];} ;
- (void)setObject:(id)object forKey:(NSString *)key inTable:(NSString *)table {
	[[self tableNamed:table] setObject:object forKey:key];
}
- (id)valueForKey:(NSString *)key inTable:(NSString *)table {
	if (key == nil) return nil;
	NSDictionary *nameTable = [self tableNamed:table];
	return [nameTable objectForKey:key];
}

- (id)instanceForKey:(NSString *)key inTable:(NSString *)table {
	if (key == nil) return nil;
	NSDictionary *nameTable = [self tableNamed:table];
	id entry = [nameTable objectForKey:key];
	if ([entry isKindOfClass:[NSDictionary class]])
		entry = [entry objectForKey:@"class"];
	if (!entry) {
		//if (VERBOSE) NSLog(@"Can't get instance of \"%@\" in \"%@\"", key, table);

	} else {
		return [self getClassInstance:entry];
	}
	return nil;
}

+ (void)registerClassName:(NSString *)className inTable:(NSString *)table {[[self sharedInstance] registerClassName:(NSString *)className inTable:(NSString *)table];} ;
- (void)registerClassName:(NSString *)className inTable:(NSString *)table {
	[[self tableNamed:table] setObject:className forKey:className];
}

+ (void)registerHandler:(id)handler forType:(NSString *)type {[[self sharedInstance] registerHandler:(id)handler forType:(NSString *)type];} ;
- (void)registerHandler:(id)handler forType:(NSString *)type {
	NSMutableDictionary *typeHandlers = [self tableNamed:kQSObjectHandlers];
	if (!type) return;

	[[self retainedTableNamed:kQSObjectHandlers] setObject:[self getClassInstance:handler] forKey:type];
	if (handler)
		[typeHandlers setObject:handler forKey:type];
	else
		[typeHandlers removeObjectForKey:type];
}

- (void)printRegistry:(id)sender {
	NSLog(@"classRegistry:\r%@", classRegistry);
	NSLog(@"bundles:\r%@", classBundles);
}

- (id)preferredInstanceOfTable:(NSString *)table {
	return [prefInstances objectForKey:table];
}
- (void)removePreferredInstanceOfTable:table {

	id object = [prefInstances objectForKey:table];
	NSString *className = NSStringFromClass([object class]);
	if (className)
	[classInstances removeObjectForKey:className];
	//NSLog(@"class %@", [classInstances allKeys]);
	if (table)
		[prefInstances removeObjectForKey:table];
}
@end

@implementation NSBundle (QSRegistryAdditions)
- (NSDictionary *)qsRequirementsDictionary {
	NSString *path = [[self bundlePath] stringByAppendingPathComponent:@"Contents/QSRequirements.plist"];
	return [[NSFileManager defaultManager] fileExistsAtPath:path] ?
		[NSDictionary dictionaryWithContentsOfFile:path] :[self objectForInfoDictionaryKey:@"QSRequirements"];
}
- (NSDictionary *)qsPlugInDictionary {
	NSString *path = [[self bundlePath] stringByAppendingPathComponent:@"Contents/QSPlugIn.plist"];
	return [[NSFileManager defaultManager] fileExistsAtPath:path] ?
		[NSDictionary dictionaryWithContentsOfFile:path] :[self objectForInfoDictionaryKey:@"QSPlugIn"];
}
- (NSDictionary *)qsRegistrationDictionary {
	NSString *path = [[self bundlePath] stringByAppendingPathComponent:@"Contents/QSRegistration.plist"];
	return [[NSFileManager defaultManager] fileExistsAtPath:path] ?
		[NSDictionary dictionaryWithContentsOfFile:path] :[self objectForInfoDictionaryKey:@"QSRegistration"];
}
- (NSDictionary *)qsActionsDictionary {return[self dictionaryForFileOrPlistKey:@"QSActions"];}

- (NSDictionary *)dictionaryForFileOrPlistKey:(NSString *)key {
	NSString *path = [[self bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Contents/%@.plist", key]];
	return [[NSFileManager defaultManager] fileExistsAtPath:path] ?
		[NSDictionary dictionaryWithContentsOfFile:path] :[self objectForInfoDictionaryKey:key];
}

- (NSDictionary *)qsPresetAdditionsDictionary {
	NSString *path = [[self bundlePath] stringByAppendingPathComponent:@"Contents/QSPresetAdditions.plist"];
	return [[NSFileManager defaultManager] fileExistsAtPath:path] ?
		[NSDictionary dictionaryWithContentsOfFile:path] :[self objectForInfoDictionaryKey:@"QSPresetAdditions"];
}
@end

@implementation QSRegistry (PlugIns)

- (void)bundleDidLoad:(NSNotification *)aNotif {
	if (DEBUG_PLUGINS)
	NSLog(@"Loaded Bundle: %@ Classes: %@", [[[aNotif object] bundlePath] lastPathComponent] , [[[aNotif userInfo] objectForKey:@"NSLoadedClasses"] componentsJoinedByString:@", "]);
}

- (BOOL)handleRegistration:(NSBundle *)bundle {
	NSDictionary *registration = [bundle dictionaryForFileOrPlistKey:@"QSRegistration"];
//NSLog(@"register %@", bundle);
	if (!registration) return NO;
	//if (![registration isKindOfClass:[NSDictionary class]]) [NSException exceptionWithName:@"Invalid registration" reason: @"Registration is not a dictionary" userInfo:nil];
	//	[bundle load];
	NSEnumerator *keynum = [registration keyEnumerator];
	NSString *table;

	while (table = [keynum nextObject]) {

		NSDictionary *providers = [registration objectForKey:table];
		if (![providers isKindOfClass:[NSDictionary class]]) [NSException raise:@"Invalid registration" format:@"%@ invalid", table];

		[[self tableNamed:table] addEntriesFromDictionary:providers];

		NSString *provider;
		NSEnumerator *e = [providers keyEnumerator];

		NSMutableDictionary *retainedInstances = [tableInstances objectForKey:table];

		while(provider = [e nextObject]) {
			id entry = [providers objectForKey:provider];

			NSString *className = entry;
			if ([entry isKindOfClass:[NSDictionary class]])
				className = [entry objectForKey:@"class"];
			if (className)
				[classBundles setObject:bundle forKey:className];
			if (retainedInstances) {
				id instance = [self getClassInstance:className];
				if (instance)
					[[self retainedTableNamed:table] setObject:instance forKey:provider];
			}
		}

	}
	return YES;
}

- (void)bundleInstalled:(NSBundle *)bundle {
	if (![identifierBundles objectForKey:[bundle bundleIdentifier]])
		[identifierBundles setObject:bundle forKey:[bundle bundleIdentifier]];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInstalledNotification object:bundle];

}

- (void)instantiatePlugIns {

}
//- (void)registerPlugIns {
//	NSMutableDictionary *validBundles = [NSMutableDictionary dictionary];
//	NSEnumerator *enumerator;
//	//	NSString *currPath;
//	NSBundle *curBundle; //, *dupBundle;
//						 //	id currInstance;
//	NSDate *date = [NSDate date];
//
//	NSMutableArray *allBundles = [NSBundle performSelector:@selector(bundleWithPath:) onObjectsInArray:[self allBundles]];
//
//	[allBundles removeObject:[NSNull null]];
//
//	NSDictionary *newBundlesIDs = [NSDictionary dictionaryWithObjects:allBundles
//															forKeys:[allBundles valueForKey:@"bundleIdentifier"]];
//
//#warning a bundle without an identifier may cause a problem here
//
//	[identifierBundles addEntriesFromDictionary:newBundlesIDs];
//
//	enumerator = [allBundles objectEnumerator];
//	while(curBundle = [enumerator nextObject]) {
//		//if (curBundle = [NSBundle bundleWithPath:currPath]) {
//		//NSLog(@"bund %@", curBundle);
//		if ([self shouldLoadPlugIn:curBundle inLoadGroup:validBundles] && [curBundle bundleIdentifier]) {
//			[validBundles setObject:curBundle forKey:[curBundle bundleIdentifier]];
//			[identifierBundles setObject:curBundle forKey:[curBundle bundleIdentifier]];
//		}
//		//}
//	}
//	//if (VERBOSE) NSLog(@"Loading Plugins:\r%@", [[validBundles valueForKey:@"bundlePath"] componentsJoinedByString:@"\r"]);
//
//
//
//	NSArray *disabledBundles = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSDisabledPlugIns"];
//
//	[validBundles removeObjectsForKeys:disabledBundles];
//	enumerator = [[validBundles allValues] objectEnumerator];
//
//
//	while(curBundle = [enumerator nextObject]) {
//		NS_DURING
//			[self loadPlugIn:curBundle];
//		NS_HANDLER
//			NSString *errorMessage = [NSString stringWithFormat:@"An error ocurred while loading plug-in \"%@\": %@", curBundle, localException];
//			if (VERBOSE) {
//				NSLog(errorMessage);
//				[localException printStackTrace];
//			}
//			NS_ENDHANDLER
//	}
//
//	//	NSLog(@"errors %@", loadErrors);
//	[self suggestOldPlugInRemoval];
//	if (DEBUG_STARTUP) NSLog(@"PlugIn Load Complete (%dms) ", (int)(-[date timeIntervalSinceNow] *1000));
//	initialLoadComplete = YES;
//}
#if 0
- (NSDictionary *)restrictionsDict {
	static NSDictionary *restrictions = nil;
	if (!restrictions) {
		restrictions = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PlugInVersionRequirements" ofType:@"plist"]];
	}
	return restrictions;
}
#endif

#define appSupportSubpath @"Application Support/Quicksilver/PlugIns"

- (NSMutableArray *)allBundles {

	NSEnumerator *searchPathEnum;
	NSString *currPath;
	NSMutableSet *bundleSearchPaths = [NSMutableSet set];
	NSMutableArray *allBundles = [NSMutableArray array];
	[allBundles addObject:[[NSBundle mainBundle] bundlePath]];

	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];

	if ((int) getenv("QSDisableExternalPlugIns")) {
		NSLog(@"External PlugIns Disabled");
	} else {
		NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
		searchPathEnum = [librarySearchPaths objectEnumerator];
		while(currPath = [searchPathEnum nextObject])
			[bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];
		[bundleSearchPaths addObject:[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]];
		[bundleSearchPaths addObject:[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"PlugIns"]];
		[bundleSearchPaths addObject:[[NSFileManager defaultManager] currentDirectoryPath]];
		[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PlugIns"]];
		//[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PrivatePlugIns"]];

		NSArray *paths = [[NSUserDefaults standardUserDefaults] arrayForKey:@"QSAdditionalPlugInPaths"];
		paths = [paths valueForKey:@"stringByStandardizingPath"];
		[bundleSearchPaths addObjectsFromArray:paths];

		[bundleSearchPaths addObject:[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"PrivatePlugIns"]];
	}

	searchPathEnum = [bundleSearchPaths objectEnumerator];
	while(currPath = [searchPathEnum nextObject]) {
		NSEnumerator *bundleEnum;
		NSString *curBundlePath;
		bundleEnum = [[[NSFileManager defaultManager] directoryContentsAtPath:currPath] objectEnumerator];
		if (bundleEnum) {
			while(curBundlePath = [bundleEnum nextObject]) {
				if ([[curBundlePath pathExtension] caseInsensitiveCompare:@"qsplugin"] == NSOrderedSame) {
					[allBundles addObject:[currPath stringByAppendingPathComponent:curBundlePath]];
				}
			}
		}
	}

	return allBundles;
}

@end

@implementation QSRegistry (ObjectSource)

- (NSMutableDictionary *)objectSources {
	return [self instancesForTable:kQSObjectSources];
}
/*
 + (void)registerSource:(id)source {[[self sharedInstance] registerSource:(id)source];} ;
 - (void)registerSource:(id)source {

	 [[self retainedTableNamed:kQSObjectSources] setObject:[self getClassInstance:source] forKey:source];
	 [[self tableNamed:] setObject:source forKey:source];
 }
 */
+ (id)sourceNamed:(NSString *)name {return[[self sharedInstance] sourceNamed:(NSString *)name];} ;
- (id)sourceNamed:(NSString *)name {
	return [self instanceForKey:name inTable:kQSObjectSources];
}

@end

@implementation QSRegistry (ObjectHandlers)

+ (NSMutableDictionary *)objectHandlers {return[[self sharedInstance] objectHandlers];}
- (NSMutableDictionary *)objectHandlers {
	return [self retainedTableNamed:kQSObjectHandlers];
}
@end

@implementation NSObject (InstancePerform)

+ (id)performSelectorWithInstance:(SEL)selector {
	return [[QSReg getClassInstance:NSStringFromClass([self class])] performSelector:selector];
}
@end

@implementation QSRegistry (Mediators)
- (id)getMediator:(NSString *)name {
	NSDictionary *header = [[self tableNamed:@"QSRegistryHeaders"] objectForKey:name];
	NSString *selector = [header objectForKey:@"selector"];
	NSBundle *bundle = [NSBundle bundleWithIdentifier:[header objectForKey:@"bundle"]];
	if (bundle && ![bundle isLoaded]) [bundle load];
	SEL sel = NSSelectorFromString(selector);
	if (sel)
	return [self performSelector:sel withObject:name];
	else
		return nil;
}
- (id)getMediatorID:(NSString *)name {
	NSDictionary *header = [[self tableNamed:@"QSRegistryHeaders"] objectForKey:name];
	NSString *selector = [header objectForKey:@"registryPreferredSelector"];
	NSBundle *bundle = [NSBundle bundleWithIdentifier:[header objectForKey:@"bundle"]];
	if (bundle && ![bundle isLoaded]) [bundle load];
	SEL sel = NSSelectorFromString(selector);
	if (sel)
		return [self performSelector:sel withObject:name];
	else
		return nil;
}
@end

