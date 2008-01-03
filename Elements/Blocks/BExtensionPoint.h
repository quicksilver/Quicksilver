/**
 *  @file BExtensionPoint.h
 *
 *  Blocks
 *  
 *  Copyright 2006 Blocks. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "BExtension.h"

/**
 *  @brief The public BExtensionPoint interface
 */
@interface BExtensionPoint : BExtension {
	NSMutableArray *elements;
	NSMutableArray *loadedElements;
	NSMutableArray *loadedInstances;
	NSMutableDictionary *elementsByID;
	NSMutableDictionary *instancesByID;
	// TODO: cache instances in various forms
}

/**
 *  @brief Returns the reciever's elements as an array.
 *  This method will trigger loading of all the elements associated with the reciever.
 */
- (NSArray *)elements;

/**
 *  @brief Returns the reciever's loaded elements.
 *  This method will return only the elements currently loaded by the reciever.
 */
- (NSArray *)loadedElements;

/**
 *  @brief Returns the reciever's elements as a dictionary.
 *  Those are keyed by element identifier.
 */
- (NSDictionary *)elementsByID;

/**
 *  @brief Returns the element identifier by @param elementID.
 */
- (BElement *)elementWithID:(NSString *)elementID;
@end
