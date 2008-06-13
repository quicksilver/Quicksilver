/**
 *  @file BRegistry.h
 *  @brief A class implementing a registry-like plugin architecture.
 *
 *  Blocks
 *
 *  Copyright 2006 Blocks. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@class BPlugin;
@class BElement;
@class BExtensionPoint;

/**
    @class
    @abstract    Central Blocks plugin registry
    @discussion  (comprehensive description)
*/
@interface BRegistry : NSObject {
    BOOL scannedPlugins;
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
  
    NSMutableDictionary *extensionPointCache;
}

#pragma mark Class Methods
/**
 *  @brief Returns the shared reciever instance.
 */
+ (id)sharedInstance;

/**
 *  @brief Make all elements attached to the correspoding extension point ID perform the passed in selector
 */
+ (void)performSelector:(SEL)selector forExtensionPoint:(NSString *)extensionPointID protocol:(Protocol *)protocol;

#pragma mark Plugin loadeing

/**
 *  @brief Scan all plugins
 */
- (void)scanPlugins;

/**
 *  @brief Load the main extension point
 */
- (void)loadMainExtension;

#pragma mark Accessors

/**
 *  @brief Returns all the registered plugins
 */
- (NSArray *)plugins;

/**
 *  @brief Returns all the registered extension points
 */
- (NSArray *)extensionPoints;

/**
 *  @brief Returns all the registered extensions
 */
- (NSArray *)extensions;

#pragma mark lookup

/**
 *  @brief Returns the plugin corresponding with the passed URL
 */
- (BPlugin *)pluginWithURL:(NSURL *)pluginURL;

/**
 *  @brief Returns the plugin with the specified plugin ID
 */
- (BPlugin *)pluginWithID:(NSString *)pluginID;

/**
 *  @brief Returns the extension point associated with this point ID
 */
- (BExtensionPoint *)extensionPointWithID:(NSString *)extensionPointID;

/**
 *  @brief Returns all elements with a specific extension point ID
 */
- (NSArray *)elementsForPointID:(NSString *)extensionPointID;

/**
 *  @brief Returns all loaded elements for a specific extension point ID
 */
- (NSArray *)loadedElementsForPointID:(NSString *)extensionPointID;

/**
 *  @brief Returns all loaded elements for a specific extension point ID keyed by element ID
 */
- (NSDictionary *)loadedElementsByIDForPointID:(NSString *)extensionPointID;

/**
 *  @brief Returns all loaded instances for a specific extension point ID
 */
- (NSArray *)loadedInstancesForPointID:(NSString *)extensionPointID;

/**
 *  @brief Returns all loaded instances for a specific extension point ID keyed by element ID
 */
- (NSDictionary *)loadedInstancesByIDForPointID:(NSString *)extensionPointID;

/**
 *  @brief Returns a dictionary containing all elements for a specific extension point ID keyed by element ID.
 */
- (NSDictionary *)elementsByIDForPointID:(NSString *)extensionPointID;

/**
 *  @brief Returns the element associated with the specified extension point ID and element ID
 */
- (BElement *)elementForPointID:(NSString *)extensionPointID withID:(NSString *)elementID;

/**
 *  @brief Returns the element instance associated with the specified extension point ID and element ID
 */
- (BElement *)instanceForPointID:(NSString *)extensionPointID withID:(NSString *)elementID;

/**
 *  @brief Registers a plugin at a path.
 */
- (void)registerPluginWithPath:(NSString *)thisPath;

/**
 *  @brief Log all the current registry
 */
- (void)logRegistry;

/**
 *  @brief Returns the current managed object context.
 *
 *  Returns the managed object context for the application (which is already
 *  bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext;

/**
 *  @brief Save the current registry
 *
 *  Performs the save action for the application, which is to send the save:
 *  message to the application's managed object context.  Any encountered errors
 *  are presented to the user.
 */
- (IBAction) saveAction:(id)sender;

/**
 *  @brief Clear all cached extension points information.
 */
- (IBAction) clearAllCaches:(id)sender;

/**
 *  @brief Clear old cached extension points information.
 */
- (IBAction) clearOldCaches:(id)sender;

@end