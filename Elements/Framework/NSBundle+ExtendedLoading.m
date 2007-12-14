//
//  NSBundle+ExtendedLoading.m
//  Elements
//
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSBundle+ExtendedLoading.h"


@implementation NSBundle (ExtendedLoading)
- (BOOL)registerDefaults {
	if (![self isLoaded]) {
		NSDictionary *newDefaults = [self objectForInfoDictionaryKey:@"QSDefaults"];
		if (newDefaults) {
			//BLog(@"Registered Defaults %@", [[newDefaults allKeys] componentsJoinedByString:@", "]);
			[[NSUserDefaults standardUserDefaults] registerDefaults:newDefaults];
		}
		
		// TODO: load applescript stuff
	}
    return YES;
}
@end
