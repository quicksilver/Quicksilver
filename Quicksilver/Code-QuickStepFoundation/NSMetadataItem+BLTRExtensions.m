//
// NSMetadataItem+BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 5/26/05.
// Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import "NSMetadataItem+BLTRExtensions.h"

@implementation NSMetadataItem (BLTRExtensions)
- (NSImage *)icon { return [[NSWorkspace sharedWorkspace] iconForFile:[self valueForKey:(id)kMDItemPath]]; }
- (NSString *)displayName { return [self valueForAttribute:(NSString *)kMDItemDisplayName]; }
+ (NSMetadataItem *)itemWithPath:(NSString *)path { return [[[self alloc] _init:MDItemCreate(NULL, (CFStringRef) path)] autorelease]; }
@end
