//
//  QSCatalogEntry.h
//  Quicksilver
//
//  Created by Alcor on 2/8/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSCatalogEntry : NSObject

@property (readonly, getter=isScanning) BOOL scanning;
@property (readonly, getter=isSuppressed) BOOL suppressed;
@property (readonly, getter=isPreset) BOOL preset;
@property (readonly, getter=isSeparator) BOOL separator;


@property (strong, atomic, getter=_contents) NSArray *contents;

+ (QSCatalogEntry *)entryWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (QSCatalogEntry *)initWithDictionary:(NSDictionary *)dict;
- (QSCatalogEntry *)childWithID:(NSString *)theID;
- (QSCatalogEntry *)childWithPath:(NSString *)path;
- (BOOL)isGroup;
- (BOOL)isEditable;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (NSInteger)state;
- (NSInteger)hasEnabledChildren;
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

- (NSUInteger)count;
- (NSIndexPath *)catalogSetIndexPath;
@end
