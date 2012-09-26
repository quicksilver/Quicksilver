//
// QSCatalogEntry.m
// Quicksilver
//
// Created by Alcor on 2/8/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSCatalogEntry.h"
#import "QSRegistry.h"
#import "QSLibrarian.h"
#import "QSResourceManager.h"
#import "QSObjectSource.h"
#import "QSNotifications.h"
#import "QSApp.h"
#import "QSTaskController.h"
#import "QSObject_PropertyList.h"
#import "NSException_TraceExtensions.h"
#import "QSTask.h"
#import <QSFoundation/QSFoundation.h>

@interface NSObject (QSCatalogSourceInformal)
- (void)enableEntry:(QSCatalogEntry *)entry;
- (void)disableEntry:(QSCatalogEntry *)entry;
@end

#define kUseNSArchiveForIndexes NO;

/*NSDictionary *entriesByID;
NSDictionary *enabledPresetDictionary;*/

@implementation QSCatalogEntry

@synthesize isSavingIndex;

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

+ (QSCatalogEntry *)entryWithDictionary:(NSDictionary *)dict {
	return [[[QSCatalogEntry alloc] initWithDictionary:dict] autorelease];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"[%@] ", [self name]];
}

- (QSCatalogEntry *)initWithDictionary:(NSDictionary *)dict {
	if (self = [super init]) {
		info = [dict mutableCopy];
		children = nil; contents = nil; indexDate = nil;

		NSArray *childDicts = [dict objectForKey:kItemChildren];
		if (childDicts) {
			NSMutableArray *newChildren = [NSMutableArray array];
			for(NSDictionary * child in childDicts) {
				[newChildren addObject:[QSCatalogEntry entryWithDictionary:child]];
			}
			children = [newChildren retain];
		}
	}
	return self;
}

- (void)enable {
	id theSource = [self source];
	if ([theSource respondsToSelector:@selector(enableEntry:)])
		[theSource enableEntry:self];
}

