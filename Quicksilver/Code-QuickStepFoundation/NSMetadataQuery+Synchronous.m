//
//  NSMetadataQuery+Synchronous.m
//
//  Created by Rob McBroom on 2012/03/22.
//

#import "NSMetadataQuery+Synchronous.h"

@implementation NSMetadataQuery (Synchronous)

- (NSArray *)resultsForSearchString:(NSString *)searchString
{
	// search everywhere
	return [self resultsForSearchString:searchString inFolders:nil];
}

- (NSArray *)resultsForSearchString:(NSString *)searchString inFolders:(NSSet *)paths
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneSearching:) name:NSMetadataQueryDidFinishGatheringNotification object:nil];
	NSPredicate *search = [NSPredicate predicateWithFormat:searchString];
	[self setPredicate:search];
	if (![paths isEqual:nil]) {
		NSMutableArray *pathURLs = [[NSMutableArray alloc] init];
		for (NSString *path in paths) {
			NSURL *pathURL = [NSURL fileURLWithPath:path];
			[pathURLs addObject:pathURL];
		}
		[self setSearchScopes:pathURLs];
	}
	if ([self startQuery]) {
		CFRunLoopRun();
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
		return [self results];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
		NSLog(@"query failed to start: %@", searchString);
	}
	return nil;
}

- (void)doneSearching:(NSNotification *)note
{
	[self stopQuery];
	CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
