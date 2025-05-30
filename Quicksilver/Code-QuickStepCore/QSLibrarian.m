#import "QSLibrarian.h"
#import "QSMnemonics.h"
#import "QSNotifications.h"

#import "QSPreferenceKeys.h"
#import "QSExecutor.h"
#import "QSObject.h"
#import "QSObject_PropertyList.h"

#import "QSApp.h"
#import "QSTask.h"

#import "QSTaskController.h"
#import "QSCatalogEntry.h"
#import "QSCatalogEntry_Private.h"

//#define compGT(a, b) (a < b)

CGFloat QSMinScore = 0.333333;

QSLibrarian *QSLib = nil;

#ifdef DEBUG
static CGFloat searchSpeed = 0.0;
#endif

@interface QSLibrarian ()

@property (retain) QSTask *scanTask;
@end

@implementation QSLibrarian

+ (id)sharedInstance {
	if (!QSLib) QSLib = [[[self class] allocWithZone:nil] init];
	
	return QSLib;
}

+ (void)createDirectories {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = [pIndexLocation stringByStandardizingPath];
	if (![manager fileExistsAtPath:path isDirectory:nil]) [manager createDirectoriesForPath:path];
	path = [pShelfLocation stringByStandardizingPath];
	if (![manager fileExistsAtPath:path isDirectory:nil]) [manager createDirectoriesForPath:path];
}
+ (void)removeIndexes {
	[[NSFileManager defaultManager] removeItemAtPath:[pIndexLocation stringByStandardizingPath] error:nil];
	[self createDirectories];
}
- (void)loadDefaultCatalog {
	//	[self setCatalog:[NSMutableDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Catalog" ofType:@"plist"]]];
}

- (id)init {
	if (self = [super init]) {
        // Set a BOOL to ensure nothing attempts to access the catalog until it's fully loaded
        catalogLoaded = NO;
		scanning_queue = dispatch_queue_create("quicksilver.qslibrarian.scanning", DISPATCH_QUEUE_SERIAL);
		NSNumber *minScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSMinimumScore"];
		if (minScore) {
			QSMinScore = [minScore doubleValue];
			NSLog(@"Minimum Score set to %f", QSMinScore);
		}
		[QSLibrarian createDirectories];
		enabledPresetsDictionary = [[NSMutableDictionary alloc] init];
		_objectDictionary = [[NSMutableDictionary alloc] init];

		//Initialize Variables
		appSearchArrays = nil;
		entriesBySource = [[NSMutableDictionary alloc] initWithCapacity:1];
        
		omittedIDs = nil;
		entriesByID = [[NSMutableDictionary alloc] initWithCapacity:1];
		[self setShelfArrays:[NSMutableDictionary dictionaryWithCapacity:1]];
		[self setCatalogArrays:[NSMutableDictionary dictionaryWithCapacity:1]];

		NSDictionary *modulesEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Plugins", kItemName,
			@"QSPlugIn", kItemIcon,
			@"QSPresetModules", kItemID,
			@"QSGroupObjectSource", kItemSource,
			[NSMutableArray array] , kItemChildren,
			[NSNumber numberWithBool:YES] , kItemEnabled, nil];

#ifdef DEBUG
		if ((NSInteger) getenv("QSDisableCatalog") || GetCurrentKeyModifiers() & shiftKey) {
			NSLog(@"Disabling Catalog");
		} else {
#endif
			[self setCatalog:[QSCatalogEntry entryWithDictionary:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"QSCATALOGROOT", kItemName, @"QSGroupObjectSource", kItemSource, [NSMutableArray arrayWithObjects:modulesEntry, nil] , kItemChildren, [NSNumber numberWithBool:YES] , kItemEnabled, nil]]];
#ifdef DEBUG
		}
#endif

		// Register for Notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogEntryChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogStructureChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadIDDictionary:) name:QSCatalogStructureChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSets:) name:QSCatalogEntryIndexedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSource:) name:QSCatalogSourceInvalidated object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadEntry:) name:QSCatalogEntryInvalidatedNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScanTask:) name:QSCatalogEntryIsIndexingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScanTask:) name:QSCatalogEntryIndexedNotification object:nil];
