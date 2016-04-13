//
//  QSSharedFileListSource.m
//  Quicksilver
//
//  Created by Rob McBroom on 2016/03/16.
//
//

#import "QSSharedFileListSource.h"
#import "QSFoundation.h"

@implementation QSSharedFileListSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
	NSDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSString *sflPath = [settings objectForKey:kItemPath];
	if (!sflPath) {
		return YES;
	}
	NSString *path = [sflPath stringByStandardizingPath];
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] || isDir) {
		return YES;
	}
	NSDate *modDate = [[manager attributesOfItemAtPath:path error:NULL] fileModificationDate];
	if ([modDate compare:indexDate] == NSOrderedDescending) {
		return NO;
	}
	return YES;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSMutableArray *sflItemArray = [NSMutableArray arrayWithCapacity:0];
	NSString *sflPath = [settings objectForKey:kItemPath];
	NSString *path = [sflPath stringByStandardizingPath];
	BOOL isDir = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] || isDir) {
		return nil;
	}
	NSDictionary *sflData = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	NSString *kItems = @"items";
	if (![[sflData allKeys] containsObject:kItems]) {
		return nil;
	}
	for (SFLListItem *item in sflData[kItems]) {
		// item's class is SFLListItem
		if ([item URL]) {
			[sflItemArray addObject:item];
		}
	}
	[sflItemArray sortUsingComparator:^NSComparisonResult(SFLListItem *item1, SFLListItem *item2) {
		return item1.order > item2.order;
	}];
	return [sflItemArray arrayByEnumeratingArrayUsingBlock:^id(SFLListItem *item) {
		NSURL *url = [item URL];
		if ([url isFileURL]) {
			return [QSObject fileObjectWithFileURL:url];
		}
		return [QSObject URLObjectWithURL:[[item URL] absoluteString] title:[item name]];
	}];
}

@end
