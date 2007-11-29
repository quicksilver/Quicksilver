//
//  QSRegistry+Convenience.m
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import "QSRegistry+Convenience.h"

//
@implementation QSRegistry (Convenience)
//
+ (NSBundle *)bundleWithIdentifier:(NSString *)identifier{
	NSBundle *bundle=[[self sharedInstance]bundleWithIdentifier:identifier];
	if (!bundle)
		bundle=[NSBundle bundleWithIdentifier:identifier];
	return bundle;
}
//
//
////- (id)init {
////    if (self=[super init]) {
////        //stringclassRegistry=[[NSMutableDictionary dictionaryWithCapacity:1]retain];
////        classRegistry=[[NSMutableDictionary alloc]init];
////		tableInstances=[[NSMutableDictionary alloc]init]; 
////		classInstances=[[NSMutableDictionary alloc]init];
////		classBundles=[[NSMutableDictionary alloc]init];
////		identifierBundles=[[NSMutableDictionary alloc]init];
////		prefInstances=[[NSMutableDictionary alloc]init];
////		
////		
////		
////		infoRegistry=[[NSMutableDictionary alloc]init];
////		
////		[self objectSources];
////		[self objectHandlers];
////		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoad:) name:NSBundleDidLoadNotification object:nil];
////		
////		//	[self retainedTableNamed:kQSFSParsers];
////    }
////    return self;
////}
///*
// - (BOOL)registerModule:{
//	 if (self=[super init]) {
//		 classRegistry=[[NSMutableDictionary dictionaryWithCapacity:1]retain]
//	 }
//	 return self;
// }*/
//
- (NSMutableDictionary *)tableNamed:(NSString *)key{
    Debugger();
  //[self loadedInstancesByIDForPointID
//    NSMutableDictionary *table=[classRegistry objectForKey:key];
//    if (!table){
//        table=[NSMutableDictionary dictionaryWithCapacity:1];
//        [classRegistry setObject:table forKey:key];
//    }
//    return table;
}
//
- (NSMutableDictionary *)instancesForTable:(NSString *)key{
  return [self loadedInstancesForPointID:key];
}
//
- (NSMutableDictionary *)retainedTableNamed:(NSString *)key{
  Debugger();
 //   NSMutableDictionary *table=[tableInstances objectForKey:key];
//    if (!table){
//        table=[NSMutableDictionary dictionaryWithCapacity:1];
//        
//		[tableInstances setObject:table forKey:key];
//		
//		//	BLog(@"regist %@",[classRegistry objectForKey:key]);
//    }
//	
//    return table;
}
//
//- (void)retainItemsInTable:(NSString *)table{
//	NSDictionary *sourceTable=[self tableNamed:table];
//	NSMutableDictionary *retainedItems=[self retainedTableNamed:table];
//	
//	NSString *entry;
//	NSEnumerator *e=[sourceTable keyEnumerator];
//	id instance;
//	while(entry=[e nextObject]){
//		if (instance=[self getClassInstance:[sourceTable objectForKey:entry]])
//			[retainedItems setObject:instance forKey:entry];
//	}
//}
- (NSBundle *)bundleForClassName:(NSString *)className{
	BLog(@"bundle requested for class %@", className);
	return nil;
//	return [classBundles objectForKey:className];
}
//
//- (void)registerBundle:(NSBundle *)bundle{
//	[identifierBundles setObject:bundle forKey:[bundle bundleIdentifier]];	
//}
//
- (NSBundle *)bundleWithIdentifier:(NSString *)ident{
	return [[self pluginWithID:ident] bundle];
}



- (BElement *)elementForClassName:(NSString *)className {
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"element" inManagedObjectContext:[self managedObjectContext]]];
  [request setPredicate:[NSPredicate predicateWithFormat:@"objcClass = %@", className]];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
  //BLog(error);
	return [array lastObject];
}

