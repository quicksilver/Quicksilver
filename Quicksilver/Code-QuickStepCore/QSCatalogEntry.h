//
//  QSCatalogEntry.h
//  Quicksilver
//
//  Created by Alcor on 2/8/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSCatalogEntry : NSObject

@property (assign, atomic) BOOL isScanning;


@property (strong, atomic, getter=_contents) NSArray *contents;

+ (QSCatalogEntry *)entryWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (QSCatalogEntry *)initWithDictionary:(NSDictionary *)dict;
- (QSCatalogEntry *)childWithID:(NSString *)theID;
- (QSCatalogEntry *)childWithPath:(NSString *)path;
- (BOOL)isSuppressed;
- (BOOL)isPreset;
- (BOOL)isSeparator;
- (BOOL)isGroup;
- (BOOL)isEditable;
- (NSInteger) state;
- (NSInteger) hasEnabledChildren;
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
- (NSUInteger) deepObjectCount;
- (BOOL)loadIndex;
- (void)saveIndex;
- (BOOL)indexIsValid;
- (void)invalidateIndex:(NSNotification *)notif;

- (BOOL)isCatalog;
- (id)source;
- (BOOL)canBeIndexed;
- (NSArray *)scannedObjects;
- (NSArray *)scanAndCache;
- (void)scanForced:(BOOL)force;
- (NSMutableArray *)children;
- (NSMutableArray *)getChildren;
- (NSArray *)contents;
- (NSArray *)contentsScanIfNeeded:(BOOL)canScan;
- (void)setContents:(NSArray *)newContents;
- (NSArray *)enabledContents;
- (NSIndexPath *)catalogIndexPath;
- (NSMutableDictionary *)info;
- (QSCatalogEntry *)uniqueCopy;
- (NSString *)indexLocation;
- (void)setName:(NSString *)newName;

- (NSDate *)indexDate;
- (void)setIndexDate:(NSDate *)anIndexDate;
- (BOOL)isScanning;
- (void)setIsScanning:(BOOL)flag;
//- (NSString *)countString;

- (NSUInteger) count;
- (NSIndexPath *)catalogSetIndexPath;
@end
