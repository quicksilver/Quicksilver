/**
 *  @file BRequirement.h
 *  @brief This class defines the dependencies tree for a plugin.
 *  If a plugins requirements are not satisfied then the plugins code will not load.
 *  Optional requirements constrain the load order of plugins.
 *  A plugin optional requirements will always be loaded before the plugin actually loads.
 *  
 *  Blocks
 *  
 *  Copyright 2006 Blocks. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@class BPlugin;

/**
 *  @brief The public BRequirement interface.
 */
@interface BRequirement : NSManagedObject {
}

#pragma mark Lifetime
/**
 *  @brief Inits the reciever with the specific identifier, version, and optionality flag
 *  This is the designated initializer for BRequirement
 */
- (id)initWithIdentifier:(NSString *)identifier version:(NSString *)version optional:(BOOL)optional;

#pragma mark Accessors

/**
 *  @brief Returns the specified required plugin.
 */
- (BPlugin *)requiredPlugin;

/**
 *  @brief Returns the bundle containing the specified required plugin.
 */
- (NSBundle *)requiredBundle;

#pragma mark Loading

/**
 *  @brief Returns YES if the reciever's requirements are met.
 */
- (BOOL)isLoaded;

/**
 *  @brief Try to load the reciever requirements.
 *  @returns This method returns YES in case of success, NO otherwise.
 */
- (BOOL)load;

@end
