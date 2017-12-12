//
//  QSCatalogEntry.h
//  Quicksilver
//
//  Created by Alcor on 2/8/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QSObjectSource;


extern NSString *const QSCatalogEntryChangedNotification;
extern NSString *const QSCatalogEntryIsIndexingNotification;
extern NSString *const QSCatalogEntryIndexedNotification;
extern NSString *const QSCatalogEntryInvalidatedNotification;

/**
 * QSCatalogEntry represent an entry in Quicksilver's catalog.
 *
 * It is built as tree of QSCatalogEntry, each having both `children` (more
 * entries) and `contents` (as a list of `QSObject`s.
 * It is also responsible for scanning its contents regularly, using one of the
 * QSObjectSources provided by QS or a plugin.
 */
@interface QSCatalogEntry : NSObject

////////////////////////////////////////////////////////////////////////////////
/// @name Properties
////////////////////////////////////////////////////////////////////////////////

/** Is the receiver scanning ? */
@property (readonly, getter=isScanning) BOOL scanning;

/** Is the receiver suppressed ? */
@property (readonly, getter=isSuppressed) BOOL suppressed;

/** Is the receiver a default preset ? */
@property (readonly, getter=isPreset) BOOL preset;

/** Is the receiver a separator ? */
@property (readonly, getter=isSeparator) BOOL separator;

/** Is the receiver a group of more entries ? */
@property (readonly, getter=isGroup) BOOL group;

/** Is the receiver modifiable ? */
@property (readonly, getter=isEditable) BOOL editable;

/** Can the receiver be indexed ? */
@property (readonly, getter=canBeIndexed) BOOL indexable;

/** Is the receiver enabled ? */
@property (getter=isEnabled) BOOL enabled;

/** The receiver's displayable name. */
@property (copy) NSString *name;

/** The receiver's icon. */
@property (retain) NSImage *icon;

/** The receiver's identifier. */
@property (readonly, copy) NSString *identifier;

/** The receiver's localized type. */
@property (readonly, copy) NSString *localizedType;

/** The receiver's source. */
@property (readonly, retain) QSObjectSource *source;

/** The receiver's last indexation date. */
@property (readonly, retain) NSDate *indexationDate;

/** The receiver's last modification date. */
@property (readonly, retain) NSDate *modificationDate;

/** The contents of the receiver. */
@property (readonly, retain) NSArray *contents;

/** The subentries of the receiver. */
@property (readonly, retain) NSMutableArray *children;

/** The settings for the receiver's object source. */
@property (readonly, retain) NSMutableDictionary *sourceSettings;

////////////////////////////////////////////////////////////////////////////////
/// @name Lifetime
////////////////////////////////////////////////////////////////////////////////

/**
 * Create a new instance of the receiver from a dictionary.
 *
 * @param dict A serialized entry as a dictionary.
 *
 * @see -[QSCatalogEntry initWithDictionary:].
 */
+ (instancetype)entryWithDictionary:(NSDictionary *)dict;

/**
 * Initialize the receiver from a dictionary.
 *
 * @param dict A dictionary containing
 *
 * @return A newly instantiated entry, or nil.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/**
 * Serialize the receiver to a dictionary.
 *
 * @warning This is an implementation detail. You should either use the
 * receiver's properties, or the private info dictionary.
 */
- (NSDictionary *)dictionaryRepresentation;

////////////////////////////////////////////////////////////////////////////////
/// @name Basic methods
////////////////////////////////////////////////////////////////////////////////

/**
 * Get the receiver's children with the given identifier.
 *
 * @param theID The identifier to lookup.
 *
 * @return An instance of QSCatalogEntry, or nil if there was no children with
 * the given identifier.
 */
- (instancetype)childWithID:(NSString *)theID;

/**
 * Get one of the receiver's children given an "identifier path".
 *
 * @param path A slash-separated string of entry identifiers.
 *
 * @return An instance of QSCatalogEntry, or nil if one of the identifiers in
 * the path wasn't valid.
 */
- (instancetype)childWithPath:(NSString *)path;

/** Make a new unique copy of the receiver */
- (instancetype)uniqueCopy;

/*
 * The state the receiver is in.
 *
 * Depending on whether the receiver is a group or not, returns either its
 * enabled state, or a negative number whose value represents the number of
 * enabled leaf entries.
 */
- (NSInteger)state;

/** Is any of receiver's children enabled ? */
- (BOOL)hasEnabledChildren;

/**
 * Enable or disable the receiver and all its children
 *
 * @param enabled Whether to enable or disable the children.
 */
- (void)setDeepEnabled:(BOOL)enabled;

/**
 * Prune all invalid children.
 *
 * If the receiver's a preset entry, this will recursively remove all children
 * which have no contents.
 */
- (void)pruneInvalidChildren;

/**
 * Get the receiver's identifiers for its leaves.
 *
 * @return An array of all the enabled leaves's identifiers for the receiver.
 */
- (NSArray *)leafIDs;

/**
 * Get the receiver's enabled leaves.
 *
 * @return An array of all the enabled leaves for the receiver.
 */
- (NSArray *)leafEntries;

/**
 * Get the receiver's children.
 *
 * @param groups If YES, the resulting array will contain groups.
 * @param leaves If YES, the resulting array will contain leaves.
 * @param disabled If YES, the resulting array will contain disabled entries.
 *
 * @return An array of all the receiver's children matching the given options.
 */
- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled;

/**
 * Get the ancestors for the receiver.
 *
 * @return An array of the receiver's ancestor chain, starting with the root.
 */
- (NSArray *)ancestors;

/** Get the number of objects contained by the receiver and all its children. */
- (NSUInteger)deepObjectCount;

/** Same as deepObjectCount */
- (NSUInteger)count;

/** Returns whether the receiver is the root catalog entry. */
- (BOOL)isCatalog;

- (NSIndexPath *)catalogIndexPath;

- (NSIndexPath *)catalogSetIndexPath;

/**
 * Get only the non-ommited objects from that entry and its children
 */
- (NSArray *)enabledContents;

////////////////////////////////////////////////////////////////////////////////
/// @name Indexing
////////////////////////////////////////////////////////////////////////////////

/** Load the receiver's index. */
- (BOOL)loadIndex;

/** Save the receiver's index. */
- (void)saveIndex;

/** Returns whether the index of the receiver is valid. */
- (BOOL)indexIsValid;

////////////////////////////////////////////////////////////////////////////////
/// @name Scanning
////////////////////////////////////////////////////////////////////////////////

/**
 * Get the objects scanned by the receiver's object source.
 *
 * @warning This bypasses the index and the receiver's object cache. You should
 * rarely need to call that method.
 *
 * @return An array of all object that the receiver's object source generated.
 */
- (NSArray *)scannedObjects;

/**
 * Scan the receiver and refresh its cache.
 *
 * This queries the receiver's source for objects and refresh the index.
 *
 * @warning If the receiver's already being scanned, this *will* return nil.
 *
 * @return An array of all the objects generated by the object source.
 */
- (NSArray *)scanAndCache;

/**
 * Scan the receiver.
 *
 * @param force If YES, the current index will be ignored.
 */
- (void)scanForced:(BOOL)force;

- (NSArray *)contentsScanIfNeeded:(BOOL)canScan;

/**
 * Mark the entry as refreshed/modified.
 *
 * @param rescan If YES, the entry will be rescanned immediately.
 */
- (void)refresh:(BOOL)rescan;

/* FIXME: Yuck! */
- (void)invalidateIndex:(NSNotification *)notif;
@end
