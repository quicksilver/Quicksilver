//
//  QSCatalogEntry.h
//  Quicksilver
//
//  Created by Alcor on 2/8/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QSObjectSource;

@interface QSCatalogEntry : NSObject

@property (readonly, getter=isScanning) BOOL scanning;
@property (readonly, getter=isSuppressed) BOOL suppressed;
@property (readonly, getter=isPreset) BOOL preset;
@property (readonly, getter=isSeparator) BOOL separator;
@property (readonly, getter=isGroup) BOOL group;
@property (readonly, getter=isEditable) BOOL editable;
@property (readonly, getter=canBeIndexed) BOOL indexable;

@property (getter=isEnabled) BOOL enabled;

@property (copy) NSString *name;
@property (readonly, retain) NSImage *icon;
@property (readonly, copy) NSString *identifier;
@property (readonly, retain) QSObjectSource *source;
@property (retain) NSDate *indexDate;

@property (readonly, retain) NSArray *contents;
@property (readonly, retain) NSMutableArray *children;

+ (instancetype)entryWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)childWithID:(NSString *)theID;
- (instancetype)childWithPath:(NSString *)path;

- (instancetype)uniqueCopy;

- (NSInteger)state;
- (NSInteger)hasEnabledChildren;
- (void)setDeepEnabled:(BOOL)enabled;
- (void)pruneInvalidChildren;

- (NSArray *)leafIDs;
- (NSArray *)leafEntries;
- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled;
- (NSArray *)ancestors;
- (NSUInteger) deepObjectCount;
- (BOOL)loadIndex;
- (void)saveIndex;
- (BOOL)indexIsValid;
- (BOOL)isCatalog;
- (NSArray *)scannedObjects;
- (NSArray *)scanAndCache;
- (void)scanForced:(BOOL)force;
- (NSArray *)contentsScanIfNeeded:(BOOL)canScan;
- (NSIndexPath *)catalogIndexPath;
- (NSMutableDictionary *)info;

- (NSUInteger)count;
- (NSIndexPath *)catalogSetIndexPath;
@end
