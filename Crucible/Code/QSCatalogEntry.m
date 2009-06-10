//
//  QSCatalogEntry.m
//  Quicksilver
//
//  Created by Alcor on 2/8/05.

//

#import "QSCatalogEntry.h"


#import "QSLibrarian.h"

#import "QSResourceManager.h"
#import "QSObjectSource.h"
#import "QSNotifications.h"
//#import "QSApp.h"
#import "QSTaskController.h"
#import "QSObject_PropertyList.h"

#import "NSException_TraceExtensions.h"
#import "QSTask.h"

@interface NSObject (QSCatalogSourceInformal)
- (void)enableEntry:(QSCatalogEntry *)entry;
- (void)disableEntry:(QSCatalogEntry *)entry;
@end

BOOL gUseNSArchiveForIndexes = NO;

NSDictionary *entriesByID;

NSDictionary *enabledPresetDictionary;

@implementation QSCatalogEntry

+ (BOOL)accessInstanceVariablesDirectly {return YES;}

+ (QSCatalogEntry *)entriesWithArray:(NSArray *)array {
	return nil;
}
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
	if ((self = [super init])) {
		info = [dict retain];
		children = nil;
		contents = nil;
		indexDate = nil;
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
	if ([[self source] respondsToSelector:@selector(enableEntry:)])
		[[self source] enableEntry:self]; 	
}
- (void)dealloc {
	if ([[self source] respondsToSelector:@selector(disableEntry:)])
		[[self source] disableEntry:self];
	
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
		if ([[child identifier] isEqualToString:theID]) return child;
	}
	return nil;
}

- (QSCatalogEntry *)childWithPath:(NSString *)path {
	if (![path length]) return self;
	
	NSEnumerator *e = [[path pathComponents] objectEnumerator];
	NSString *s;
	QSCatalogEntry *object = self;
	while((s = [e nextObject])) {
		object = [object childWithID:s];
	}
	return object;
}



- (BOOL)isRestricted {
	if (isRestricted) return YES;
	if (DEBUG) return NO;
	//	if (self == catalog) return NO;
	
	NSString *sourceType = [info objectForKey:kItemSource];
  
  id source = [QSReg sourceNamed:sourceType];
  
  
	if ([sourceType isEqualToString:@"QSGroupObjectSource"] || source) {
		isRestricted = [NSApp featureLevel] <[[info objectForKey:kItemFeatureLevel] intValue];
		return isRestricted;
	}
	isRestricted = YES;
	return isRestricted;
}

- (BOOL)isSuppressed {
	if (DEBUG) return NO;
	//if (self == catalog) return NO;
	
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
	if ([self isPreset]) return NO;
	return ![[info objectForKey:@"permanent"] boolValue];
}
- (BOOL)isEditable {
	id source = [self source];
	if ([source respondsToSelector:@selector(usesGlobalSettings)] && [source performSelector:@selector(usesGlobalSettings)])
		return YES;
	return ![self isPreset];
}
- (NSString *)type {
	id source = [self source];
	NSString *theID = NSStringFromClass([source class]);
	
	NSString *title = [[NSBundle bundleForClass:[source class]]safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
	if ([title isEqualToString:theID]) title = [[NSBundle mainBundle] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
	return title;
}
- (BOOL)isCatalog {return self == [QSLib catalog];}
- (BOOL)isPreset {return [[self identifier] hasPrefix:@"QSPreset"];}
- (BOOL)isSeparator {return [[self identifier] hasPrefix:@"QSSeparator"];}
- (BOOL)isGroup {return [[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"];}
- (BOOL)isLeaf {return ![self isGroup];}
- (int) state {
	BOOL enabled = [self isEnabled];
	if (!enabled) return 0;
	
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) { 
		foreach(child, [self deepChildrenWithGroups:NO leaves:YES disabled:YES]) {
			if (![child isEnabled]) return -1*enabled;
		}
	}
	return enabled;
}


- (int) hasEnabledChildren {
	BOOL hasEnabledChildren = NO;
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) { 
		for (id loopItem in children)
			hasEnabledChildren |= [loopItem isEnabled];
	}
	return hasEnabledChildren;
}
- (BOOL)shouldIndex {
	return [self isEnabled]; 	
}
- (BOOL)isEnabled {
	//if (self == catalog) return YES;
	
	if ([self isRestricted])
		return NO;
	//NSString *theID = [self identifier];
	if ([self isPreset]) {
		NSNumber *value = nil;
		if ((value = [QSLib presetIsEnabled:self]))
			return [value boolValue];
		if ((value = [info objectForKey:kItemEnabled]))
			return [value boolValue];  
		// ***warning   * this is just a little silly...
		
		return YES;
	}
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
	//	if (!self) self = catalog;
	//NSMutableArray *children = [info objectForKey:kItemChildren];
	NSMutableArray *children2 = [[children copy] autorelease];
	foreach(child, children2) {
		if ([child isSeparator]) return; //Stop when at end of presets
		if ([child isRestricted]) {
			if (DEBUG_CATALOG) QSLog(@"Disabling Preset:%@", [child identifier]);
			[children removeObject:child];
		} else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Show All Catalog Entries"] && [child isSuppressed]) {
			if (DEBUG_CATALOG) QSLog(@"Suppressing Preset:%@", [child identifier]);
			[children removeObject:child];
			
		} else if ([child isGroup]) {
			[child pruneInvalidChildren];
			if (![(NSArray *)[child children] count]) // Remove empty groups
				[children removeObject:child];
		}
	}
}

- (NSArray *)leafIDs {
	if (![self isEnabled]) {
		return nil;
	} else if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) { 
		NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:1];
		//NSArray *children = [info objectForKey:kItemChildren];
		foreach(child, children) {
			[childObjects addObjectsFromArray:[child leafIDs]];
		}
		return childObjects;
	} else {
		return [NSArray arrayWithObject:[self identifier]];
		
	}
}