- (Class)getClass:(NSString*)className{
	BLog(@" requested class %@", className);
	return Nil;
//	Class providerClass=NSClassFromString(className);
//	if (!providerClass){
//		NSBundle *bundle=[classBundles objectForKey:className];
//		if (bundle){
//			[bundle load];
//			providerClass=NSClassFromString(className);
//			return providerClass;
//		}else{
//			BLog(@"Could not find bundle for class: %@",className);	
//		}
//	}	
//	return providerClass;
}
//
- (id)getClassInstance:(NSString *)className{
  
  BElement *classElement = [self elementForClassName:className];
  BLogError(@"[QSReg getClassInstance:] is deprecated. (%@ %@)", className, classElement);
  return [classElement elementInstance];
  //Debugger();
  //	if (!className){
  //		BLog(@"Null class requested");	
  //		return nil;
  //	}
  //	id instance;
  //	if (instance=[classInstances objectForKey:className])return instance;
  //
  //	Class providerClass=NSClassFromString(className);
  //	if (!providerClass){
  //		[[classBundles objectForKey:className]load]; //performSelectorOnMainThread:@selector(load) withObject:nil waitUntilDone:YES];
  //		providerClass=NSClassFromString(className);
  //	}
  //	if (providerClass){
  //		if ([providerClass respondsToSelector:@selector(sharedInstance)])
  //			
  //			instance=[providerClass sharedInstance];
  //		else
  //			instance=[[[providerClass alloc]init]autorelease];
  //		[classInstances setObject:instance forKey:className];
  //		//BLog(@"get instance %@",instance);
  //		return instance;
  //	}else{
  //		if (VERBOSE)BLog(@"Can't find class %@ %@", className,[classBundles objectForKey:className]);	
  //	}
  //	return nil;
}
//
//
//- (NSMutableDictionary *)identifierBundles { return [[identifierBundles retain] autorelease]; }
//
//
//+ (void)setObject:(id)object forKey:(NSString *) inTable:(NSString *)table{[[self sharedInstance]setObject:(id)object forKey:(NSString *) inTable:(NSString *)table];};
//- (void)setObject:(id)object forKey:(NSString *)key inTable:(NSString *)table{
//    [[self tableNamed:table] setObject:object forKey:key];
//}
//- (id)valueForKey:(NSString *)key inTable:(NSString *)table{
//	if (key==nil)return nil;
//	NSDictionary *nameTable=[self tableNamed:table];
//	return [nameTable objectForKey:key];	
//}
//
- (id)instanceForKey:(NSString *)key inTable:(NSString *)table{
	return [self instanceForPointID:table withID:key];
}
//
//+ (void)registerClassName:(NSString *)className inTable:(NSString *)table{[[self sharedInstance]registerClassName:(NSString *)className inTable:(NSString *)table];};
//- (void)registerClassName:(NSString *)className inTable:(NSString *)table{
//    [[self tableNamed:table] setObject:className forKey:className];
//}
//
//
//+ (void)registerHandler:(id)handler forType:(NSString *)type{[[self sharedInstance]registerHandler:(id)handler forType:(NSString *)type];};
//- (void)registerHandler:(id)handler forType:(NSString *)type{
//    NSMutableDictionary *typeHandlers=[self tableNamed:kQSObjectHandlers];
//    if (!type)return;
//	
//	[[self retainedTableNamed:kQSObjectHandlers] setObject:[self getClassInstance:handler] forKey:type];
//    if (handler)
//        [typeHandlers setObject:handler forKey:type];
//    else
//        [typeHandlers removeObjectForKey:type];
//}
//
//
//- (void) printRegistry:(id)sender{
//	BLog(@"classRegistry:\r%@",classRegistry);
//	BLog(@"bundles:\r%@",classBundles);
//}
//
//
//- (id)preferredInstanceOfTable:(NSString *)table{
//	return [prefInstances objectForKey:table];
//}
//- (void)removePreferredInstanceOfTable:table{
//	
//	id object=[prefInstances objectForKey:table];
//	NSString *className=NSStringFromClass([object class]);
//	if (className)
//	[classInstances removeObjectForKey:className];
//	//BLog(@"class %@",[classInstances allKeys]);
//	if (table)
//		[prefInstances removeObjectForKey:table];
//}
@end
//
//@implementation NSBundle (QSRegistryAdditions)
//- (NSDictionary *)qsRequirementsDictionary{
//	NSString *path=[[self bundlePath]stringByAppendingPathComponent:@"Contents/QSRequirements.plist"];
//	return [[NSFileManager defaultManager]fileExistsAtPath:path]?
//		[NSDictionary dictionaryWithContentsOfFile:path]:[self objectForInfoDictionaryKey:@"QSRequirements"];
//}
//- (NSDictionary *)qsPlugInDictionary{
//	NSString *path=[[self bundlePath]stringByAppendingPathComponent:@"Contents/QSPlugIn.plist"];
//	return [[NSFileManager defaultManager]fileExistsAtPath:path]?
//		[NSDictionary dictionaryWithContentsOfFile:path]:[self objectForInfoDictionaryKey:@"QSPlugIn"];
//}
//- (NSDictionary *)qsRegistrationDictionary{
//	NSString *path=[[self bundlePath]stringByAppendingPathComponent:@"Contents/QSRegistration.plist"];
//	return [[NSFileManager defaultManager]fileExistsAtPath:path]?
//		[NSDictionary dictionaryWithContentsOfFile:path]:[self objectForInfoDictionaryKey:@"QSRegistration"];
//}
//- (NSDictionary *)qsActionsDictionary{return[self dictionaryForFileOrPlistKey:@"QSActions"];}
//
//- (NSDictionary *)dictionaryForFileOrPlistKey:(NSString *)key{
//	NSString *path=[[self bundlePath]stringByAppendingPathComponent:[NSString stringWithFormat:@"Contents/%@.plist",key]];
//	return [[NSFileManager defaultManager]fileExistsAtPath:path]?
//		[NSDictionary dictionaryWithContentsOfFile:path]:[self objectForInfoDictionaryKey:key];
//}
//
//- (NSDictionary *)qsPresetAdditionsDictionary{
//	NSString *path=[[self bundlePath]stringByAppendingPathComponent:@"Contents/QSPresetAdditions.plist"];
//	return [[NSFileManager defaultManager]fileExistsAtPath:path]?
//		[NSDictionary dictionaryWithContentsOfFile:path]:[self objectForInfoDictionaryKey:@"QSPresetAdditions"];
//}
//@end
//
//@implementation QSRegistry (PlugIns)
//
//- (void)bundleDidLoad:(NSNotification *)aNotif{
//	if (DEBUG_PLUGINS)
//	BLog(@"Loaded Bundle: %@ Classes: %@",[[[aNotif object]bundlePath]lastPathComponent],[[[aNotif userInfo]objectForKey:@"NSLoadedClasses"]componentsJoinedByString:@", "]);
//}
//
//- (void)addPlugInsForBundleAtPath:(NSString *)bundlePath{
//	
//}
//
//
//- (BOOL) handleRegistration:(NSBundle *)bundle{
//	NSDictionary *registration=[bundle dictionaryForFileOrPlistKey:@"QSRegistration"];
////BLog(@"register %@",bundle);
//	if (!registration)return NO;
//	//if (![registration isKindOfClass:[NSDictionary class]])[NSException exceptionWithName:@"Invalid registration" reason: @"Registration is not a dictionary" userInfo:nil];
//	//	[bundle load];
//	NSEnumerator *keynum=[registration keyEnumerator];
//	NSString *table;
//	
//	while (table=[keynum nextObject]){
//		
//		NSDictionary *providers=[registration objectForKey:table];
//		if (![providers isKindOfClass:[NSDictionary class]])[NSException raise:@"Invalid registration" format:@"%@ invalid",table];
//		
//		[[self tableNamed:table]addEntriesFromDictionary:providers];
//		
//		NSString *provider;
//		NSEnumerator *e=[providers keyEnumerator];
//		
//		NSMutableDictionary *retainedInstances=[tableInstances objectForKey:table];
//		
//		while(provider=[e nextObject]){
//			id entry=[providers objectForKey:provider];
//			
//			NSString *className=entry;
//			if ([entry isKindOfClass:[NSDictionary class]])
//				className=[entry objectForKey:@"class"];
//			if (className)
//				[classBundles setObject:bundle forKey:className];
//			if (retainedInstances){
//				id instance=[self getClassInstance:className];
//				if (instance)
//					[[self retainedTableNamed:table] setObject:instance forKey:provider];
//			}
//		}	
//		
//	}
//	return YES;
//}
//
//
//
//
//
//- (void)bundleInstalled:(NSBundle *)bundle{
//	if (![identifierBundles objectForKey:[bundle bundleIdentifier]])
//		[identifierBundles setObject:bundle forKey:[bundle bundleIdentifier]];
//	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInInstalledNotification object:bundle];
//	
//}
//
//
//
//- (void)instantiatePlugIns{
//	
//}
////- (void)registerPlugIns{
////	NSMutableDictionary *validBundles=[NSMutableDictionary dictionary];
////	NSEnumerator *enumerator;
////	//	NSString *currPath;
////	NSBundle *curBundle; //,*dupBundle;
////						 //	id currInstance;
////	NSDate *date=[NSDate date];
////	
////	NSMutableArray *allBundles=[NSBundle performSelector:@selector(bundleWithPath:) onObjectsInArray:[self allBundles]];
////	
////	[allBundles removeObject:[NSNull null]];
////	
////	NSDictionary *newBundlesIDs=[NSDictionary dictionaryWithObjects:allBundles
////															forKeys:[allBundles valueForKey:@"bundleIdentifier"]];
////	
////#warning a bundle without an identifier may cause a problem here
////	
////	[identifierBundles addEntriesFromDictionary:newBundlesIDs];
////	
////	enumerator = [allBundles objectEnumerator];
////	while(curBundle = [enumerator nextObject]){
////		//if(curBundle = [NSBundle bundleWithPath:currPath]){
////		//BLog(@"bund %@",curBundle);
////		if ([self shouldLoadPlugIn:curBundle inLoadGroup:validBundles] && [curBundle bundleIdentifier]){
////			[validBundles setObject:curBundle forKey:[curBundle bundleIdentifier]];
////			[identifierBundles setObject:curBundle forKey:[curBundle bundleIdentifier]];
////		}
////		//}
////	}
////	//if (VERBOSE)BLog(@"Loading Plugins:\r%@",[[validBundles valueForKey:@"bundlePath"]componentsJoinedByString:@"\r"]);
////
////
////
////	NSArray *disabledBundles=[[NSUserDefaults standardUserDefaults] objectForKey:@"QSDisabledPlugIns"];
////
////	[validBundles removeObjectsForKeys:disabledBundles];
////	enumerator = [[validBundles allValues] objectEnumerator];
////
////
////	while(curBundle = [enumerator nextObject]){
////		NS_DURING
////			[self loadPlugIn:curBundle];
////		NS_HANDLER
////			NSString *errorMessage=[NSString stringWithFormat:@"An error ocurred while loading plug-in \"%@\": %@",curBundle,localException];
////			if (VERBOSE){
////				BLog(errorMessage);
////				[localException printStackTrace];
////			}
////			NS_ENDHANDLER
////	}
////
////	//	BLog(@"errors %@",loadErrors);
////	[self suggestOldPlugInRemoval];
////	if (DEBUG_STARTUP) BLog(@"PlugIn Load Complete (%dms)",(int)(-[date timeIntervalSinceNow]*1000));
////	initialLoadComplete=YES;
////}
//- (NSDictionary *)restrictionsDict{
//	static NSDictionary *restrictions=nil;
//	if (!restrictions){
//		restrictions=[[NSDictionary alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"PlugInVersionRequirements" ofType:@"plist"]];	
//	}
//	return restrictions;
//}
//
//
//
//
//#define appSupportSubpath @"Application Support/Quicksilver/PlugIns"
//
//- (NSMutableArray *)allBundles{
//	
//	NSEnumerator *searchPathEnum;
//	NSString *currPath;
//	NSMutableSet *bundleSearchPaths = [NSMutableSet set];
//	NSMutableArray *allBundles = [NSMutableArray array];
//	[allBundles addObject:[[NSBundle mainBundle]bundlePath]];
//	
//	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
//	
//	
//	
//	
//	
//	if ((int)getenv("QSDisableExternalPlugIns")){
//		BLog(@"External PlugIns Disabled");
//	}else{
//		NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
//		searchPathEnum = [librarySearchPaths objectEnumerator];
//		while(currPath = [searchPathEnum nextObject])
//			[bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];		
//		[bundleSearchPaths addObject:[[[NSBundle mainBundle]bundlePath] stringByDeletingLastPathComponent]];
//		[bundleSearchPaths addObject:[[[[NSBundle mainBundle]bundlePath] stringByDeletingLastPathComponent]stringByAppendingPathComponent:@"PlugIns"]];
//		[bundleSearchPaths addObject:[[NSFileManager defaultManager]currentDirectoryPath]];
//		[bundleSearchPaths addObject:[[[NSFileManager defaultManager]currentDirectoryPath]stringByAppendingPathComponent:@"PlugIns"]];
//		//[bundleSearchPaths addObject:[[[NSFileManager defaultManager]currentDirectoryPath]stringByAppendingPathComponent:@"PrivatePlugIns"]];
//		
//		NSArray *paths=[[NSUserDefaults standardUserDefaults]arrayForKey:@"QSAdditionalPlugInPaths"];
//		paths=[paths valueForKey:@"stringByStandardizingPath"];
//		[bundleSearchPaths addObjectsFromArray:paths];
//		
//		[bundleSearchPaths addObject:[[[NSFileManager defaultManager]currentDirectoryPath]stringByAppendingPathComponent:@"PrivatePlugIns"]];
//	}
//	
//	searchPathEnum = [bundleSearchPaths objectEnumerator];
//	while(currPath = [searchPathEnum nextObject])
//	{
//		NSEnumerator *bundleEnum;
//		NSString *curBundlePath;
//		bundleEnum = [[[NSFileManager defaultManager]directoryContentsAtPath:currPath]objectEnumerator];
//		if(bundleEnum){
//			while(curBundlePath = [bundleEnum nextObject]){
//				if([[curBundlePath pathExtension] caseInsensitiveCompare:@"qsplugin"]==NSOrderedSame){
//					[allBundles addObject:[currPath stringByAppendingPathComponent:curBundlePath]];
//				}
//			}
//		}
//	}
//	
//	return allBundles;
//}
//
//
//@end
//
//
//
//
//
@implementation QSRegistry (ObjectSource)


