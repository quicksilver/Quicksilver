//
//  QSCatalogEntry.h
//  Quicksilver
//
//  Created by Alcor on 2/8/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSCatalogEntry : NSObject {
	NSDate *indexDate;
	BOOL isPreset;

	NSString *name;

	id parent;
	NSMutableArray *children;

	NSMutableDictionary *info;
	NSMutableArray *contents;
	NSBundle *bundle;
	BOOL isScanning;
}

+ (QSCatalogEntry *)entryWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (QSCatalogEntry *)initWithDictionary:(NSDictionary *)dict;
- (void)dealloc;
- (NSDictionary *)dictionaryRepresentation;
- (QSCatalogEntry *)childWithID:(NSString *)theID;
- (QSCatalogEntry *)childWithPath:(NSString *)path;
- (BOOL)isRestricted;
- (BOOL)isSuppressed;
- (BOOL)isPreset;
- (BOOL)isSeparator;
- (BOOL)isGroup;
- (int) state;
- (int) hasEnabledChildren;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (void)setDeepEnabled:(BOOL)enabled;
- (void)pruneInvalidChildren;
- (NSArray *)leafIDs;
- (NSArray *)leafEntries;
- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled;
- (NSString *)identifier;
- (NSArray *)ancestors;
- (NSString *)name;
- (NSImage *)icon;
- (int) deepObjectCount;
- (BOOL)loadIndex;
- (void)saveIndex;
- (BOOL)indexIsValid;
- (BOOL)isCatalog;
- (id)source;
- (BOOL)canBeIndexed;
- (NSArray *)scannedObjects;
- (NSArray *)scanAndCache;
- (NSArray *)scanForced:(BOOL)force;
- (NSMutableArray *)children;
- (NSMutableArray *)getChildren;
- (NSArray *)contents;
- (NSArray *)contentsScanIfNeeded:(BOOL)canScan;
- (void)setContents:(NSArray *)newContents;
- (NSIndexPath *)catalogIndexPath;
- (NSMutableDictionary *)info;
- (QSCatalogEntry *)uniqueCopy;
- (NSString *)indexLocation;
- (void)setName:(NSString *)newName;

- (NSDate *)indexDate;
- (void)setIndexDate:(NSDate *)anIndexDate;
- (NSArray *)_contents;
- (NSMutableDictionary *)info;
- (BOOL)isScanning;
- (void)setIsScanning:(BOOL)flag;
//- (NSString *)countString;

- (int) count;
- (NSIndexPath *)catalogSetIndexPath;
@end
