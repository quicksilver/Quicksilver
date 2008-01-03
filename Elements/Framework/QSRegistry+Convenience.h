/**
 *  @file QSRegistry+Convenience.h
 *  @brief Convenient category on QSRegistry
 *  This category provides useful methods for manipulating Quicksilver registry
 *  
 *  QSElements
 *
 *  Copyright 2007 Blacktree. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "QSRegistry.h"

#define QSPlugInLoadedNotification @"QSPlugInLoaded"
#define QSPlugInInstalledNotification @"QSPlugInInstalled"

#define kQSActionProviders @"QSActionProviders"
#define kQSFSParsers @"QSFSParsers"
#define kQSObjectSources @"QSObjectSources"
#define kQSObjectHandlers @"QSObjectHandlers"
#define kQSPreferencePanes @"QSPreferencePanes"
#define pRegistryStoreLocation QSApplicationSupportSubPath(@"Registry.plist", NO);

/**
 *  @brief A convenience category on QSRegistry 
 */
@interface QSRegistry (Convenience)

/**
 *  @brief Returns the plugin bundle with the specified identifier @param ident
 */
- (NSBundle *)bundleWithIdentifier:(NSString *)ident;

/**
 *  @brief Returns the plugin bundle with the specified class name @param className
 */
- (NSBundle *)bundleForClassName:(NSString *)className;

/**
 *  @brief Returns an instance of the plugin class named @param className
 */
- (id)getClassInstance:(NSString *)className;

/**
 *  @brief Returns an instance of the plugin associated with the key @param key in table @param table
 */
- (id)instanceForKey:(NSString *)key inTable:(NSString *)table;

/**
 *  @brief Returns the instances in table @param table.
 */
- (NSDictionary *)instancesForTable:(NSString *)key;

/**
 *  @brief Register a class named @param className in table @param table
 */
- (void)registerClassName:(NSString *)className inTable:(NSString *)table;

// FIXME: Those are defined but not completely implemented
/**
 *  @brief Returns the table named @param key retained by the reciever.
 */
- (NSDictionary *)retainedTableNamed:(NSString *)key;

- (Class)getClass:(NSString*)className;

/**
 *  @brief Returns the table associated to the given name
 */
- (NSDictionary *)tableNamed:(NSString *)key;

// FIXME: Those are defined but not implemented

/**
 *  @brief Set the object associated with @param key in @param table to @object
 */
- (void)setObject:(id)object forKey:(NSString *)key inTable:(NSString *)table;

- (id)preferredInstanceOfTable:(NSString *)table;

- (void)removePreferredInstanceOfTable:table;

- (id)valueForKey:(NSString *)key inTable:(NSString *)table;

- (NSDictionary *)identifierBundles;

- (void)registerBundle:(NSBundle *)bundle;
@end

/**
 *  @brief A category on QSRegistry for ObjectSource handling
 */
@interface QSRegistry (ObjectSource)

/**
 *  @brief Returns the QSObjectSource with the specified ID @param ID
 */
- (id)sourceNamed:(NSString *)sourceID;

/**
 *  @brief Set the object associated with @param key in @param table to @object
 *  It's not implemented right now.
 */
- (NSDictionary *)objectSources;

@end

/**
 *  @brief A category on QSRegistry for ObjectHandled handling
 */
@interface QSRegistry (ObjectHandlers)
- (NSMutableDictionary *)objectHandlers;
	//- (void)registerHandler:(id)handler forType:(NSString *)type;
@end


/**
 *  @brief A category on QSRegistry for plugin handling
 */
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

/**
 *  @brief A category on NSObject for plugin loading
 */
@interface NSObject (QSPluginLoading)
+(void)loadPlugIn;
@end

/**
 *  @brief A category on NSBundle for direct plugin information access
 */
@interface NSBundle (QSRegistryAdditions)
- (NSDictionary *)qsRequirementsDictionary;
- (NSDictionary *)qsPlugInDictionary;
- (NSDictionary *)qsRegistrationDictionary;
- (NSDictionary *)qsActionsDictionary;
- (NSDictionary *)dictionaryForFileOrPlistKey:(NSString *)key;
- (NSDictionary *)qsPresetAdditionsDictionary;
@end

/**
 *  @brief A category on QSRegistry for Mediators handling
 */
@interface QSRegistry (Mediators)
- (id)getMediator:(NSString *)name;
- (id)getMediatorID:(NSString *)name;
@end