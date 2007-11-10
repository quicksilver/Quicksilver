//
//  NSMetadataItem+BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 5/26/05.

//

#import "NSMetadataItem+BLTRExtensions.h"


@implementation NSMetadataItem (BLTRExtensions)
- (NSImage *)icon {
    NSString *path = [self valueForKey:(id)kMDItemPath];
    return [[NSWorkspace sharedWorkspace] iconForFile:path];
}
- (NSString *)displayName{
	return [self valueForAttribute:(NSString *)kMDItemDisplayName];
}
+ (NSMetadataItem *)itemWithPath:(NSString *)path{
	MDItemRef ref=MDItemCreate(NULL,(CFStringRef)path);
	return [[[self alloc]_init:ref]autorelease];
}
@end
