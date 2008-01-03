//
//  BRequirement.m
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import "BRequirement.h"
#import "BRegistry.h"
#import "BPlugin.h"
#import "BLog.h"


@implementation BRequirement

#pragma mark Lifetime

- (id)initWithIdentifier:(NSString *)identifier version:(NSString *)version optional:(BOOL)isOptional {
	if ((self = [super init])) {
	[self setValue:identifier forKey:@"identifier"];
	[self setValue:version forKey:@"version"];
	[self setValue:[NSNumber numberWithBool:isOptional] forKey:@"optional"];
	}
	return self;
}

#pragma mark Accessors

- (NSString *)description {
    return [NSString stringWithFormat:@"bundleIdentifier: %@ optional: %i", [self valueForKey:@"bundle"], [self valueForKey:@"optional"]];
}

- (BPlugin *)requiredPlugin {
	return [[BRegistry sharedInstance] pluginWithID:[self valueForKey:@"bundleIdentifier"]];
}

- (NSBundle *)requiredBundle {
	return [NSBundle bundleWithIdentifier:[self valueForKey:@"bundleIdentifier"]];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
	BLog(@"Requirement %@ could not set value %@ to %@", self,  key, value);	
}

#pragma mark Loading

- (BOOL)isLoaded {
	BPlugin *plugin = [self requiredPlugin];
	if (plugin) return [plugin isLoaded];
	NSBundle *bundle = [self requiredBundle];
	if (bundle) return [bundle isLoaded];
	return NO;
}

- (BOOL)load {
	BPlugin *plugin = [self requiredPlugin];
	if (plugin) return [plugin load];
	NSBundle *bundle = [self requiredBundle];
	if (bundle) return [bundle load];
	return NO;
}

@end