- (void)dealloc {
	id theSource = [self source];
	if ([theSource respondsToSelector:@selector(disableEntry:)])
		[theSource disableEntry:self];
	[indexDate release];
	[bundle release];
	[children release];
	[info release];
	[contents release];
	[super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
	if (children)
		[info setObject:[children valueForKey:@"dictionaryRepresentation"] forKey:kItemChildren];
	return info;
}

- (QSCatalogEntry *)childWithID:(NSString *)theID {
	QSCatalogEntry *child;
	for(child in children) {
		if ([[child identifier] isEqualToString:theID])
			return child;
	}
	return nil;
}

- (QSCatalogEntry *)childWithPath:(NSString *)path {
	if (![path length])
		return self;
	QSCatalogEntry *object = self;
	for(NSString *s in [path pathComponents]) {
		object = [object childWithID:s];
	}
	return object;
}

- (BOOL)isSuppressed {
#ifdef DEBUG
	return NO;
#endif
	NSString *path = [info objectForKey:@"requiresPath"];
	if (path && ![[NSFileManager defaultManager] fileExistsAtPath:[path stringByResolvingWildcardsInPath]])
		return YES;
	if ([[info objectForKey:@"requiresSettingsPath"] boolValue]) {
		path = [[info objectForKey:@"settings"] objectForKey:kItemPath];
		if (path && ![[NSFileManager defaultManager] fileExistsAtPath:[path stringByResolvingWildcardsInPath]])
			return YES;
	}
	NSString *requiredBundle = [info objectForKey:@"requiresBundle"];
	if (requiredBundle && ![[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:requiredBundle])
		return YES;
	return NO;
}

- (NSDate *)lastScanDate {
	return [[[NSFileManager defaultManager] attributesOfItemAtPath:[self indexLocation] error:nil] objectForKey:NSFileModificationDate];
}

- (BOOL)deletable {
	if ([self isPreset])
		return NO;
	return ![[info objectForKey:@"permanent"] boolValue];
}

- (BOOL)isEditable {
	id source = [self source];
	return ([source respondsToSelector:@selector(usesGlobalSettings)] && [source performSelector:@selector(usesGlobalSettings)]) ? YES : ![self isPreset];
}

- (NSString *)type {
	id source = [self source];
	NSString *theID = NSStringFromClass([source class]);
	NSString *title = [[NSBundle bundleForClass:[source class]] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
	if ([title isEqualToString:theID])
		return [[NSBundle mainBundle] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
	else
		return title;
}

- (BOOL)isCatalog { return self == [[QSLibrarian sharedInstance] catalog]; }
- (BOOL)isPreset { return [[self identifier] hasPrefix:@"QSPreset"]; }
- (BOOL)isSeparator { return [[self identifier] hasPrefix:@"QSSeparator"]; }
- (BOOL)isGroup { return [[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]; }
- (BOOL)isLeaf { return ![self isGroup]; }
- (NSInteger)state {
	BOOL enabled = [self isEnabled];
	if (!enabled) return 0;
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		for(QSCatalogEntry * child in [self deepChildrenWithGroups:NO leaves:YES disabled:YES]) {
			if (![child isEnabled]) return -1*enabled;
		}
	}
	return enabled;
}

- (NSInteger)hasEnabledChildren {
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		BOOL hasEnabledChildren = NO;
		for (id loopItem in children)
			hasEnabledChildren |= [loopItem isEnabled];
		return hasEnabledChildren;
	} else
		return YES;
}

- (BOOL)shouldIndex {
	return [self isEnabled];
}

- (BOOL)isEnabled {
	if ([self isPreset]) {
		NSNumber *value;
		if (value = [[QSLibrarian sharedInstance] presetIsEnabled:self])
			return [value boolValue];
		else if (value = [info objectForKey:kItemEnabled])
			return [value boolValue];
		// ***warning  * this is just a little silly...
		return YES;
	} else {
		return [[info objectForKey:kItemEnabled] boolValue];
	}
}

- (void)setEnabled:(BOOL)enabled {
	NSString *theID = [info objectForKey:kItemID];
	if ([theID hasPrefix:@"QSPreset"])
		[[QSLibrarian sharedInstance] setPreset:self isEnabled:enabled];
	else
		[info setObject:[NSNumber numberWithBool:enabled] forKey:kItemEnabled];
	if (enabled && ![[self contents] count]) [self scanForced:NO];
}

- (void)setDeepEnabled:(BOOL)enabled {
	[self setEnabled:enabled];
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSArray *deepChildren = [self deepChildrenWithGroups:YES leaves:YES disabled:YES];
		for(QSCatalogEntry * child in deepChildren)
			[child setEnabled:enabled];
	}
}

- (void)pruneInvalidChildren {
	NSMutableArray *children2 = [children copy];
	for(QSCatalogEntry * child in children2) {
		if ([child isSeparator]) break; //Stop when at end of presets
		if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Show All Catalog Entries"] && [child isSuppressed]) {
			
#ifdef DEBUG
			if (DEBUG_CATALOG) NSLog(@"Suppressing Preset:%@", [child identifier]);
#endif
			
			[children removeObject:child];
		} else if ([child isGroup]) {
			[child pruneInvalidChildren];
			if (![(NSArray *)[child children] count]) // Remove empty groups
				[children removeObject:child];
		}
	}
	[children2 release];
}

- (NSArray *)leafIDs {
	if (![self isEnabled]) {
		return nil;
	} else if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:1];
		for(QSCatalogEntry * child in children) {
			[childObjects addObjectsFromArray:[child leafIDs]];
		}
		return childObjects;
	} else {
		return [NSArray arrayWithObject:[self identifier]];
	}
}

- (NSArray *)leafEntries {
	return [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
}

- (NSMutableDictionary *)info {
	return info;
}

- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled {
	if (!(disabled || [self isEnabled]))
		return nil;
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:1];
		if (groups)
			[childObjects addObject:self];
		for(QSCatalogEntry * child in children) {
			[childObjects addObjectsFromArray:[child deepChildrenWithGroups:groups leaves:leaves disabled:disabled]];
		}
		return childObjects;
	} else if (leaves) {
		return [NSArray arrayWithObject:self];
	}
	return nil;
}

