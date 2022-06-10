//
// QSCatalogEntry.m
// Quicksilver
//
// Created by Alcor on 2/8/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import <QSFoundation/QSFoundation.h>
#import "QSCatalogEntry.h"
#import "QSCatalogEntry_Private.h"
#import "QSRegistry.h"
#import "QSLibrarian.h"
#import "QSResourceManager.h"
#import "QSObjectSource.h"
#import "QSNotifications.h"
#import "QSApp.h"
#import "QSTaskController.h"
#import "QSObject_PropertyList.h"
#import "QSTask.h"

#define kUseNSArchiveForIndexes NO;

NSString *const QSCatalogEntryChangedNotification = @"QSCatalogEntryChanged";
NSString *const QSCatalogEntryIsIndexingNotification = @"QSCatalogEntryIsIndexing";
NSString *const QSCatalogEntryIndexedNotification = @"QSCatalogEntryIndexed";
NSString *const QSCatalogEntryInvalidatedNotification = @"QSCatalogEntryInvalidated";

@interface QSCatalogEntry () {
    NSString *_name;
    NSArray *_contents;
    NSImage *_icon;
    QSObjectSource *_source;

	NSMutableArray *_children;
    dispatch_queue_t scanQueue;
}

@property (getter=isScanning) BOOL scanning;
@property (retain) NSArray *contents;
@property (retain) NSMutableArray *children;

- (NSString *)indexLocation;

@end

@implementation QSCatalogEntry

+ (BOOL)accessInstanceVariablesDirectly {return YES;}

+ (QSCatalogEntry *)entriesWithArray:(NSArray *)array { return nil; }

// KVO
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"deepObjectCount"]) {
        NSSet *affectingKeys = [NSSet setWithObjects:@"contents", @"enabled",nil];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKeys];
    } else if ([key isEqualToString:@"currentEntry"]) {
        keyPaths = [keyPaths setByAddingObject:@"selection"];
    } else if ([key isEqualToString:@"self"] ) {
        keyPaths = [keyPaths setByAddingObject:@"count"];
    }
    return keyPaths;
}


+ (instancetype)entryWithDictionary:(NSDictionary *)dict {
	return [[QSCatalogEntry alloc] initWithDictionary:dict];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"[%@] ", self.name];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _children = [NSMutableArray array];
    _info = [NSMutableDictionary dictionary];
    _info[kItemID] = [NSString uniqueString];

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
	if (!self) {
        return nil;
    }

    _info = [dict mutableCopy];
    NSDictionary *settings = _info[kItemSettings];
    if (settings)
        _info[kItemSettings] = settings.mutableCopy;

    NSArray *childDicts = dict[kItemChildren];
    if (childDicts) {
        NSMutableArray *newChildren = [NSMutableArray arrayWithCapacity:childDicts.count];
        for (NSDictionary *child in childDicts) {
            [newChildren addObject:[QSCatalogEntry entryWithDictionary:child]];
        }
        self.children = newChildren;
    }

    // create a serial dispatch queue to make scan processes serial for each catalog entry
    scanQueue = dispatch_queue_create([[NSString stringWithFormat:@"QSCatalogEntry scanQueue: %@",[dict objectForKey:kItemID]] UTF8String], NULL);
    dispatch_queue_set_specific(scanQueue, kQueueCatalogEntry, (__bridge void *)self, NULL);

	return self;
}

- (void)enable {
    /* This is a bit of a misnomer.
     * It doesn't actually "enable" the entry (as in add the entry to the catalog)
     * but actually means "your object source can start listening for whatever it needs to listen to"
     * Currently this is only used by the "watch" option to the FSObjectSource, but this *is* the
     * dawn of an answer to the asynchronous loading of catalog entries.
     * Called by -[QSLibrarian enableEntries]
     */
	if ([self.source respondsToSelector:@selector(enableEntry:)]) {
		[self.source enableEntry:self];
    }
}

