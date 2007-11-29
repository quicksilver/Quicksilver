//
//  BExtensionPoint.h
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BExtension.h"

@class BPlugin, BElement;

@interface BExtensionPoint : BExtension {
	NSMutableArray *elements;
	NSMutableArray *loadedElements;
	NSMutableArray *loadedInstances;
	NSMutableDictionary *elementsByID;
	NSMutableDictionary *instancesByID;
	// TODO: cache instances in various forms
}
- (NSArray *)elements;
- (NSArray *)loadedElements;
- (NSDictionary *)elementsByID;
- (BElement *)elementWithID:(NSString *)elementID;
@end
