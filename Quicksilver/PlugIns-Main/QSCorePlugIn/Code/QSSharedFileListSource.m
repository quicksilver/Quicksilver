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

/**
 * Returns the valid path for an SFL file.
 * Tries .sfl3, .sfl2, and .sfl extensions in order.
 * @return NSString path, or nil if no valid file exists
 */
- (NSString *)validPathForSfl:(NSString *)sflPath
{
	NSString *basePath = [sflPath stringByStandardizingPath];
	// Strip any existing .sfl* extension
	basePath = [basePath stringByDeletingPathExtension];

	// Try extensions in order: .sfl3, .sfl2, .sfl
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *extensions = @[@".sfl3", @".sfl2", @".sfl"];
	for (NSString *ext in extensions) {
		NSString *testPath = [basePath stringByAppendingString:ext];
		BOOL isDir = NO;
		if ([manager fileExistsAtPath:testPath isDirectory:&isDir] && !isDir) {
			return testPath;
		}
	}
	return nil;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
	NSDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSString *sflPath = [settings objectForKey:kItemPath];
	if (!sflPath) {
		return YES;
	}

	NSString *path = [self validPathForSfl:sflPath];
	if (!path) {
		return YES;
	}

	NSFileManager *manager = [NSFileManager defaultManager];
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

	NSString *path = [self validPathForSfl:sflPath];
	if (!path) {
		return nil;
	}

	NSString *extension = [path pathExtension];

	NSDictionary *sflData = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	NSString *kItems = @"items";
	if (![[sflData allKeys] containsObject:kItems]) {
		return nil;
	}

	// Parse based on file extension: sfl2 and sfl3 use bookmark data, sfl uses SFLListItem
	if ([extension isEqualToString:@"sfl2"] || [extension isEqualToString:@"sfl3"]) {
		return [sflData[kItems] arrayByEnumeratingArrayUsingBlock:^id(NSDictionary *item) {
			// Bookmark data might be direct NSData or wrapped in a dictionary with NS.data key
			id bookmarkValue = item[@"Bookmark"];
			NSData *bookmarkData = nil;

			if ([bookmarkValue isKindOfClass:[NSData class]]) {
				bookmarkData = bookmarkValue;
			} else if ([bookmarkValue isKindOfClass:[NSDictionary class]]) {
				// Try NS.data key (common in sfl3)
				bookmarkData = bookmarkValue[@"NS.data"];
			}

			if (!bookmarkData) {
				return nil;
			}

			NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithoutMounting relativeToURL:nil bookmarkDataIsStale:nil error:nil];
			if ([url isFileURL]) {
				return [QSObject fileObjectWithFileURL:url];
			}
			return [QSObject URLObjectWithURL:[url absoluteString] title:item[@"Name"]];
		}];
	} else if ([extension isEqualToString:@"sfl"]) {
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
	return nil;
}

@end