- (void)dealloc {
	if ([self.source respondsToSelector:@selector(disableEntry:)]) {
		[self.source disableEntry:self];
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = self.info.mutableCopy;
	if (self.children) {
		dict[kItemChildren] = [self.children valueForKey:@"dictionaryRepresentation"];
    }
	return dict;
}

- (QSCatalogEntry *)childWithID:(NSString *)theID {
	for (QSCatalogEntry *child in self.children) {
		if ([child.identifier isEqualToString:theID]) {
			return child;
        }
	}
	return nil;
}

- (QSCatalogEntry *)childWithPath:(NSString *)path {
	if (path.length == 0) {
		return self;
    }

	QSCatalogEntry *object = self;
	for (NSString *s in path.pathComponents) {
		object = [object childWithID:s];
	}
	return object;
}

- (BOOL)isSuppressed {
	NSString *path = self.info[@"requiresPath"];
	if (path && ![NSFileManager.defaultManager fileExistsAtPath:path.stringByResolvingWildcardsInPath]) {
		return YES;
    }
	if ([self.info[@"requiresSettingsPath"] boolValue]) {
		path = self.info[kItemSettings][kItemPath];
		if (path && ![NSFileManager.defaultManager fileExistsAtPath:path.stringByResolvingWildcardsInPath]) {
			return YES;
        }
	}
	NSString *requiredBundle = self.info[@"requiresBundle"];
	if (requiredBundle && ![NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:requiredBundle]) {
		return YES;
    }
	return NO;
}

- (NSDate *)lastScanDate {
	return self.indexationDate;
}

- (NSDate *)indexationDate {
	if (self.isGroup) {
		// It's a group entry. Loop through the child catalog entries to find the one with the latest scan date
		NSDate *latestIndexDate = nil;
		for (QSCatalogEntry *child in [self children]) {
			NSDate *childIndexDate = [child indexationDate];
            if (childIndexDate && ([childIndexDate compare:latestIndexDate] == NSOrderedDescending || latestIndexDate == nil)) {
				latestIndexDate = childIndexDate;
			}
		}
		return latestIndexDate;
	}
	return [[NSFileManager.defaultManager attributesOfItemAtPath:self.indexLocation error:NULL] objectForKey:NSFileModificationDate];
}

- (NSDate *)modificationDate {
	id modDate = self.info[kItemModificationDate];
	if (!modDate) return nil;
	return [NSDate dateWithTimeIntervalSinceReferenceDate:[(NSNumber *)modDate doubleValue]];
}

- (BOOL)canBeDeleted {
	if (self.isPreset) {
        return NO;
    }

	return ![self.info[@"permanent"] boolValue];
}

- (BOOL)isEditable {
    if ([self.source respondsToSelector:@selector(usesGlobalSettings)]
        && [self.source performSelector:@selector(usesGlobalSettings)]) {
        return YES;
    }

    return !self.isPreset;
}

- (NSString *)localizedType {
	NSString *theID = NSStringFromClass([self.source class]);
	NSString *title = [[NSBundle bundleForClass:[self.source class]] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
	if ([title isEqualToString:theID]) {
		return [[NSBundle mainBundle] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
	} else {
		return title;
    }
}

- (BOOL)isCatalog { return self == [[QSLibrarian sharedInstance] catalog]; }
- (BOOL)isPreset { return [self.identifier hasPrefix:@"QSPreset"]; }
- (BOOL)isSeparator { return [self.identifier hasPrefix:@"QSSeparator"]; }
- (BOOL)isGroup { return [self.info[kItemSource] isEqualToString:@"QSGroupObjectSource"]; }
- (BOOL)isLeaf { return !self.isGroup; }

- (NSInteger)state {
	BOOL enabled = self.isEnabled;
	if (!enabled) return 0;
	if (self.isGroup) {
		for (QSCatalogEntry *child in [self deepChildrenWithGroups:NO leaves:YES disabled:YES]) {
			if (!child.isEnabled) {
                return -1*enabled;
            }
		}
	}
	return enabled;
}

- (BOOL)hasEnabledChildren {
	if (self.isGroup) {
		BOOL hasEnabledChildren = NO;
		for (QSCatalogEntry *child in self.children)
			hasEnabledChildren |= child.isEnabled;
		return hasEnabledChildren;
	}

    return YES;
}

- (BOOL)shouldIndex {
	return self.isEnabled;
}

- (BOOL)isEnabled {
    @synchronized (self) {
        if (self.isPreset) {
            /* Check our enabled state, defaulting to YES if not defined yet. */
            NSNumber *value = [[QSLibrarian sharedInstance] presetIsEnabled:self];
            return (value != nil ? value.boolValue : YES);
        }

        NSNumber *value = self.info[kItemEnabled];
        return (value != nil ? value.boolValue : YES);
    }
}

- (void)setEnabled:(BOOL)enabled {
    @synchronized (self) {
        if (self.isPreset) {
            [[QSLibrarian sharedInstance] setPreset:self isEnabled:enabled];
        } else {
            self.info[kItemEnabled] = @(enabled);
            if (enabled && self.contents.count == 0) {
                [self scanForced:YES];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:self];
	if (enabled && [self.source respondsToSelector:@selector(enableEntry:)]) {
		[self.source enableEntry:self];
    } else if (!enabled && [self.source respondsToSelector:@selector(disableEntry:)]) {
		[self.source disableEntry:self];
	}
}

- (void)setDeepEnabled:(BOOL)enabled {
	self.enabled = enabled;
	if (self.isGroup) {
		NSArray *deepChildren = [self deepChildrenWithGroups:YES leaves:YES disabled:YES];
		for (QSCatalogEntry *child in deepChildren) {
			child.enabled = enabled;
        }
	}
}

- (void)pruneInvalidChildren {
    /* Do a "manual" reverse enumeration because we'd be mutating-while-enumerating
     * and we don't want our index to move around. */
    NSIndexSet *prunedChildren = [self.children indexesOfObjectsPassingTest:^BOOL(QSCatalogEntry *child, NSUInteger idx, BOOL *stop) {
        if (!child.isPreset) {
            /* Prune presets only */
            return NO;
        }

        if (child.isSuppressed && ![NSUserDefaults.standardUserDefaults boolForKey:@"Show All Catalog Entries"]) {
#ifdef DEBUG
			if (DEBUG_CATALOG) NSLog(@"Suppressing Preset:%@", child.identifier);
#endif
            return TRUE;
        } else if (child.isGroup) {
            [child pruneInvalidChildren];
            return child.children.count == 0;
        }
        return NO;
    }];
    [self.children removeObjectsAtIndexes:prunedChildren];
}

- (NSArray *)leafIDs {
	if (!self.isEnabled) {
        return @[];
    }

	if (self.isGroup) {
		NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:1];
		for (QSCatalogEntry *child in self.children) {
			[childObjects addObjectsFromArray:[child leafIDs]];
		}
		return childObjects;
    }

    return @[self.identifier];
}

- (NSArray *)leafEntries {
	return [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
}

- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled {
	if (!self.isEnabled && !disabled) {
        return @[];
    }

	if (self.isGroup) {
		NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:1];
		if (groups)
			[childObjects addObject:self];

		for (QSCatalogEntry *child in self.children) {
			[childObjects addObjectsFromArray:[child deepChildrenWithGroups:groups leaves:leaves disabled:disabled]];
		}
		return childObjects;
	}

    if (!leaves) {
        return @[];
	}

    return @[self];
}

- (NSString *)identifier {
    @synchronized (self) {
        NSString *ID = self.info[kItemID];
        if (!ID) {
            ID = [NSString uniqueString];
            self.info[kItemID] = ID;
        }
        return ID;
    }
}

- (NSIndexPath *)catalogIndexPath {
	NSArray *anc = self.ancestors;
	NSUInteger i;
	NSUInteger index;
	NSIndexPath *p = nil;
	for (i = 0; i < (anc.count - 1); i++) {
		index = [[anc[i] children] indexOfObject:anc[i + 1]];
		p = (p) ? [p indexPathByAddingIndex:index] : [NSIndexPath indexPathWithIndex:index];
	}
	return p;
}

- (NSIndexPath *)catalogSetIndexPath {
    NSArray *anc = self.ancestors;
    NSUInteger i;
    NSUInteger index;
    NSIndexPath *p = nil;
    for (i = 1; i < (anc.count - 1); i++) {
        index = [[anc[i] children] indexOfObject:anc[i+1]];
        p = (p) ? [p indexPathByAddingIndex:index] : [NSIndexPath indexPathWithIndex:index];
    }
    return p;
}

- (NSArray *)ancestors {
	QSCatalogEntry *catalog = [QSLibrarian.sharedInstance catalog];
	NSArray *groups = [catalog deepChildrenWithGroups:YES leaves:NO disabled:YES];
	NSMutableArray *entryChain = [NSMutableArray arrayWithCapacity:0];
	QSCatalogEntry *thisItem = self;
	QSCatalogEntry *theGroup = nil;
	NSUInteger i;

	[entryChain addObject:self];
	while (thisItem != catalog) {
		for (i = 0; i < groups.count; i++) {
			theGroup = groups[i];
			if ([theGroup.children containsObject:thisItem]) {
				[entryChain insertObject:theGroup atIndex:0];
				thisItem = theGroup;
				break;
			} else if (i == groups.count - 1) {
				NSLog(@"couldn't find parent of %@", thisItem);
				return nil;
			}
		}
	}
	return entryChain;
}

- (NSComparisonResult) compare:(QSCatalogEntry *)other {
    if (other.name != nil) {
        return [self.name compare:other.name];
    }
    // other.name is nil, so make the receiver higher in the list
    return NSOrderedAscending;
}

- (NSString *)name {
    @synchronized (self) {
        if (self.isSeparator) {
            return @"";
        }

		if (_name) return _name;

		/* FIXME: this is tampering with localization
		 * A better way would be to have separate keys for plugin-provided names
		 * vs user-customized ones
		 */

		// The default list of bundles to check
		NSSet *bundles = [NSSet setWithObjects:
						  [NSBundle bundleForClass:[self.source class]],
						  [NSBundle bundleWithIdentifier:@"com.blacktree.Quicksilver.QSCorePlugIn"],
						  [NSBundle mainBundle],
						  nil];
		if (self.isPreset) {
			for (NSBundle *bundle in bundles) {
				_name = [bundle safeLocalizedStringForKey:self.identifier value:nil table:@"QSCatalogPreset.name"];
				if (_name) break;
			}
			if (!_name) {
#ifdef DEBUG
				if (DEBUG_LOCALIZATION)
					NSLog(@"Missing localized name for preset entry %@", self.identifier);
#endif
				_name = self.info[kItemName];
			}
		} else {
			NSString *sourceString = NSStringFromClass([self.source class]);
			for (NSBundle *bundle in bundles) {
				_name = [bundle safeLocalizedStringForKey:sourceString value:nil table:@"QSObjectSource.name"];
				if (_name) break;
			}

			if (self.info[kItemName]) {
				// This is (supposedly) a user-customized name
				_name = self.info[kItemName];
			}

		}

        return [_name copy];
    }
}

- (void)setName:(NSString *)newName {
    @synchronized (self) {
        _name = [newName copy];
        self.info[kItemName] = _name;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:self];
}

- (id)imageAndText { return self; }

- (void)setImageAndText:(id)object { self.name = object; }

- (NSImage *)image { return self.icon; }

- (NSString *)text { return self.name; }

- (NSImage *)icon {
    @synchronized (self) {
        _icon = [QSResourceManager imageNamed:self.info[kItemIcon]];
        if (!_icon) {
            _icon = [self.source iconForEntry:self];
        }

        if (!_icon)
            _icon = [QSResourceManager imageNamed:@"Catalog"];

		/* FIXME: tiennou: must check that this actually works */
        NSData *iconData = self.info[@"iconData"];
        if (!_icon && iconData) {
            _icon = [[NSImage alloc] initWithData:iconData];
        }

        return _icon;
    }
}

- (void)setIcon:(NSImage *)icon {
    @synchronized (self) {
        if (icon) {
            if (_icon.name) {
                self.info[kItemIcon] = icon.name;
            } else {
                self.info[@"iconData"] = [icon TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0];
            }
        }
        _icon = icon;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:self];
}

- (NSString *)getCount {
	NSInteger num;
	if((num = [self count]))
		return [NSString stringWithFormat:@"%ld", (long)num];
	else
		return nil;
}

- (NSUInteger)count {
	return self.deepObjectCount;
}

- (NSUInteger)deepObjectCount {
	NSArray *leaves = [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
	NSUInteger i, count = 0;

	for (i = 0; i < leaves.count; i++) {
		QSCatalogEntry *leaf = leaves[i];
		count += leaf.enabledContents.count;
	}

	return count;
}

- (NSString *)indexLocation {
	return [[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:self.identifier] stringByAppendingPathExtension:@"qsindex"];
}

- (BOOL)loadIndex {
	if (self.isEnabled) {
		NSMutableArray *dictionaryArray = nil;
		@try {
			dictionaryArray = [QSObject objectsWithDictionaryArray:[NSMutableArray arrayWithContentsOfFile:self.indexLocation]];
        }
        @catch (NSException *e) {
            NSLog(@"Error loading index of %@: %@", self.name , e);
        }

        if (!dictionaryArray) {
            return NO;
        }

        [self setContents:dictionaryArray];
        [NSNotificationCenter.defaultCenter postNotificationName:QSCatalogEntryIndexedNotification object:self];
        [QSLibrarian.sharedInstance recalculateTypeArraysForItem:self];
	}
	return YES;
}

- (void)saveIndex {
    QSGCDQueueSync(scanQueue, ^{
#ifdef DEBUG
        if (DEBUG_CATALOG) NSLog(@"saving index for %@", self);
#endif

        @try {
            NSArray *writeArray = [self.contents arrayByPerformingSelector:@selector(dictionaryRepresentation)];
            [writeArray writeToFile:self.indexLocation atomically:YES];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception whilst saving catalog entry %@\ncontents: %@\nException: %@", self.name, self.contents, exception);
        }
    });
}


- (void)invalidateIndex:(NSNotification *)notif {
#ifdef DEBUG
	if (VERBOSE)
		NSLog(@"Catalog Entry Invalidated: %@ (%@) %@", self, [notif object] , [notif name]);
#endif
	[self scanForced:YES];
}

- (BOOL)indexIsValid {
	if (self.isScanning) {
		return YES;
	}
    __block BOOL isValid = YES;
    QSGCDQueueSync(scanQueue, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIsIndexingNotification object:self];
        NSFileManager *manager = NSFileManager.defaultManager;
        NSString *indexLocation = self.indexLocation;
        if (![manager fileExistsAtPath:indexLocation isDirectory:nil]) {
            isValid = NO;
        }
        if (isValid) {
            if ([self.modificationDate compare:self.indexationDate] == NSOrderedDescending) {
                isValid = NO; //Catalog Specification is more recent than index
            }
        }
        if (isValid) {
            isValid = [self.source indexIsValidFromDate:self.indexationDate forEntry:self];
        }
    });
    return isValid;
}

- (QSObjectSource *)source {
    @synchronized (self) {
        if (!_source) {
            _source = [QSReg sourceNamed:self.info[kItemSource]];
#ifdef DEBUG
            if (!_source && VERBOSE)
                NSLog(@"Source not found: %@ for Entry: %@", self.info[kItemSource], self.identifier);
#endif
        }
        return _source;

    }
}

- (NSArray *)scannedObjects {
    NSArray *itemContents = nil;
    @autoreleasepool {
        @try {
            itemContents = [self.source objectsForEntry:self];
        }
        @catch (NSException *exception) {
            NSLog(@"An error occurred while scanning \"%@\": %@", self.name, exception);
            [exception printStackTrace];
        }
    }
    return itemContents;
}

- (BOOL)canBeIndexed {
    if ([self.source respondsToSelector:@selector(entryCanBeIndexed:)]) {
        return [self.source entryCanBeIndexed:self];
    }

    // Otherwise all entries can be indexed
    return YES;
}

- (NSArray *)scanAndCache {
    if (self.isScanning) {
#ifdef DEBUG
		if (VERBOSE) NSLog(@"%@ is already being scanned", self.name);
#endif
		return nil;
	} else {
        __block NSArray *itemContents = nil;
		self.scanning = YES;
        QSGCDQueueSync(scanQueue, ^{
			// Use a serial queue to do the actual scanning. Ensures that a catalog entry cannot be scanned multiple times at the same time.
            itemContents = [self scannedObjects];
		});
		[self willChangeValueForKey:@"self"];
		NSString *ID = self.identifier;
		if (itemContents && ID) {
			self.contents = itemContents;
			if (self.canBeIndexed) {
				[self saveIndex];
			}
		} else if (ID) {
			self.contents = nil;
		}
		[self didChangeValueForKey:@"self"];
		self.scanning = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexedNotification object:self];
		return itemContents;
    }
}

- (void)scanForced:(BOOL)force {
    if (self.isSeparator || !self.isEnabled) {
        return;
    }

    if (self.isGroup) {
        @autoreleasepool {
            for(QSCatalogEntry *child in self.children) {
                [child scanForced:force];
            }
        }
        return;
    }
    BOOL valid = [self indexIsValid];
    if (valid && !force) {
#ifdef DEBUG
        if (DEBUG_CATALOG) NSLog(@"\tIndex is valid for source: %@", self.name);
#endif
        return;
    }

#ifdef DEBUG
    if (DEBUG_CATALOG)
        NSLog(@"Scanning source: %@%@", self.name , (force?@" (forced) ":@""));
#endif

    [self scanAndCache];
}

- (NSArray *)contents {
    @synchronized (self) {
        return [self contentsScanIfNeeded:NO];
    }
}

- (void)setContents:(NSArray *)newContents {
    @synchronized (self) {
        _contents = [newContents copy];
    }
}

- (NSArray *)contentsScanIfNeeded:(BOOL)canScan {
    @synchronized (self) {
        if (!self.isEnabled) return nil;

        if (self.isGroup) {
            NSMutableSet *childObjects = [NSMutableSet setWithCapacity:1];

            for (QSCatalogEntry *child in self.children) {
                [childObjects addObjectsFromArray:[child contentsScanIfNeeded:canScan]];
            }
            return [childObjects allObjects];
        }

        if (!_contents && canScan)
            return [self scanAndCache];

        return _contents;
    }
}

- (NSArray *)enabledContents
{
    NSIndexSet *enabled = [[self contents] indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *obj, NSUInteger idx, BOOL *stop) {
        return ![QSLib itemIsOmitted:obj];
    }];
    return [[self contents] objectsAtIndexes:enabled];
}

- (void)refresh:(BOOL)rescan {
    self.info[kItemModificationDate] = @([NSDate timeIntervalSinceReferenceDate]);
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:self];
    if (rescan) [self scanAndCache];
}

- (QSCatalogEntry *)uniqueCopy {
	NSMutableDictionary *newDictionary = [self.info mutableCopy];
	if (self.isPreset) {
		newDictionary[kItemEnabled] = @(self.isEnabled);
#warning this is tampering with localization
		newDictionary[kItemName] = self.name;
	}
	newDictionary[kItemID] = [NSString uniqueString];

	QSCatalogEntry *newEntry = [[QSCatalogEntry alloc] initWithDictionary:newDictionary];
	if (self.children)
		newEntry.children = [self.children valueForKey:@"uniqueCopy"];

	return newEntry;
}

- (NSMutableDictionary *)sourceSettings {
    NSMutableDictionary *settings = self.info[kItemSettings];
    if (!settings) {
        settings = [[NSMutableDictionary alloc] init];
        self.info[kItemSettings] = settings;
    }
    return settings;
}


// Backward-compatibility
- (BOOL)deletable QS_DEPRECATED { return self.canBeDeleted; }

@end

@implementation QSCatalogEntry (OldStyleSourceSupport)

- (id)objectForKey:(NSString *)key {
	return self.info[key];
}

@end
