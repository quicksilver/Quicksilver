/**
 *  @file BExtension.h
 *  
 *  Blocks
 *  
 *  Copyright 2006 Blocks. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@class BPlugin;
@class BExtensionPoint;

/**
 *  @brief The public BExtension interface
 *  This class acts as a base implementation for both BElement and BExtensionPoint since they need similar accessors.
 *  This class is similar to Eclipse's IExtension.
 */
@interface BExtension : NSManagedObject {
}

#pragma mark accessors
/**
 *  @brief Returns the plugin associated with the reciever.
 */
- (BPlugin *)plugin;

/**
 *  @brief Returns the plugin associated with the reciever.
 */
- (NSString *)extensionPointID;

/**
 *  @brief Returns the extension point associated with the reciever.
 */
- (BExtensionPoint *)extensionPoint;

/**
 *  @brief Returns the reciever's identifier.
 */
- (NSString *)identifier;

/**
 *  @brief Compare Declaration Orders
 *  This method compares the load ordering of this extension with the given extension.
 *  If the extensions plugins are different the load order of the plugin is used to compare.
 *  If the plugins are the same then the extension declaration order is used to compare.
 *  This ordering is used by some extension points (such as menu extensions) to decide which extensions are processed first.
 */
- (NSComparisonResult)compareDeclarationOrder:(BExtension *)extension;

/**
 *  @brief Returns the reciever's contents as an XML element
 */
- (NSXMLElement *)XMLContent;

/**
 *  @brief Returns the reciever's contents as a plist-compatible id
 */
- (id)plistContent;

@end