- (NSString *)identifier {
	NSString *ID = [info objectForKey:kItemID];
	if (!ID && [info isKindOfClass:[NSMutableDictionary class]]) {
		[(NSMutableDictionary *)info setObject:[NSString uniqueString] forKey:kItemID];
		return [info objectForKey:kItemID];
	} else
		return ID;
}

- (NSIndexPath *)catalogIndexPath {
	NSArray *anc = [self ancestors];
	NSUInteger i;
	NSUInteger index;
	NSIndexPath *p = nil;
	for (i = 0; i < ([anc count] - 1); i++) {
		index = [[[anc objectAtIndex:i] children] indexOfObject:[anc objectAtIndex:i+1]];
		p = (p) ? [p indexPathByAddingIndex:index] : [NSIndexPath indexPathWithIndex:index];
	}
	return p;
}

- (NSIndexPath *)catalogSetIndexPath {
	NSArray *anc = [self ancestors];
	NSUInteger i;
	NSUInteger index;
	NSIndexPath *p = nil;
	for (i = 1; i < ([anc count] - 1); i++) {
		index = [[[anc objectAtIndex:i] children] indexOfObject:[anc objectAtIndex:i+1]];
		p = (p) ? [p indexPathByAddingIndex:index] : [NSIndexPath indexPathWithIndex:index];
	}
	return p;
}

- (NSArray *)ancestors {
	id catalog = [[QSLibrarian sharedInstance] catalog];
	NSArray *groups = [catalog deepChildrenWithGroups:YES leaves:NO disabled:YES];
	NSMutableArray *entryChain = [NSMutableArray arrayWithCapacity:0];
	id thisItem = self;
	NSUInteger i;
	[entryChain addObject:self];
	id theGroup = nil;
	while(thisItem != catalog) {
		for (i = 0; i < [groups count]; i++) {
			theGroup = [groups objectAtIndex:i];
			if ([[theGroup children] containsObject:thisItem]) {
				[entryChain insertObject:theGroup atIndex:0];
				thisItem = theGroup;
				break;
			} else if (i == [groups count] - 1) {
				NSLog(@"couldn't find parent of %@", thisItem);
				return nil;
			}
		}
	}
	return entryChain;
}

- (NSComparisonResult) compare:(QSCatalogEntry *)other {
	return [[self name] compare:[other name]];
}

- (NSString *)name {
	NSString *ID = [self identifier];
	if ([ID isEqualToString:@"QSSeparator"])
		return @"";
	if (!name)
		name = [info objectForKey:kItemName];
	if (!name) {
		name = [bundle?bundle:[NSBundle mainBundle] safeLocalizedStringForKey:ID value:ID table:@"QSCatalogPreset.name"];
		if (name) [self setValue:name forKey:@"name"];
	}
	return name;
}

- (void)setName:(NSString *)newName {
	[info setObject:newName forKey:kItemName];
	name = newName;
}

- (id)imageAndText { return self; }

- (void)setImageAndText:(id)object { [self setName:object]; }

- (NSImage *)image { return [self icon]; }

- (NSString *)text { return [self name]; }

- (NSImage *)icon {
	NSImage *image;
	if(!(image = [QSResourceManager imageNamed:[info objectForKey:kItemIcon]])){
		if(!(image = [[QSReg sourceNamed:[info objectForKey:kItemSource]] iconForEntry:info])){
			image = [QSResourceManager imageNamed:@"Catalog"];
		}
	}
	return image;
}

- (NSString *)getCount {
	NSInteger num;
	if((num = [self count]))
		return [NSString stringWithFormat:@"%ld", (long)num];
	else
		return nil;
}

- (NSUInteger)count {
	return [self deepObjectCount];
}

