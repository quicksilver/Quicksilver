//
//  QSPathsTests.m
//  QSCoreTests
//
//  Created by Nathan Henrie on 2023-09-11.
//

#import <XCTest/XCTest.h>
#import "QSLibrarian.h"


@interface QSCatalogEntryTests : XCTestCase

@end

@implementation QSCatalogEntryTests

-(NSURL *)tmpPath {
	NSURL *tempFolder = [NSURL fileURLWithPath:NSTemporaryDirectory()];
	NSURL *testFolder = [tempFolder URLByAppendingPathComponent:@"qstest"];
	return testFolder;
}
-(void)setUp {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtURL:[self tmpPath] error:nil];
	[fileManager createDirectoryAtURL:[self tmpPath] withIntermediateDirectories:YES attributes:nil error:nil];
}

-(void)tearDown {
	// delete the folder
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtURL:[self tmpPath] error:nil];
}
-(NSURL *)createTempFolderWithFileCount:(NSUInteger)count {
	// create a folder called 'qstest' in the temp folder, and add 'coun't number of empty files
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *tempFolder = [NSURL fileURLWithPath:NSTemporaryDirectory()];
	NSURL *testFolder = [tempFolder URLByAppendingPathComponent:@"qstest"];
	[fileManager createDirectoryAtURL:testFolder withIntermediateDirectories:YES attributes:nil error:&error];
	XCTAssertNil(error, @"Error creating temp folder: %@", error);
	for (NSUInteger i = 0; i < count; i++) {
		NSURL *file = [testFolder URLByAppendingPathComponent:[NSString stringWithFormat:@"file%lu", (unsigned long)i]];
		[fileManager createFileAtPath:file.path contents:nil attributes:nil];
	}
	return testFolder;
}

-(void)testCatalogEntry {
	// create a new catalog entry and attempt to scan

	NSURL *testFolder = [self createTempFolderWithFileCount:5];

	NSDictionary *settings = @{@"parser": @"QSDirectoryParser",
							  @"folderDepth": @1,
							  @"scanContents": @1,
							  @"kind": @"Folder",
							  @"path": [testFolder path],
							  @"type": @""};
	NSDictionary *dict = @{@"source": @"QSFileSystemObjectSource",
						  @"settings": settings,
						  @"ID": @"QSTestCatalogEntry",
						  @"name": @"Test Catalog Entry"};
	QSCatalogEntry *entry = [[QSCatalogEntry alloc] initWithDictionary:dict];
	XCTAssertNotNil(entry, @"Catalog entry should not be nil");

	// scan the catalog entry
	NSArray *objs = [entry scannedObjects];

	// make sure there are 5 items in it
	XCTAssertEqual([objs count], 6, @"Catalog entry should have 5 items");

	
	// test and make sure these files can be stored to a shelf
	NSString *shelfPath = [[[self tmpPath] URLByAppendingPathComponent:@"test_shelf.qsshelf"] path];
	[QSLib saveObjects:objs toPath:shelfPath];

}

@end