- (NSArray *)leafEntries {
	//QSLog(@"deep %@", self);
	return [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
}

- (NSMutableDictionary *)info {
	return info;
}

- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled {
	//	if (!self) self = catalog;
	
	if (!disabled && ![self isEnabled]) return nil;
	
	
	
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) { 
		NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:1];
		if (groups) [childObjects addObject:self];
		foreach(child, children) {
			[childObjects addObjectsFromArray:[child deepChildrenWithGroups:groups leaves:leaves disabled:disabled]];
		}
		//	QSLog(@"deep %@ %d", self, [childObjects count]);
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
		ID = [info objectForKey:kItemID];
	}
	return ID;
}

- (NSIndexPath *)catalogIndexPath {
	
	NSArray *anc = [self ancestors];
	int i;
	int index;
	NSIndexPath *p = nil;
	for (i = 0; i<([anc count] -1); i++) {
		index = [[[anc objectAtIndex:i] children] indexOfObject:[anc objectAtIndex:i+1]];
		if (!p)
			p = [NSIndexPath indexPathWithIndex:index];
		else
			p = [p indexPathByAddingIndex:index];
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
		if (!p)
			p = [NSIndexPath indexPathWithIndex:index];
		else
			p = [p indexPathByAddingIndex:index];
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
			}
			if (i == [groups count] -1) {
				QSLog(@"couldn't find parent of %@", thisItem);
				return nil;
			}
		}
	}
	//		QSLog(@"anc %@", entryChain); 	
	return entryChain;
}

- (NSComparisonResult) compare:(QSCatalogEntry *)other {
	return [[self name] compare:[other name]]; 	
}

