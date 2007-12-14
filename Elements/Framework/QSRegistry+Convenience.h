//
//  QSRegistry+Convenience.h
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSRegistry.h"

#define QSPlugInLoadedNotification @"QSPlugInLoaded"
#define QSPlugInInstalledNotification @"QSPlugInInstalled"

#define kQSActionProviders @"QSActionProviders"
#define kQSFSParsers @"QSFSParsers"
#define kQSObjectSources @"QSObjectSources"
#define kQSObjectHandlers @"QSObjectHandlers"
#define kQSPreferencePanes @"QSPreferencePanes"
#define pRegistryStoreLocation QSApplicationSupportSubPath(@"Registry.plist",NO);

@interface QSRegistry (Convenience)

- (NSMutableDictionary *)tableNamed:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key inTable:(NSString *)table;
- (void)registerClassName:(NSString *)className inTable:(NSString *)table;
- (NSMutableDictionary *)instancesForTable:(NSString *)key;
- (NSMutableDictionary *)retainedTableNamed:(NSString *)key;
- (id)preferredInstanceOfTable:(NSString *)table;
- (void)removePreferredInstanceOfTable:table;
- (id)getClassInstance:(NSString *)className;

- (Class)getClass:(NSString*)className;

- (id)valueForKey:(NSString *)key inTable:(NSString *)table;
- (id)instanceForKey:(NSString *)key inTable:(NSString *)table;
- (NSBundle *)bundleForClassName:(NSString *)className;
- (NSBundle *)bundleWithIdentifier:(NSString *)ident;
- (NSMutableDictionary *)identifierBundles;

- (void)registerBundle:(NSBundle *)bundle;
@end

@interface QSRegistry (ObjectSource)
- (NSMutableDictionary *)objectSources;
- (id)sourceNamed:(NSString *)name;
//- (void)registerSource:(id)source;
@end

@interface QSRegistry (ObjectHandlers)
- (NSMutableDictionary *)objectHandlers;
	//- (void)registerHandler:(id)handler forType:(NSString *)type;
@end


@interface QSRegistry (PlugIns)

- (void)addPlugInsForBundleAtPath:(NSString *)bundlePath;
		 //- (BOOL)registerBundle:(NSBundle *)bundle;
- (NSMutableArray *)allBundles;
	//- (BOOL)shouldLoadPlugIn:(NSBundle *)bundle inLoadGroup:(NSDictionary *)loadingBundles;
- (void)instantiatePlugIns;
	//- (void)registerPlugIns;
- (void)bundleInstalled:(NSBundle *)bundle;
- (NSDictionary *)restrictionsDict;
- (BOOL) handleRegistration:(NSBundle *)bundle;
@end


@interface NSObject (QSPluginLoading)
+(void)loadPlugIn;
@end

@interface NSBundle (QSRegistryAdditions)
- (NSDictionary *)qsRequirementsDictionary;
- (NSDictionary *)qsPlugInDictionary;
- (NSDictionary *)qsRegistrationDictionary;
- (NSDictionary *)qsActionsDictionary;
- (NSDictionary *)dictionaryForFileOrPlistKey:(NSString *)key;
- (NSDictionary *)qsPresetAdditionsDictionary;
@end




@interface QSRegistry (Mediators)
- (id)getMediator:(NSString *)name;
- (id)getMediatorID:(NSString *)name;
@end