#if 0
		//Create proxy Images
		[(NSImage *)[[NSImage alloc] initWithSize:NSZeroSize] setName:@"QSDirectProxyImage"];
		[(NSImage *)[[NSImage alloc] initWithSize:NSZeroSize] setName:@"QSDefaultAppProxyImage"];
		[(NSImage *)[[NSImage alloc] initWithSize:NSZeroSize] setName:@"QSIndirectProxyImage"];
#endif
		[self loadShelfArrays];

        _scanTask = [QSTask taskWithIdentifier:@"QSLibrarianScanTask"];
        _scanTask.name = @"Updating Catalog";
        _scanTask.icon = [QSResourceManager imageNamed:@"Catalog.icns"];
        _scanTask.showProgress = YES;
	}

	return self;
}

- (void)enableEntries {
	[[catalog leafEntries] makeObjectsPerformSelector:@selector(enable)];
}

- (void)pruneInvalidChildren:(id)sender {
#ifdef DEBUG
	if(VERBOSE) NSLog(@"prune invalid");
#endif
	[catalog pruneInvalidChildren];
}
- (QSCatalogEntry *)catalogCustom {
	return [self entryForID:kCustomCatalogID];
}

- (void)assignCustomAbbreviationForItem:(QSObject *)item {}

- (void)setPreset:(QSCatalogEntry *)preset isEnabled:(BOOL)flag {
	[enabledPresetsDictionary setObject:[NSNumber numberWithBool:flag] forKey:[preset identifier]];
}

- (NSNumber *)presetIsEnabled:(QSCatalogEntry *)preset {
	return [enabledPresetsDictionary objectForKey:[preset identifier]];
}


- (void)registerPresets:(NSArray *)newPresets inBundle:(NSBundle *)bundle scan:(BOOL)scan {
	for (NSMutableDictionary *dict in newPresets) {
		QSCatalogEntry *entry = [QSCatalogEntry entryWithDictionary:dict];
		NSString *path = [dict objectForKey:@"catalogPath"];

        QSCatalogEntry *parent = nil;
		if ([path isEqualToString:@"/"])
			parent = catalog;
		else if (path)
			parent = [catalog childWithPath:path];

		if (!parent) {
			parent = [catalog childWithPath:@"QSPresetModules"];
		}
		[parent.children addObject:entry];

        [parent.children sortUsingComparator:^NSComparisonResult(QSCatalogEntry *obj1, QSCatalogEntry *obj2) {
            return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
        }];
		if (scan) {
			QSGCDQueueAsync(scanning_queue, ^{
				[entry scanForced:YES];
			});
		}
	}
	//[catalogChildren replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:newPresets];
}

- (void)initCatalog {}

- (void)loadCatalogInfo {
	//	NSLog(@"load Catalog %p %@", catalog, [catalog getChildren]);
	//[catalogChildren addObject:[QSCatalogEntry entryWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSeparator", kItemID, nil]]];

    QSCatalogEntry *customEntry = [QSCatalogEntry entryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                       @"Custom", kItemName,
                                                                       @"ToolbarCustomizeIcon", kItemIcon,
                                                                       kCustomCatalogID, kItemID,
                                                                       @"QSGroupObjectSource", kItemSource,
                                                                       [NSMutableArray array] , kItemChildren,
                                                                       [NSNumber numberWithBool:YES] , @"permanent",
                                                                       [NSNumber numberWithBool:YES] , kItemEnabled, nil]];
    
	[catalog.children addObject:customEntry];
    
	NSMutableDictionary *catalogStorage = [NSMutableDictionary dictionaryWithContentsOfFile:[pCatalogSettings stringByStandardizingPath]];

	[enabledPresetsDictionary addEntriesFromDictionary:[catalogStorage objectForKey:@"enabledPresets"]];
	omittedIDs = [NSMutableSet setWithArray:[catalogStorage objectForKey:@"omittedItems"]];

    for(NSDictionary * entry in [catalogStorage objectForKey:@"customEntries"]) {
        [[customEntry children] addObject:[QSCatalogEntry entryWithDictionary:entry]];
    }
    
    catalogLoaded = YES;
	[self reloadIDDictionary:nil];
	//NSLog(@"load Catalog %p %@", catalog, [catalog getChildren]);

}

