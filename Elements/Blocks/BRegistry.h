//
//  BRegistry.h
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;
@class BElement;
@class BExtensionPoint;

/*!
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

#pragma mark class methods

+ (id)sharedInstance;
+ (void)performSelector:(SEL)selector forExtensionPoint:(NSString *)extensionPointID protocol:(Protocol *)protocol;
- (BPlugin *)pluginWithURL:(NSURL *)pluginURL;
#pragma mark init

- (void)scanPlugins;
- (void)loadMainExtension;

#pragma mark accessors

- (NSArray *)plugins;
- (NSArray *)extensionPoints;
- (NSArray *)extensions;

#pragma mark lookup

- (BPlugin *)pluginWithID:(NSString *)pluginID;
- (BExtensionPoint *)extensionPointWithID:(NSString *)extensionPointID;

- (NSArray *)elementsForPointID:(NSString *)extensionPointID;
- (NSArray *)loadedElementsForPointID:(NSString *)extensionPointID;
- (NSArray *)loadedInstancesForPointID:(NSString *)extensionPointID;
- (NSDictionary *)elementsByIDForPointID:(NSString *)extensionPointID;

- (BElement *)elementForPointID:(NSString *)extensionPointID 
                         withID:(NSString *)elementID;
- (BElement *)instanceForPointID:(NSString *)extensionPointID 
                          withID:(NSString *)elementID;
	

- (void)registerPluginWithPath:(NSString *)thisPath;

- (void)logRegistry;
	
- (NSManagedObjectContext *) managedObjectContext;

- (IBAction) saveAction:(id)sender;

- (IBAction) clearAllCaches:(id)sender;
- (IBAction) clearOldCaches:(id)sender;


@end