//
// QSLoginItemFunctions.m
// Quicksilver
//
// Created by Alcor on 12/22/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSLoginItemFunctions.h"
#import "NDAlias.h"

BOOL QSItemShouldLaunchAtLogin(NSString *path) {
	NSArray *loginItems = [(NSArray *)CFPreferencesCopyValue((CFStringRef) @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
	for (id loopItem in loginItems) {
		if ([[[loopItem objectForKey:@"Path"] stringByStandardizingPath] isEqualToString:path]) {
			return YES;
		}
	}
	return NO;
}

void QSSetItemShouldLaunchAtLogin(NSString *path, BOOL launch, BOOL includeAlias) {
	NSMutableArray *loginItems;
	NSArray *tempItems = (NSArray*)CFPreferencesCopyValue((CFStringRef) @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	loginItems = [[tempItems mutableCopy] autorelease];
	[tempItems release];

	if (!loginItems) {
#ifdef DEBUG
			NSLog(@"Creating AutoLaunchedApplicationDictionary");
#endif
		loginItems = [NSMutableArray arrayWithCapacity:1];
	}

	if (launch && !QSItemShouldLaunchAtLogin(path) ) {
		NSLog(@"Enabling Launch at login: %@", path);
		[loginItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", [NSNumber numberWithBool:NO] , @"Hide", includeAlias?[[NDAlias aliasWithPath:path] data] :nil, @"AliasData", nil]];
	} else if (!launch) {
		int i;
		for (i = 0; i<[loginItems count]; i++)
			if ([[[[loginItems objectAtIndex:i] objectForKey:@"Path"] stringByStandardizingPath] isEqualToString:path]) break;
		if (i<[loginItems count])
			[loginItems removeObjectAtIndex:i];
		NSLog(@"Disable Login Launch: %@", path);
	}
	CFPreferencesSetValue((CFStringRef) @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}