- (void)dealloc {
    /* Warning: we are a singleton, as the OS will just reap memory this will *never* be called */
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self writeCatalog:self];
}

- (void)writeCatalog:(id)sender {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = [pCatalogSettings stringByStandardizingPath];
	if (![manager fileExistsAtPath:[path stringByDeletingLastPathComponent] isDirectory:nil]) {
		[manager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:nil];
	} else ;
	// ***warning  **add error

	NSMutableArray *catalogChildren = [[self entryForID:kCustomCatalogID] children];
	NSMutableArray *customEntries = [NSMutableArray arrayWithCapacity:1];
    
// !!! Andre Berg 20091017:  updated to foreach
//     NSEnumerator *childEnumerator = [catalogChildren objectEnumerator];
// 	QSCatalogEntry *thisEntry;
// 	while(thisEntry = [childEnumerator nextObject]) {
// 		if (![thisEntry isPreset] && ![thisEntry isSeparator])
// 			[customEntries addObject:[thisEntry dictionaryRepresentation]];
// 		else if (DEBUG && ![thisEntry isSeparator]) [presetEntries addObject:thisEntry];
// 	}
    
#ifdef DEBUG
	NSMutableArray *presetEntries = [NSMutableArray arrayWithCapacity:1];
#endif
	
	for(QSCatalogEntry * thisEntry in catalogChildren) {
		if (![thisEntry isPreset] && ![thisEntry isSeparator]) {
			[customEntries addObject:[thisEntry dictionaryRepresentation]];
		}
#ifdef DEBUG
		else if (![thisEntry isSeparator]) {
			[presetEntries addObject:thisEntry];
		}
#endif
	}



	NSMutableDictionary *catalogStorage = [NSMutableDictionary dictionaryWithCapacity:2];
	// if (enabledPresetsDictionary)
	[catalogStorage setObject:enabledPresetsDictionary forKey:@"enabledPresets"];
	[catalogStorage setObject:customEntries forKey:@"customEntries"];

	if (omittedIDs) [catalogStorage setObject:[omittedIDs allObjects] forKey:@"omittedItems"];
	[catalogStorage writeToFile:path atomically:YES];

	[self reloadEntrySources:nil];

	//	if (DEBUG) [presetEntries writeToFile:[pCatalogPresetsDebugLocation stringByStandardizingPath] atomically:YES];
	//	if (VERBOSE) NSLog(@"Catalog Saved");
}

- (void)reloadSource:(NSNotification *)notif {
	dispatch_async(scanning_queue, ^{
		NSArray *entries = [[self->entriesBySource objectForKey:[notif object]] copy];
		self.scanTask.status = [NSString localizedStringWithFormat:@"Reloading Index for %@", [entries lastObject]];
		[self.scanTask start];
		for (id loopItem in entries) {
			[loopItem scanForced:NO];
		}
		[self.scanTask stop];
	});
}

- (void)reloadEntrySources:(NSNotification *)notif {
	NSArray *entries = [catalog leafEntries];
	[entriesBySource removeAllObjects];

	for (QSCatalogEntry *thisEntry in entries) {
		NSString *source = [thisEntry.info objectForKey:kItemSource];

		NSMutableArray *sourceArray = [entriesBySource objectForKey:source];
		if (!sourceArray) {
			sourceArray = [NSMutableArray arrayWithCapacity:1];
			if (source) [entriesBySource setObject:sourceArray forKey:source];
		}

		[sourceArray addObject:thisEntry];
	}
}

- (void)reloadEntry:(NSNotification *)notif
{
	dispatch_async(scanning_queue, ^{
		QSCatalogEntry *entry = [self entryForID:[notif object]];
		if (entry) {
			[entry scanForced:YES];
		}
	});
}

- (void)reloadIDDictionary:(NSNotification *)notif {
	NSArray *entries = [catalog deepChildrenWithGroups:YES leaves:YES disabled:YES];
	[entriesByID removeAllObjects];
	for (QSCatalogEntry *thisEntry in entries) {
		[entriesByID setObject:thisEntry forKey:[thisEntry identifier]];
	}
}


