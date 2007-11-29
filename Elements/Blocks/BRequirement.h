//
//  BRequirement.h
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;

// Imports define the requirements for a plugin to load. If a plugins imports are not satisfied then the plugins code will not load. Optional imports constrain the load order of plugins. A plugins optional imports will always be loaded before the plugin of they exist.
@interface BRequirement : NSManagedObject {
}

#pragma mark init

- (id)initWithIdentifier:(NSString *)identifier version:(NSString *)version optional:(BOOL)optional;

#pragma mark accessors

- (BPlugin *)requiredPlugin;
- (NSBundle *)requiredBundle;

#pragma mark loading

- (BOOL)isLoaded;
- (BOOL)load;

@end
