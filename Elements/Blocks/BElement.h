/*
 *  @file BElement.h
 *  @brief The basic plugin block
 *  
 *  Blocks
 *
 *  Copyright 2007 Blocks. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


#import "BPlugin.h"
#import "BExtension.h"

/**
 *  @brief The public BElement interface
 *  This class is equivalent to IConfigurationElement
 */
@interface BElement : BExtension {
    Class elementClass;
    id elementInstance;	
}

/**
 *  @brief Returns the reciever class name
 */
- (NSString *)elementClassName;

/**
 *  @brief Returns the reciever class
 */
- (Class)elementClass;

/**
 *  @brief Returns the current reciever instance
 */
- (id)elementInstance;

/**
 *  @brief Returns a new autoreleased reciever instance
 */
- (id)elementNewInstance;
@end

/**
 *  @brief The public BExecutableExtension interface
 *  This protocol is equivalent to IExecutableExtension
 */
@protocol BExecutableExtension
/**
 *  @brief Returns the BExecutableExtension-conformant instance associated with the specified BElement
 */
+ (id) instanceWithElement:(BElement *)element;
@end