- (void)reloadSets:(NSNotification *)notif {
	QSThreadSafeMutableDictionary *newDict = [[QSThreadSafeMutableDictionary alloc] initWithCapacity:self.objectDictionary.count];
	//NSLog(@"cat %@ %@", catalog, [catalog leafEntries]);dls
    for(QSCatalogEntry * entry in [catalog leafEntries]) {
        for (QSObject *obj in [entry contents]) {
			NSString *identifier = [obj identifier];
            if (identifier) {
                [newDict setObject:obj forKey:identifier];
            } else {
				if ([[obj primaryType] isEqualToString:QSTextType]) {
					// don't add identifiers to string objects
					// it ends up replacing the string value
					identifier = [obj objectForType:QSTextType];
				} else {
					identifier = [NSString stringWithFormat:@"QSID:%@:%@", [entry identifier], [obj displayName]];
				}
                [obj setIdentifier:identifier];
            }
        }
    }
	self.objectDictionary = newDict;
}

- (void)updateScanTask:(NSNotification *)notif {
    QSCatalogEntry *entry = [notif object];
    if (!entry) {
        return;
    }
    if ([notif.name isEqualToString:QSCatalogEntryIsIndexingNotification]) {
        [[self scanTask] setStatus:[NSString stringWithFormat:NSLocalizedString(@"Checking: %@", @"Catalog task checking (%@ => source name)"), entry.name]];
    } else if ([notif.name isEqualToString:QSCatalogEntryIndexedNotification]) {
        [[self scanTask] setStatus:[NSString stringWithFormat:NSLocalizedString(@"Scanning: %@", @"Catalog task scanning (%@ => source name)"), entry.name]];
    }
}

- (QSCatalogEntry *)entryForID:(NSString *)theID {
	QSCatalogEntry *entry = [entriesByID objectForKey:theID];
	//if (!entry)
	//	NSLog(@"cant find entry %@", theID);
	return entry;
}

- (QSCatalogEntry *)firstEntryContainingObject:(QSObject *)object {
	NSArray *entries = [catalog deepChildrenWithGroups:NO leaves:YES disabled:NO];
    NSIndexSet *matchedIndexes = [entries indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSCatalogEntry *entry, NSUInteger idx, BOOL *stop) {
        BOOL match = [entry.contents containsObject:object];
		if (match) {
			if (![entry.identifier isEqualToString:@"QSPresetObjectHistory"]) {
				// we only want the first entry (one) so once we have it, stop the enumeration
				*stop = YES;
			}
		}
		return match;
    }];
    if ([matchedIndexes count]) {
		NSArray *matchedCatalogEntries = [entries objectsAtIndexes:matchedIndexes];
		for (QSCatalogEntry *matchedEntry in matchedCatalogEntries) {
			if (![[matchedEntry identifier] isEqualToString:@"QSPresetObjectHistory"] || matchedEntry == [matchedCatalogEntries lastObject]) {
				return matchedEntry;
			}
		}
    }
	return nil;
}


- (void)loadShelfArrays {
	NSString *path = [pShelfLocation stringByStandardizingPath];
	NSArray *shelves = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	NSArray *dictionaryArray;
	for (NSString *thisShelf in shelves) {
		if (![[thisShelf pathExtension] isEqualToString:@"qsshelf"])
            continue;
        
        NSError *error;
        NSData *data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:thisShelf]];
        dictionaryArray = [NSPropertyListSerialization propertyListWithData:data
																	options:NSPropertyListMutableContainersAndLeaves
																	 format:NULL
																	  error:&error];

        if (dictionaryArray == nil) {
            NSLog(@"Error reading shelf file %@: %@", thisShelf, error);
            continue;
        }

		NSArray *objects = [QSObject objectsWithDictionaryArray:dictionaryArray];
		if (objects)
            [shelfArrays setObject:objects forKey:[thisShelf stringByDeletingPathExtension]];
	}
}



