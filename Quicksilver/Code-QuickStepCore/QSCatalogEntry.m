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

+ (BOOL)accessInstanceVariablesDirectly {return YES;}

+ (QSCatalogEntry *)entriesWithArray:(NSArray *)array { return nil; }

+ (void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"contents"] triggerChangeNotificationsForDependentKey:@"deepObjectCount"];
	[self setKeys:[NSArray arrayWithObject:@"enabled"] triggerChangeNotificationsForDependentKey:@"deepObjectCount"];
	[self setKeys:[NSArray arrayWithObject:@"selection"] triggerChangeNotificationsForDependentKey:@"currentEntry"];
	[self setKeys:[NSArray arrayWithObject:@"count"] triggerChangeNotificationsForDependentKey:@"self"];
}

+ (QSCatalogEntry *)entryWithDictionary:(NSDictionary *)dict {
	return [[(QSCatalogEntry *)[QSCatalogEntry alloc] initWithDictionary:dict] autorelease];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"[%@] ", [self name]];
}

- (QSCatalogEntry *)initWithDictionary:(NSDictionary *)dict {
	if (self = [super init]) {
		info = [dict retain];
		children = nil; contents = nil; indexDate = nil;

		NSArray *childDicts = [dict objectForKey:kItemChildren];
		if (childDicts) {
			NSMutableArray *newChildren = [NSMutableArray array];
			foreach(child, childDicts) {
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
	NSEnumerator *e = [children objectEnumerator];
	QSCatalogEntry *child;
	while(child = [e nextObject]) {
		if ([[child identifier] isEqualToString:theID])
			return child;
	}
	return nil;
}

- (QSCatalogEntry *)childWithPath:(NSString *)path {
	if (![path length])
		return self;
	NSEnumerator *e = [[path pathComponents] objectEnumerator];
	NSString *s;
	QSCatalogEntry *object = self;
	while(s = [e nextObject]) {
		object = [object childWithID:s];
	}
	return object;
}



- (BOOL)isRestricted {
	if (DEBUG)
		return NO;
	NSString *sourceType = [info objectForKey:kItemSource];
	if ([sourceType isEqualToString:@"QSGroupObjectSource"] || [QSReg sourceNamed:sourceType])
		return [NSApp featureLevel] < [[info objectForKey:kItemFeatureLevel] intValue];
	return YES;
}

- (BOOL)isSuppressed {
	if (DEBUG)
		return NO;
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
	return [[[NSFileManager defaultManager] fileAttributesAtPath:[self indexLocation] traverseLink:YES] objectForKey:NSFileModificationDate];
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

- (BOOL)isCatalog { return self == [QSLib catalog]; }
- (BOOL)isPreset { return [[self identifier] hasPrefix:@"QSPreset"]; }
- (BOOL)isSeparator { return [[self identifier] hasPrefix:@"QSSeparator"]; }
- (BOOL)isGroup { return [[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]; }
- (BOOL)isLeaf { return ![self isGroup]; }
- (int)state {
	BOOL enabled = [self isEnabled];
	if (!enabled) return 0;
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		foreach(child, [self deepChildrenWithGroups:NO leaves:YES disabled:YES]) {
			if (![child isEnabled]) return -1*enabled;
		}
	}
	return enabled;
}

- (int)hasEnabledChildren {
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		BOOL hasEnabledChildren = NO;
		int i;
		for (i = 0; i<[children count]; i++)
			hasEnabledChildren |= [[children objectAtIndex:i] isEnabled];
		return hasEnabledChildren;
	} else
		return YES;
}

- (BOOL)shouldIndex {
	return [self isEnabled];
}

- (BOOL)isEnabled {
	if ([self isRestricted])
		return NO;
	else if ([self isPreset]) {
		NSNumber *value;
		if (value = [QSLib presetIsEnabled:self])
			return [value boolValue];
		else if (value = [info objectForKey:kItemEnabled])
			return [value boolValue];
		// ***warning  * this is just a little silly...
		return YES;
	} else
		return [[info objectForKey:kItemEnabled] boolValue];
}

- (void)setEnabled:(BOOL)enabled {
	NSString *theID = [info objectForKey:kItemID];
	if ([theID hasPrefix:@"QSPreset"])
		[QSLib setPreset:self isEnabled:enabled];
	else
		[info setObject:[NSNumber numberWithBool:enabled] forKey:kItemEnabled];
	if (enabled && ![[self contents] count]) [self scanForced:NO];
}

- (void)setDeepEnabled:(BOOL)enabled {
	[self setEnabled:enabled];
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSArray *deepChildren = [self deepChildrenWithGroups:YES leaves:YES disabled:YES];
		foreach(child, deepChildren)
			[(QSCatalogEntry*)child setEnabled:enabled];
	}
}

- (void)pruneInvalidChildren {
	NSMutableArray *children2 = [children copy];
	foreach(child, children2) {
		if ([child isSeparator]) return; //Stop when at end of presets
		if ([child isRestricted]) {
			if (DEBUG_CATALOG) NSLog(@"Disabling Preset:%@", [child identifier]);
			[children removeObject:child];
		} else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Show All Catalog Entries"] && [child isSuppressed]) {
			if (DEBUG_CATALOG) NSLog(@"Suppressing Preset:%@", [child identifier]);
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
		foreach(child, children) {
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
		foreach(child, children) {
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
	int i;
	int index;
	NSIndexPath *p = nil;
	for (i = 0; i < ([anc count]-1); i++) {
		index = [[[anc objectAtIndex:i] children] indexOfObject:[anc objectAtIndex:i+1]];
		p = (p) ? [p indexPathByAddingIndex:index] : [NSIndexPath indexPathWithIndex:index];
/*		if (!p)
			p = [NSIndexPath indexPathWithIndex:index];
		else
			p = [p indexPathByAddingIndex:index];*/
	}
	return p;
}

- (NSIndexPath *)catalogSetIndexPath {
	NSArray *anc = [self ancestors];
	int i;
	int index;
	NSIndexPath *p = nil;
	for (i = 1; i<([anc count] -1); i++) {
		index = [[[anc objectAtIndex:i] children] indexOfObject:[anc objectAtIndex:i+1]];
		p = (p) ? [p indexPathByAddingIndex:index] : [NSIndexPath indexPathWithIndex:index];
/*		if (!p)
			p = [NSIndexPath indexPathWithIndex:index];
		else
			p = [p indexPathByAddingIndex:index];*/
	}
	return p;
}

- (NSArray *)ancestors {
	id catalog = [QSLib catalog];
	NSArray *groups = [catalog deepChildrenWithGroups:YES leaves:NO disabled:YES];
	NSMutableArray *entryChain = [NSMutableArray arrayWithCapacity:0];
	id thisItem = self;
	int i;
	[entryChain addObject:self];
	id theGroup = nil;
	while(thisItem != catalog) {
		for(i = 0; i<[groups count]; i++) {
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

- (id)this { return self; /*[[self retain] autorelease];*/ }

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
	int num;
	if((num = [self count]))
		return [NSString stringWithFormat:@"%d", num];
	else
		return nil;
}

- (int)count {
	return [self deepObjectCount];
}

- (int)deepObjectCount {
	NSArray *leaves = [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
	int i, count = 0;
	for (i = 0; i<[leaves count]; i++)
		count += [[[leaves objectAtIndex:i] contents] count];
	return count;
}

- (NSString *)indexLocation {
	return [[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:[self identifier]] stringByAppendingPathExtension:@"qsindex"];
}

- (BOOL)loadIndex {
	if ([self isEnabled]) {
		NSString *path = [self indexLocation];
		NSMutableArray *dictionaryArray = nil;
		NS_DURING
#if 0
if(kUseNSArchiveForIndexes)
	dictionaryArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
else
#endif
			dictionaryArray = [QSObject objectsWithDictionaryArray:[NSMutableArray arrayWithContentsOfFile:path]];
		NS_HANDLER
			NSLog(@"Error loading index of %@: %@", [self name] , localException);
		NS_ENDHANDLER

			if (dictionaryArray)
				[self setContents:dictionaryArray];
			else
				return NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexed object:self];
			[QSLib recalculateTypeArraysForItem:self];
	}
	return YES;
}

- (void)saveIndex {
	if (DEBUG_CATALOG) NSLog(@"saving index for %@", self);
	[self setIndexDate:[NSDate date]];
	NSString *key = [self identifier];
	NSString *path = [pIndexLocation stringByStandardizingPath];
#if 0
if (kUseNSArchiveForIndexes)
	[NSKeyedArchiver archiveRootObject:[self contents] toFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsindex"]];
	else
#endif
	[[[self contents] arrayByPerformingSelector:@selector(archiveDictionary)] writeToFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsindex"] atomically:YES];
}


- (void)invalidateIndex:(NSNotification *)notif {
	if (VERBOSE)
		NSLog(@"Catalog Entry Invalidated: %@ (%@) %@", self, [notif object] , [notif name]);
	[self scanForced:YES];
}

- (BOOL)indexIsValid {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *indexPath = [[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:[self identifier]]stringByAppendingPathExtension:@"qsindex"];
	if (![manager fileExistsAtPath:indexPath isDirectory:nil])
		return NO;
	if (!indexDate)
		[self setIndexDate:[[manager fileAttributesAtPath:indexPath traverseLink:NO] fileModificationDate]];
	NSNumber *modInterval = [info objectForKey:kItemModificationDate];
	if (modInterval) {
		NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[modInterval floatValue]];
		if ([specDate compare:indexDate] == NSOrderedDescending) return NO; //Catalog Specification is more recent than index
	}
	return [[self source] indexIsValidFromDate:indexDate forEntry:info];
}

- (id)source {
	id source = [QSReg sourceNamed:[info objectForKey:kItemSource]];
	if (!source && VERBOSE)
		NSLog(@"Source not found: %@ for Entry: %@", [info objectForKey:kItemSource] , [self identifier]);
	return source;
}

- (NSArray *)scannedObjects {
	if (isScanning) {
		if (VERBOSE) NSLog(@"%@ is already being scanned", [self name]);
		return nil;
	} else {
		[self setIsScanning:YES];
		NSArray *itemContents = nil;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NS_DURING
			QSObjectSource *source = [self source];
			itemContents = [[source objectsForEntry:info] retain];
		NS_HANDLER
			NSLog(@"An error ocurred while scanning \"%@\": %@", [self name], localException);
			[localException printStackTrace];
		NS_ENDHANDLER
		[pool release];
		[self setIsScanning:NO];
		return [itemContents autorelease];
	}
}

- (BOOL)canBeIndexed {
	QSObjectSource *source = [self source];
	return ![source respondsToSelector:@selector(entryCanBeIndexed:)] || [source entryCanBeIndexed:[self info]];
}

- (NSArray *)scanAndCache {
	NSString *ID = [self identifier];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:QSCatalogEntryIsIndexing object:self];
	NSArray *itemContents = [self scannedObjects];
		if (itemContents && ID) {
		[self setContents:itemContents];
		QSObjectSource *source = [self source];
		if (![source respondsToSelector:@selector(entryCanBeIndexed:)] || [source entryCanBeIndexed:[self info]]) {
			[self saveIndex];
		} else {
			//	NSLog(@"not caching %@", [self name]);
		}
	} else if (ID) {
		[self setContents:nil]; //[catalogArrays removeObjectForKey:ID];
	}
	[self willChangeValueForKey:@"self"];
	[self didChangeValueForKey:@"self"];
	[nc postNotificationName:QSCatalogEntryIndexed object:self];
	return itemContents;
}

- (void)scanForcedInThread:(BOOL)force {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[QSLib scanTask] startTask:nil];
	[self scanForced:force];
	[[QSLib scanTask] stopTask:nil];
	[pool release];
}

- (NSArray *)scanForced:(BOOL)force {
	if ([self isSeparator] || ![self isEnabled]) return nil;
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		foreach(child, children) {
			[child scanForced:force];
		}
		[pool release];
		return nil;
	}
	[[QSLib scanTask] setStatus:[NSString stringWithFormat:@"Checking:%@", name]];
	BOOL valid = [self indexIsValid];
	if (valid && !force) {
		if (DEBUG_CATALOG) NSLog(@"\tIndex is valid for source: %@", name);
		return [self contents];
	}
	if (DEBUG_CATALOG)
		NSLog(@"Scanning source: %@%@", [self name] , (force?@" (forced) ":@""));
	[[QSLib scanTask] setStatus:[NSString stringWithFormat:@"Scanning:%@", name]];
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
		children = [newChildren retain];
	}
}

- (NSArray *)contents { return [self contentsScanIfNeeded:NO]; }
- (NSArray *)_contents { return contents; }
- (void)setContents:(NSArray *)newContents {
	if(newContents != contents){
		[contents release];
		contents = [newContents retain];
	}
}

- (NSArray *)contentsScanIfNeeded:(BOOL)canScan {
	if (![self isEnabled]) {
		return nil;
	}
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		NSMutableSet *childObjects = [NSMutableSet setWithCapacity:1];

		foreach(child, children) {
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


	QSCatalogEntry *newEntry = [QSCatalogEntry entryWithDictionary:newDictionary];
	if ([self children])
		[newEntry setChildren:[[self children] valueForKey:@"uniqueCopy"]];

	return newEntry;
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