- (NSUInteger)deepObjectCount {
	NSArray *leaves = [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
	NSUInteger i, count = 0;
	for (i = 0; i < [leaves count]; i++)
		count += [(NSArray *)[[leaves objectAtIndex:i] contents] count];
	return count;
}

- (NSString *)indexLocation {
	return [[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:[self identifier]] stringByAppendingPathExtension:@"qsindex"];
}

- (BOOL)loadIndex {
	if ([self isEnabled]) {
		NSString *path = [self indexLocation];
		NSMutableArray *dictionaryArray = nil;
		@try {
			dictionaryArray = [QSObject objectsWithDictionaryArray:[NSMutableArray arrayWithContentsOfFile:path]];
        }
        @catch (NSException *e) {
            NSLog(@"Error loading index of %@: %@", [self name] , e);
        }
        
        if (!dictionaryArray)        
            return NO;

        [self setContents:dictionaryArray];
        [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexed object:self];
        [[QSLibrarian sharedInstance] recalculateTypeArraysForItem:self];
	}
	return YES;
}

- (void)saveIndex {
	// If an index is currently being scanned, do not try to save it now (saving will be done once the entry has been scanned)
    if (isScanning || isSavingIndex) {
        return;
    }
    
    [self setIsSavingIndex:YES];
#ifdef DEBUG
	if (DEBUG_CATALOG) NSLog(@"saving index for %@", self);
#endif
	
	[self setIndexDate:[NSDate date]];
	NSString *key = [self identifier];
	NSString *path = [pIndexLocation stringByStandardizingPath];
   
    // Lock the 'contents' mutablearray so that it cannot be changed whilst it's being written to file
    @synchronized(contents) {
        NSArray *writeArray = [contents arrayByPerformingSelector:@selector(dictionaryRepresentation)];
        [writeArray writeToFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsindex"] atomically:YES];
    }
    [self setIsSavingIndex:NO];
}


- (void)invalidateIndex:(NSNotification *)notif {
#ifdef DEBUG
	if (VERBOSE)
		NSLog(@"Catalog Entry Invalidated: %@ (%@) %@", self, [notif object] , [notif name]);
#endif
	[self scanForced:YES];
}

- (BOOL)indexIsValid {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *indexPath = [[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:[self identifier]]stringByAppendingPathExtension:@"qsindex"];
	if (![manager fileExistsAtPath:indexPath isDirectory:nil])
		return NO;
	if (!indexDate)
		[self setIndexDate:[[manager attributesOfItemAtPath:indexPath error:NULL] fileModificationDate]];
	NSNumber *modInterval = [info objectForKey:kItemModificationDate];
	if (modInterval) {
		NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[modInterval doubleValue]];
		if ([specDate compare:indexDate] == NSOrderedDescending) return NO; //Catalog Specification is more recent than index
	}
	return [[self source] indexIsValidFromDate:indexDate forEntry:info];
}

- (id)source {
	id source = [QSReg sourceNamed:[info objectForKey:kItemSource]];
#ifdef DEBUG
	if (!source && VERBOSE)
		NSLog(@"Source not found: %@ for Entry: %@", [info objectForKey:kItemSource] , [self identifier]);
#endif
	return source;
}

- (NSArray *)scannedObjects {
    if (isScanning) {
        return nil;
    }
    NSArray *itemContents = nil;
    @autoreleasepool {
        @try {
            QSObjectSource *source = [self source];
            itemContents = [[source objectsForEntry:info] retain];
        }
        @catch (NSException *exception) {
            NSLog(@"An error ocurred while scanning \"%@\": %@", [self name], exception);
            [exception printStackTrace];
        }
    }
    return [itemContents autorelease];
}

- (BOOL)canBeIndexed {
	QSObjectSource *source = [self source];
	return ![source respondsToSelector:@selector(entryCanBeIndexed:)] || [source entryCanBeIndexed:[self info]];
}

- (NSArray *)scanAndCache {
    if (isScanning) {
#ifdef DEBUG
		if (VERBOSE) NSLog(@"%@ is already being scanned", [self name]);
#endif
		return nil;
	}
    [self setIsScanning:YES];
    NSString *ID = [self identifier];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:QSCatalogEntryIsIndexing object:self];
    NSArray *itemContents = [self scannedObjects];
    if (itemContents && ID) {
        [self setContents:itemContents];
        QSObjectSource *source = [self source];
        if (![source respondsToSelector:@selector(entryCanBeIndexed:)] || [source entryCanBeIndexed:[self info]]) {
            [self saveIndex];
        }
    } else if (ID) {
        [self setContents:nil];
    }
    [self willChangeValueForKey:@"self"];
    [self didChangeValueForKey:@"self"];
    [nc postNotificationName:QSCatalogEntryIndexed object:self];
    [self setIsScanning:NO];
    return itemContents;
}