- (BOOL)loadCatalogArrays {

#ifdef DEBUG
	NSDate *date = [NSDate date];
#endif
	
	NSArray *entries = [catalog leafEntries];

//	NSLog(@"entries %@", entries);
	BOOL indexesValid = YES;
	//BOOL indexValid;
	for(QSCatalogEntry * entry in entries) {
		if (![entry loadIndex]) {
			if (!invalidIndexes) invalidIndexes = [[NSMutableArray alloc] init];
			NSLog(@"entry %@ is invalid", entry);
			[invalidIndexes addObject:entry];
			indexesValid = NO;
		}
	}

#ifdef DEBUG
	if (DEBUG_CATALOG)
		NSLog(@"Indexes loaded (%fms) ", (-[date timeIntervalSinceNow] *1000));
#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexedNotification object:catalog];
    if (invalidIndexes)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanInvalidIndexes) name:NSApplicationDidFinishLaunchingNotification object:nil];
	return indexesValid;
}

- (void)scanCatalogWithDelay:(id)sender {
    NSLog(@"deprecated method scanCatalogWithDelay: This method does nothing");
}

- (BOOL)scanInvalidIndexes {
	for(QSCatalogEntry *entry in invalidIndexes) {
		NSLog(@"Forcing %@ to scan", entry);
		[entry scanForced:NO];
	}
	invalidIndexes = nil;
	return YES;
}

/*
 - (BOOL)loadIndexesForEntries:(NSArray *)theEntries {

	 return YES;
 }
 */



- (void)recalculateTypeArraysForItem:(QSCatalogEntry *)entry {
	// this method **previously** took the newly scanned catalog entry, got its new contents
	// and then sorted them into 'types' which are stored in QSLibrarian's 'typeArrays'.
	// QSLibrarian used to use these to easily get objects by type.
	// Upon further inspection, the only place this was ever used was for getting the valid objects for a certain
	// type for the 3rd pane (e.g. when you do something like "file" ... open with ... [populate list of app types])
	// Now, we calculate this on the fly using concurrent enumeration, instead of using locks and constantly recalculating it
	// WARNING: Testing removing all this code and calculating on the fly
	return;
}

- (QSObject *)objectWithIdentifier:(NSString *)ident
{
    return [self.objectDictionary objectForKey:ident];
}

- (void)setIdentifier:(NSString *)ident forObject:(QSObject *)obj
{
    if (ident) {
        [self.objectDictionary setObject:obj forKey:ident];
    }
}

- (void)removeObjectWithIdentifier:(NSString *)ident
{
    if (ident) {
        [self.objectDictionary removeObjectForKey:ident];
    }
}

- (NSArray *)arrayForType:(NSString *)type {
	
		type = QSUTIForAnyTypeString(type);
	NSArray *allObjects = [self.objectDictionary allValues];
	NSIndexSet *ind = [allObjects indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		// if it's a proxy object, check if its types include the string
		if ([obj isProxyObject]) {
			if ([[(QSProxyObject *)obj proxyTypes] containsObject:type]) {
				return YES;
			}
			return NO;
		}
			return [[obj types] indexOfObject:type] != NSNotFound;
	}];

	// NSLog(@"found %d objects for type %@\r%@", [typeSet count] , string, [typeArrays objectForKey:string]);
	return [allObjects objectsAtIndexes:ind];
}

- (NSArray *)scoredArrayForType:(NSString *)string
{
    // return all objects of this type, sorted by rank
    return [self scoredArrayForString:nil inSet:[self arrayForType:string] mnemonicsOnly:YES];
}

- (NSDictionary *)typeArraysFromArray:(NSArray *)array {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:1];
	NSMutableArray *typeEntry;
	for(QSObject *object in array) {
		NSDictionary *data = [[object dataDictionary] copy];
		for (NSString *key in [data allKeys]) {
			if ([key hasPrefix:@"QSObject"]) continue;
			typeEntry = [dict objectForKey:key];
			if (!typeEntry) {
				typeEntry = [NSMutableArray arrayWithCapacity:1];
				[dict setObject:typeEntry forKey:key];
			}
			[typeEntry addObject:[object copy]];
		}
		
	}
	return dict;
}

- (void)loadMissingIndexes {
	NSArray *entries = [catalog leafEntries];
	for (QSCatalogEntry *entry in entries) {
		if (!entry.canBeIndexed || !entry.contents) {
			[entry scanAndCache];
		} else {
			//	NSLog(@"monster %d", [[catalogArrays objectForKey:[entry objectForKey:kItemID]]count]);
		}
	}
}

- (void)savePasteboardHistory {
	[self saveShelf:@"QSPasteboardHistory"];
}

