/**
 *  @file BPlugin.h
 *
 *  Blocks
 *
 *  Copyright 2006 Blocks. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

/**
 *  @brief A notification sent just before a plugin will be loaded
 */
extern NSString *kBPluginWillLoadNotification;

/**
 *  @brief A notification sent just after a plugin has been loaded
 */
extern NSString *kBPluginDidLoadNotification;


/**
 *  @brief A notification sent just before a plugin will be registered
 */
extern NSString *kBPluginWillRegisterNotification;

/**
 *  @brief A notification sent just after a plugin has been registered
 */
extern NSString *kBPluginDidRegisterNotification;

/**
 *  @brief The public BPlugin interface
 */
@interface BPlugin : NSManagedObject {
    NSBundle *bundle;
	NSXMLDocument *pluginXMLDocument;
    NSDictionary *attributes;
	unsigned loadSequenceNumber;
	BOOL registered;
	NSXMLElement *info;
}

/**
 *  @brief The reciever's designated initializer
 */
- (id)initWithPluginURL:(NSURL *)url bundle:(NSBundle *)bundle insertIntoManagedObjectContext:(NSManagedObjectContext*)context;

/**
 *  @brief Returns the bundle associated with the reciever.
 */
- (NSBundle *)bundle;

/**
 *  @brief Change the bundle associated with the reciever.
 */
- (void)setBundle:(NSBundle *)value;

/**
 *  @brief Returns the reciever's name.
 */
- (NSString *)name;

/**
 *  @brief Returns the reciever's identifier.
 */
- (NSString *)identifier;

/**
 *  @brief Returns the reciever's version.
 */
- (NSString *)version;

/**
 *  @brief Returns the reciever's requirements.
 */
- (NSArray *)requirements;

/**
 *  @brief Returns the reciever's extension points.
 */
- (NSArray *)extensionPoints;


/**
 *  @brief Returns the reciever's extensions.
 */
- (NSArray *)extensions;

/**
 *  @brief Returns the path to the reciever's XML declaration.
 */
- (NSString *)xmlPath;

/**
 *  @brief Returns the path to the reciever's protocols declaration.
 */
- (NSString *)protocolsPath;

/**
 *  @brief Returns YES if the reciever is enabled, NO otherwise.
 */
- (BOOL)enabled;

/**
 *  @brief Returns the reciever as an XML element.
 */
- (NSXMLElement *)info;

/**
 *  @brief Returns the reciever as an XML document
 */
- (NSXMLDocument *)pluginXMLDocument;

#pragma mark loading

/**
 *  @brief Load the reciever attributes from its XML contents.
 *  @return This method returns YES in case of success, NO otherwise.
 */
- (BOOL) loadPluginXMLAttributes;

/**
 *  @brief Load the reciever contents from its XML contents.
 *  @return This method returns YES in case of success, NO otherwise.
 */
- (BOOL) loadPluginXMLContent;

/**
 *  @brief Returns the reciever load order.
 */
- (unsigned)loadSequenceNumber;

/**
 *  @brief Returns whether the reciever is loaded or not.
 */
- (BOOL)isLoaded;

/**
 *  @brief Load the reciever and return whether successful or not.
 */
- (BOOL)load;

/**
 *  @brief Registers the plugin.
 *  Returns YES if registration is successful, NO otherwise.
 */
- (BOOL)registerPlugin;

/**
 *  @brief Returns an URL representing the file-system location of the reciever.
 */
- (NSURL *)pluginURL;

@end