- (void)scanForcedInThread:(NSNumber *)force {

	@autoreleasepool {
        [[[QSLibrarian sharedInstance] scanTask] startTask:nil];
        [self scanForced:[force boolValue]];
        [[[QSLibrarian sharedInstance] scanTask] stopTask:nil];
    }
}

- (NSArray *)scanForced:(BOOL)force {
	if ([self isSeparator] || ![self isEnabled]) return nil;
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
        @autoreleasepool {
            for(QSCatalogEntry * child in children) {
                [child scanForced:force];
            }
        }
		return nil;
	}
	[[[QSLibrarian sharedInstance] scanTask] setStatus:[NSString stringWithFormat:@"Checking: %@", [self name]]];
	BOOL valid = [self indexIsValid];
	if (valid && !force) {
		
#ifdef DEBUG
		if (DEBUG_CATALOG) NSLog(@"\tIndex is valid for source: %@", name);
#endif
		
		return [self contents];
	}
	
#ifdef DEBUG
	if (DEBUG_CATALOG)
		NSLog(@"Scanning source: %@%@", [self name] , (force?@" (forced) ":@""));
#endif
	
	[[[QSLibrarian sharedInstance] scanTask] setStatus:[NSString stringWithFormat:@"Scanning: %@", [self name]]];
	[self scanAndCache];
	return nil;
}

- (NSMutableArray *)children { return children; }
- (NSMutableArray *)getChildren {
	if (!children)
		children = [[NSMutableArray alloc] init];
	return children;
}
- (void)setChildren:(NSArray *)newChildren {
	if(newChildren != children){
		[children release];
		children = [newChildren mutableCopy];
	}
}

- (NSArray *)contents { return [self contentsScanIfNeeded:NO]; }
- (NSArray *)_contents { return contents; }
- (void)setContents:(NSArray *)newContents {
	if(newContents != contents){
		[contents release];
		contents = [newContents mutableCopy];
	}
}

- (NSArray *)contentsScanIfNeeded:(BOOL)canScan {
	if (![self isEnabled]) {
		return nil;
	}
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSMutableSet *childObjects = [NSMutableSet setWithCapacity:1];

		for(QSCatalogEntry * child in children) {
			[childObjects addObjectsFromArray:[child contentsScanIfNeeded:(BOOL)canScan]];
		}
		return [childObjects allObjects];

	} else {

		if (!contents && canScan)
			return [self scanAndCache];
		return contents;
	}
}


- (QSCatalogEntry *)uniqueCopy {
	NSMutableDictionary *newDictionary = [[info mutableCopy] autorelease];
	if ([self isPreset]) {
		[newDictionary setObject:[NSNumber numberWithBool:[self isEnabled]] forKey:kItemEnabled];
		[newDictionary setObject:[self name] forKey:kItemName];
	}
	[newDictionary setObject:[NSString uniqueString] forKey:kItemID];

	QSCatalogEntry *newEntry = [[QSCatalogEntry alloc] initWithDictionary:newDictionary];
	if ([self children])
		[newEntry setChildren:[[self children] valueForKey:@"uniqueCopy"]];

	return [newEntry autorelease];
}

- (NSDate *)indexDate { return indexDate;  }
- (void)setIndexDate:(NSDate *)anIndexDate {
	//	NSLog(@"date %@ ->%@", indexDate, anIndexDate);
	[indexDate release];
	indexDate = [anIndexDate retain];
}

- (BOOL)isScanning { return isScanning;  }
- (void)setIsScanning:(BOOL)flag {
	isScanning = flag;
}

@end