- (NSString *)name {
	NSString *ID = [self identifier];
	if (!name)
		name = [info objectForKey:kItemName];
	//QSLog(@"bundle %@", [info objectForKey:@"bundle"]);
	if ([ID isEqualToString:@"QSSeparator"]) return @"";
	//NSBundle *bundle = [info objectForKey:@"bundle"];
	//if (!bundle) bundle = [NSBundle mainBundle];
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

- (id)imageAndText {return self;}

- (void)setImageAndText:(id)object {[self setName:object];}

- (id)this {return [[self retain] autorelease];}

- (NSImage *)image {
	return [self icon];
}

- (NSString *)text {
	return [self name]; 	
}

- (NSImage *)icon {
	NSImage *image = [QSResourceManager imageNamed:[info objectForKey:kItemIcon]];
	if (!image) {
		id source = [QSReg sourceNamed:[info objectForKey:kItemSource]];
		image = [source iconForEntry:info];
	}
	
	if (!image) {
		image = [QSResourceManager imageNamed:@"Catalog"];
		//	[image createIconRepresentations];
	}
	return image;
}

- (int) count {
	return [self deepObjectCount]; 	
}

- (int) deepObjectCount {
	NSArray *leaves = [self deepChildrenWithGroups:NO leaves:YES disabled:NO];
	int count = 0;
	for (id loopItem in leaves)
		count += [[loopItem contents] count];
	return count;
}

- (NSString *)countString {
	int num = [self count];
	if (!num) return nil;
	return [NSString stringWithFormat:@"%d", num];
}

- (NSString *)indexLocation {
	NSString *path = [pIndexLocation stringByStandardizingPath];
	path = [path stringByAppendingPathComponent:[self identifier]];
	return [path stringByAppendingPathExtension:@"qsindex"];
}

- (BOOL)loadIndex {
	//NSString *theID = [info objectForKey:kItemID];
	if ([self isEnabled]) {
		NSString *path = [self indexLocation];
		
		NSMutableArray *dictionaryArray = nil;
		NS_DURING
			
			if (gUseNSArchiveForIndexes) {
				dictionaryArray = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
			} else {
				dictionaryArray = [NSMutableArray arrayWithContentsOfFile:path];
				dictionaryArray = [QSObject objectsWithDictionaryArray:dictionaryArray];
			}
			
			NS_HANDLER
				QSLog(@"Error loading index of %@: %@", [self name] , localException);
			NS_ENDHANDLER
			if (dictionaryArray) {
				[self setContents:dictionaryArray];
			} else {
				return NO;
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexed object:self];
			
			[QSLib recalculateTypeArraysForItem:self];
	}
		
		return YES;
}

- (void)writeContentsToCache {
    NSString *path = nil;
    
    for (QSObject *item in [self contents]) {
        if ([item isKindOfClass:NSClassFromString(@"QSProxyObject")]) continue; // Don't write proxies
        if ([item singleFilePath]) continue; // Don't write real files
        
        if (!path) {
            path = [pIndexLocation stringByDeletingLastPathComponent];
            path = [path stringByAppendingPathComponent:@"Contents"];
            
            path = [path stringByStandardizingPath];
            path = [path stringByAppendingPathComponent:[self identifier]]; 	
            [[NSFileManager defaultManager] createDirectoriesForPath:path];
        }
        
        NSString *thisName = [item.name stringByAppendingPathExtension:@"qs"];
        
        thisName = [thisName stringByReplacing:@"/" with:@"_"];
        thisName = [thisName stringByReplacing:@":" with:@"_"];
        NSString *thisPath = [path stringByAppendingPathComponent:thisName];
        [[item dictionaryRepresentation] writeToFile:thisPath atomically:YES];
    }
}

- (void)saveIndex {
	if (DEBUG_CATALOG) QSLog(@"saving index for %@", self);
	[self setIndexDate:[NSDate date]];
	NSString *key = [self identifier];
	//NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = [pIndexLocation stringByStandardizingPath];
	
	if (gUseNSArchiveForIndexes) {
		[NSKeyedArchiver archiveRootObject:[self contents]  toFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsindex"]];
	} else {
		NSArray *dictionaryArray = [[self contents] arrayByPerformingSelector:@selector(dictionaryRepresentation)];
		[dictionaryArray writeToFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsindex"] atomically:YES];
	}
	
  [self writeContentsToCache];
	//	QSLog(@"Stored");
}


- (void)invalidateIndex:(NSNotification *)notif {
	if (VERBOSE)
		QSLog(@"Catalog Entry Invalidated: %@ (%@) %@", self, [notif object] , [notif name]); 	
	//[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogSourceInvalidated object:NSStringFromClass([self class])];
	[self scanForced:YES];
}

- (BOOL)indexIsValid {
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *indexPath = [[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:[self identifier]]stringByAppendingPathExtension:@"qsindex"];
	if (![manager fileExistsAtPath:indexPath isDirectory:nil]) return NO;
	if (!indexDate) [self setIndexDate:[[manager fileAttributesAtPath:indexPath traverseLink:NO] fileModificationDate]];
	NSNumber *modInterval = [info objectForKey:kItemModificationDate];
	if (modInterval) {
		NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[modInterval floatValue]];
		if ([specDate compare:indexDate] == NSOrderedDescending) return NO; //Catalog Specification is more recent than index
	}
	BOOL valid = [[self source] indexIsValidFromDate:indexDate forEntry:info];
	//	[taskController removeTask:@"Checking"];
	return valid;
}
- (id)source {
	id source = [QSReg sourceNamed:[info objectForKey:kItemSource]];
	if (!source && VERBOSE)
		QSLogDebug(@"Source not found: %@ for Entry: %@", [info objectForKey:kItemSource] , [self identifier]);
	return source;
} ;

- (NSArray *)scannedObjects {
	if (isScanning) {
		if (VERBOSE) QSLog(@"%@ is already being scanned", [self name]);
		return nil;
	}
	isScanning = YES;
	[self setIsScanning:YES];
	NSArray *itemContents = nil;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@try {
		QSObjectSource *source = [self source];
		itemContents = [[source objectsForEntry:info] retain];
	}
  @catch(id localException) {
		NSString *errorMessage = [NSString stringWithFormat:@"An error ocurred while scanning \"%@\": %@", [self name] , localException];
		if (0 && DEBUG) NSRunAlertPanel(@"Scan Error", errorMessage, nil, nil, nil);
		else QSLog(errorMessage);
		[localException printStackTrace];
  }
	[pool release];
  
	[self setIsScanning:NO];
	return [itemContents autorelease];
}


- (BOOL)canBeIndexed {
	QSObjectSource *source = [self source];
	return ![source respondsToSelector:@selector(entryCanBeIndexed:)] || [source entryCanBeIndexed:[self info]];
}

- (void)updateItemContents {
  NSArray *itemContents = [self scannedObjects];
  [self setContents:itemContents];
}

- (NSArray *)scanAndCache {
	NSString *ID = [self identifier];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIsIndexing object:self];
	
  
  QSObjectSource *source = [self source];
  //QSLogDebug(@"scanning %@ on main thread %d", self, [source respondsToSelector:@selector(scanInMainThread)]);
  
  if ([source respondsToSelector:@selector(shouldScanOnMainThread)] && [source shouldScanOnMainThread]) {
    QSLogDebug(@"scanning %@ on main thread", self);
    [self performSelectorOnMainThread:@selector(updateItemContents) withObject:nil waitUntilDone:YES];
  } else {
    [self updateItemContents];
  }
  
  if (contents && ID) {
    if (![source respondsToSelector:@selector(entryCanBeIndexed:)] || [source entryCanBeIndexed:[self info]]) {
      [self saveIndex];
    }
  }
  
		[self willChangeValueForKey:@"self"];
  
    [self didChangeValueForKey:@"self"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexed object:self];
    
    return contents;
}
- (void)scanForcedInThread:(BOOL)force {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[QSLib scanTask] startTask:nil];
	[self scanForced:force];
	[[QSLib scanTask] stopTask:nil];
	[pool release];
}