- (NSMutableDictionary *)objectSources{
	Debugger();
    return [self elementsForPointID:kQSObjectSources];
}
/*
 + (void)registerSource:(id)source{[[self sharedInstance]registerSource:(id)source];};
 - (void)registerSource:(id)source{
	 
	 [[self retainedTableNamed:kQSObjectSources] setObject:[self getClassInstance:source] forKey:source];
	 [[self tableNamed:] setObject:source forKey:source];
 }
 */
+ (id)sourceNamed:(NSString *)name{return[[self sharedInstance]sourceNamed:(NSString *)name];};
- (id)sourceNamed:(NSString *)name{
    return [self instanceForPointID:kQSObjectSources withID:name];
}




@end

@implementation QSRegistry (ObjectHandlers)


+ (NSMutableDictionary *)objectHandlers{
	return[[self sharedInstance]objectHandlers];
}
- (NSMutableDictionary *)objectHandlers{
    return [self loadedInstancesByIDForPointID:kQSObjectHandlers];
}
@end


@implementation NSObject (InstancePerform)

+ (id)performSelectorWithInstance:(SEL)selector{
	return [[QSReg getClassInstance:NSStringFromClass([self class])]performSelector:selector];
}
@end

@implementation QSRegistry (Mediators)
- (id)getMediator:(NSString *)name{
	BExtensionPoint *point = [self extensionPointWithID:name];
	NSDictionary *header = [point plistContent];
  
  
	if (!header) return nil;
	NSString *selector=[header objectForKey:@"selector"];
	NSBundle *bundle=[[point plugin] bundle];
	if (bundle && ![bundle isLoaded])[bundle load];
	SEL sel=NSSelectorFromString(selector);
	id mediator = nil;
	if (sel)
		mediator = [self performSelector:sel withObject:name];
  
	return mediator;
}

- (id)getMediatorID:(NSString *)name{
	BExtensionPoint *point = [self extensionPointWithID:name];
	NSDictionary *header = [point plistContent];
	NSString *selector=[header objectForKey:@"registryPreferredSelector"];
	NSBundle *bundle=[[point plugin] bundle];
	if (bundle && ![bundle isLoaded])[bundle load];
	SEL sel=NSSelectorFromString(selector);
	if (sel)
		return [self performSelector:sel withObject:name];
	else
		return nil;
}
@end