- (void)saveShelf:(NSString *)key {
	NSString *path = [pShelfLocation stringByStandardizingPath];
	path = [[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsshelf"];
	NSArray *dictionaryArray = [shelfArrays objectForKey:key];
	[self saveObjects:dictionaryArray toPath:path];
}

- (void)saveObjects:(NSArray *)objects toPath:(NSString*)path {
	objects = [objects arrayByPerformingSelector:@selector(dictionaryRepresentation)];

	QSGCDAsync(^{
		NSError *err = nil;
		[objects writeToURL:[NSURL fileURLWithPath:path] error:&err];
		if (err) {
			NSLog(@"Error writing shelf to disk: %@", err);
		}
	});
}

- (void)scanCatalogIgnoringIndexes:(BOOL)force {
    dispatch_async(scanning_queue, ^{
        @autoreleasepool {
			self.scanTask.status = NSLocalizedString(@"Catalog Rescan", @"Catalog rescan task status");
			self.scanTask.progress = -1;
			[self.scanTask start];

            NSArray *children = [self->catalog deepChildrenWithGroups:NO leaves:YES disabled:NO];
            NSUInteger i;
            NSUInteger c = [children count];
            for (i = 0; i<c; i++) {
				self.scanTask.progress = (CGFloat)i / c;
				QSCatalogEntry *e = [children objectAtIndex:i];
                [e scanForced:force];
            }

			self.scanTask.progress = 1.0;
			[self.scanTask stop];
			QSGCDMainAsync(^{
				[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogIndexingCompleted object:nil];
			});
        }
    });
}


- (void)startThreadedScan {
    [self scanCatalog:nil];
}
- (void)startThreadedAndForcedScan {
    [self forceScanCatalog:nil];
}
- (IBAction)forceScanCatalog:(id)sender {
	[self scanCatalogIgnoringIndexes:YES];
}

- (IBAction)scanCatalog:(id)sender {
	[self scanCatalogIgnoringIndexes:NO];
	//NSLog(@"scanned");
}

- (BOOL)itemIsOmitted:(QSBasicObject *)item {
	return [omittedIDs containsObject:[item identifier]];
}
- (void)setItem:(QSBasicObject *)item isOmitted:(BOOL)omit {
	if (!omittedIDs && omit) omittedIDs = [NSMutableSet set];
	if (omit) [omittedIDs addObject:[item identifier]];
	else [omittedIDs removeObject:[item identifier]];
	[self writeCatalog:self];
}

#ifdef DEBUG
- (CGFloat) estimatedTimeForSearchInSet:(NSArray *)set {
	CGFloat estimate = (set ? [set count] : [self.objectDictionary count]) * searchSpeed;
	if (VERBOSE)
        NSLog(@"Estimate: %fms avg: %ldµs", estimate * 1000, (long)(searchSpeed * 1000000));
	return MIN(estimate, 0.5);
}
#endif

#ifdef DEBUG
- (NSMutableArray *)scoreTest:(id)sender {
	NSArray *array = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", nil];
	NSInteger i, j;
	NSInteger count = [array count];

	NSDate *totalDate = [NSDate date];
	NSDate *date;
	//NSMutableArray *newResultArray;


	for(i = 0; i<count; i++) {
		date = [NSDate date];
		for(j = 0; j<25; j++) {
			//	NSData *scores;
			NSString *string = [array objectAtIndex:i];
            @autoreleasepool {
                /*newResultArray = */[self scoredArrayForString:string inSet:nil mnemonicsOnly:NO];
                //if (VERBOSE) NSLog(@"Searched for \"%@\" in %3fms (%d items) ", string, (1000 * -[date timeIntervalSinceNow]) , [newResultArray count]);
                
            }
		}
		if (VERBOSE) NSLog(@"SearchTest in %3fs, %3fs", -[date timeIntervalSinceNow] , -[totalDate timeIntervalSinceNow]);
	}
	return nil;
}
#endif

- (NSMutableArray *)scoredArrayForString:(NSString *)string {
	return [self scoredArrayForString:string inSet:nil mnemonicsOnly:NO];
}

- (NSMutableArray *)scoredArrayForString:(NSString *)string inNamedSet:(NSString *)setName {
	return [self scoredArrayForString:string inSet:nil mnemonicsOnly:NO];
}

- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(id)set {
	return [self scoredArrayForString:searchString inSet:set mnemonicsOnly:NO];
}

- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(NSArray *)set mnemonicsOnly:(BOOL)mnemonicsOnly {
    BOOL includeOmitted = NO;
	
	// if we are searching within 'set' (i.e. we have drilled down or we have search results),
	// then include any items that have been 'omitted' from the global catalog.
    if (set) {
		includeOmitted = YES;
    } else {
		set = [self.objectDictionary allValues];
    }
    
    if (!searchString) searchString = @"";
    BOOL usePureStringRanking = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUsePureStringRanking"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             searchString, QSRankingContext,
                             set, QSRankingObjectsInSet,
                             [NSNumber numberWithBool:includeOmitted], QSRankingIncludeOmitted,
                             [NSNumber numberWithBool:mnemonicsOnly], QSRankingMnemonicsOnly,
                             [NSNumber numberWithBool:usePureStringRanking], QSRankingUsePureString,
                             nil];

	NSMutableArray *rankObjects = [QSDefaultObjectRanker rankedObjectsForAbbreviation:searchString options:options];
#ifdef DEBUG
	NSDate *date = [NSDate date];
	
	NSInteger count = [set count];
	CGFloat speed = -[date timeIntervalSinceNow] / count;
	if (count)
        searchSpeed = ((speed + searchSpeed) / 2.0f);

	if (VERBOSE)
        NSLog(@"Ranking: %fms avg: %f¬µs", -([date timeIntervalSinceNow] * 1000), (speed * 1000000));

#endif
 	[rankObjects sortUsingSelector:@selector(scoreCompare:)];
/*    NSArray *rankedObjects = [rankObjects arrayByPerformingSelector:@selector(object)];
	[rankObjects release];
    return [[rankedObjects mutableCopy] autorelease];*/
    return rankObjects;
}


- (NSMutableArray *)shelfNamed:(NSString *)shelfName {
	NSMutableArray *shelfArray = [shelfArrays objectForKey:shelfName];

	if (shelfName && !shelfArray) {
		shelfArray = [NSMutableArray arrayWithCapacity:1];
		[shelfArrays setObject:shelfArray forKey:shelfName];
	}

	return shelfArray;
}

//Accessors
- (QSCatalogEntry *)catalog {
	return catalog;
}

- (void)setCatalog:(QSCatalogEntry *)newCatalog {
	catalog = newCatalog;
}

- (NSMutableSet *)defaultSearchSet { return defaultSearchSet;  }
- (void)setDefaultSearchSet:(NSMutableSet *)newDefaultSearchSet {
	//NSLog(@"SetSet %@", newDefaultSearchSet);
    
    // avoid multiple threads from trying to release defaultSearchSet all at the same time
    @synchronized(defaultSearchSet) {
        if(newDefaultSearchSet != defaultSearchSet){
            defaultSearchSet = newDefaultSearchSet;
        }
    }
}

- (NSMutableDictionary *)appSearchArrays { return appSearchArrays;  }

- (void)setAppSearchArrays:(NSMutableDictionary *)newAppSearchArrays {
	appSearchArrays = newAppSearchArrays;
}


- (NSMutableDictionary *)catalogArrays { return catalogArrays;  }

- (void)setCatalogArrays:(NSMutableDictionary *)newCatalogArrays {
	catalogArrays = newCatalogArrays;
}

- (NSMutableDictionary *)shelfArrays { return shelfArrays;  }

- (void)setShelfArrays:(NSMutableDictionary *)newShelfArrays {
	shelfArrays = newShelfArrays;
}

@end

@implementation QSLibrarian (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	[self registerPresets:info inBundle: bundle scan:catalogLoaded];
	if (catalogLoaded) {
		[self reloadIDDictionary:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	}
	return YES;
}
@end

@implementation QSLibrarian (ConstellationMenus_Legacy)
- (id)validActionsForDirectObject:(id)obj indirectObject:(id)obj2 {
		// This is used by the Constellation menus plugin
		return [QSExec validActionsForDirectObject:obj indirectObject:obj2];
}
@end
