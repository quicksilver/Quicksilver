//
//  QSICloudDocumentSource.m
//  Quicksilver
//
//  Created by Rob McBroom on 2012/08/20.
//
//

#import "QSICloudDocumentSource.h"
#import "QSDownloads.h"

@implementation QSICloudDocumentSource

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry
{
	NSMutableArray *objects = [NSMutableArray array];
	NSArray *ICloudEnabledApplications = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:pICloudDocumentsPrefix error:nil];
	for (NSString *appBundleID in ICloudEnabledApplications) {
		// technically, these aren't bundle IDs (they already use ~ instead of .)
		// but they'll work with the iCloudDocumentsForBundleID method
		[objects addObjectsFromArray:[QSDownloads iCloudDocumentsForBundleID:appBundleID]];
	}
	return objects;
}

@end