- (NSArray *)scanForced:(BOOL)force {
	
	if ([self isSeparator]) return nil;
	if (![self isEnabled]) return nil;
	
  //	QSTaskController *taskController = [QSTaskController sharedInstance];
	if ([[info objectForKey:kItemSource] isEqualToString:@"QSGroupObjectSource"]) {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		foreach(child, children) {
			[child scanForced:force];
		}
		[pool release];
		//if (theEntry == catalog) [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogIndexed object:nil];
		return nil;
	}
  
	[[QSLib scanTask] setStatus:[NSString stringWithFormat:@"Checking:%@", name]];
	
	BOOL valid = [self indexIsValid];
	if (valid && !force) {
		if (DEBUG_CATALOG) QSLog(@"\tIndex is valid for source: %@", name);
		
		return [self contents];
	}
	if (DEBUG_CATALOG) 
		QSLog(@"Scanning source: %@%@", [self name] , (force?@" (forced) ":@""));
  
	[[QSLib scanTask] setStatus:[NSString stringWithFormat:@"Scanning:%@", name]];
  
	[self scanAndCache];
	
	return nil;
}

- (NSMutableArray *)children {return [[children retain] autorelease];}


- (NSMutableArray *)getChildren {
	if (!children)
		children = [[NSMutableArray alloc] init];
	return children;
}


- (void)setChildren:(NSArray *)newChildren {
  [children autorelease];
  children = [newChildren retain];
}

- (NSArray *)contents { return [self contentsScanIfNeeded:NO];  }
- (NSArray *)_contents {
	return contents; 	
}
- (void)setContents:(NSArray *)newContents {
  [contents autorelease];
  contents = [newContents retain];
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

- (NSDate *)indexDate { return [[indexDate retain] autorelease];  }
- (void)setIndexDate:(NSDate *)anIndexDate
{
	//	QSLog(@"date %@ ->%@", indexDate, anIndexDate);
	[indexDate release];
	indexDate = [anIndexDate retain];
}


- (BOOL)isScanning { return isScanning;  }
- (void)setIsScanning:(BOOL)flag
{
  isScanning = flag;
}

@end
