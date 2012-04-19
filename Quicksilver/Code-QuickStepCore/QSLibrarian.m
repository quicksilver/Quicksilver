#import "QSLibrarian.h"
#import "QSMnemonics.h"
#import "QSNotifications.h"

#import "QSPreferenceKeys.h"
#import "QSExecutor.h"
#import "QSObjectRanker.h"
#import "QSObject.h"
#import "QSObject_PropertyList.h"

#import "QSApp.h"
#import "QSTask.h"

#import "QSTaskController.h"
//#define compGT(a, b) (a < b)
#import "UKMainThreadProxy.h"

float QSMinScore = 0.333333;

static int presetSort(id item1, id item2, QSLibrarian *librarian) {
	return [[item1 name] caseInsensitiveCompare:[item2 name]];
}

QSLibrarian *QSLib = nil;

static float searchSpeed = 0.0;

@implementation QSLibrarian

+ (id)sharedInstance {
	if (!QSLib) QSLib = [[[self class] allocWithZone:[self zone]] init];
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
		NSNumber *minScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSMinimumScore"];
		if (minScore) {
			QSMinScore = [minScore floatValue];
			NSLog(@"Minimum Score set to %f", QSMinScore);
		}
		[QSLibrarian createDirectories];
		enabledPresetsDictionary = [[NSMutableDictionary alloc] init];
		scanTask = [[QSTask alloc] initWithIdentifier:@"QSLibrarianScanTask"];
		[scanTask setName:@"Updating Catalog"];
		[scanTask setIcon:[NSImage imageNamed:@"Catalog.icns"]];
		
		previewImageQueue = [[NSOperationQueue alloc] init];
		[previewImageQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
		//Initialize Variables
		appSearchArrays = nil;
		typeArrays = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		entriesBySource = [[NSMutableDictionary alloc] initWithCapacity:1];

		omittedIDs = nil;
		entriesByID = [[NSMutableDictionary alloc] initWithCapacity:1];
		[self setShelfArrays:[NSMutableDictionary dictionaryWithCapacity:1]];
		[self setCatalogArrays:[NSMutableDictionary dictionaryWithCapacity:1]];

		NSDictionary *modulesEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Modules", kItemName,
			@"PlugInIcon", kItemIcon,
			@"QSPresetModules", kItemID,
			@"QSGroupObjectSource", kItemSource,
			[NSMutableArray array] , kItemChildren,
			[NSNumber numberWithBool:YES] , kItemEnabled, nil];

#ifdef DEBUG
		if ((int) getenv("QSDisableCatalog") || GetCurrentKeyModifiers() & shiftKey) {
			NSLog(@"Disabling Catalog");
		} else {
#endif
			[self setCatalog:[QSCatalogEntry entryWithDictionary:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"QSCATALOGROOT", kItemName, @"QSGroupObjectSource", kItemSource, [NSMutableArray arrayWithObjects:modulesEntry, nil] , kItemChildren, [NSNumber numberWithBool:YES] , kItemEnabled, nil]]];
#ifdef DEBUG
		}
#endif

		// Register for Notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogEntryChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogStructureChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadIDDictionary:) name:QSCatalogStructureChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSets:) name:QSCatalogEntryIndexed object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSource:) name:QSCatalogSourceInvalidated object:nil];
#if 0
		//Create proxy Images
		[(NSImage *)[[NSImage alloc] initWithSize:NSZeroSize] setName:@"QSDirectProxyImage"];
		[(NSImage *)[[NSImage alloc] initWithSize:NSZeroSize] setName:@"QSDefaultAppProxyImage"];
		[(NSImage *)[[NSImage alloc] initWithSize:NSZeroSize] setName:@"QSIndirectProxyImage"];
#endif
		[self loadShelfArrays];
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

	//NSLog(@"prestes %@", newPresets);
	NSMutableDictionary *dict;
	QSCatalogEntry *entry, *parent;
	NSString *path;
	NSMutableArray *children;
	for(dict in newPresets) {
		parent = nil;
		entry = [QSCatalogEntry entryWithDictionary:dict];
		path = [dict objectForKey:@"catalogPath"];
		[dict setObject:bundle forKey:@"bundle"];

		NSArray *grandchildren = [entry deepChildrenWithGroups:YES leaves:YES disabled:YES];

		[grandchildren setValue:bundle forKey:@"bundle"];

		if ([path isEqualToString:@"/"])
			parent = catalog;
		else if (path)
			parent = [catalog childWithPath:path];

		//NSLog(@"adding %@ to %p %@\r%@", entry, parent, parent, nil, [dict description]);
		if (!parent) {
			parent = [catalog childWithPath:@"QSPresetModules"];
			//		NSLog(@"register failed %@ %@ %@", parent, path, [entry identifier]);
		}
		children = [parent getChildren];
		[children addObject:entry];
		[children sortUsingFunction:(int (*)(id, id, void *))presetSort context:(void *)self];
		if (scan) [entry scanForced:YES];
	}
	//[catalogChildren replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:newPresets];
}

- (void)initCatalog {}

- (void)loadCatalogInfo {
	NSMutableArray *catalogChildren = [catalog getChildren];
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
    
	[catalogChildren addObject:customEntry];
    
	NSMutableDictionary *catalogStorage = [NSMutableDictionary dictionaryWithContentsOfFile:[pCatalogSettings stringByStandardizingPath]];

	[enabledPresetsDictionary addEntriesFromDictionary:[catalogStorage objectForKey:@"enabledPresets"]];
	omittedIDs = [[NSMutableSet setWithArray:[catalogStorage objectForKey:@"omittedItems"]] retain];

    for(NSDictionary * entry in [catalogStorage objectForKey:@"customEntries"]) {
        [[customEntry children] addObject:[QSCatalogEntry entryWithDictionary:entry]];
    }
    
	[self reloadIDDictionary:nil];
	//NSLog(@"load Catalog %p %@", catalog, [catalog getChildren]);

}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self writeCatalog:self];
	[enabledPresetsDictionary release];
	[defaultSearchSet release];
	[omittedIDs release];
	[scanTask release];
	[previewImageQueue release];
	[activityController release];
	[catalogArrays release];
	[typeArrays release];
	[defaultSearchArrays release];
	[appSearchArrays release];
	[shelfArrays release];
	[actionObjects release];
	[actionIdentifiers release];
	[objectSources release];
	[entriesByID release];
	[entriesBySource release];
	[invalidIndexes release];
	[catalog release];
	[super dealloc];
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

//- (NSArray *)entriesForSource:(NSString *)source {
//	NSArray *[self leafEntriesOfEntry:catalog];
//s}

- (void)reloadSource:(NSNotification *)notif {
	  NSArray *entries = [entriesBySource objectForKey:[notif object]];
	[scanTask setStatus:[NSString stringWithFormat:@"Reloading Index for %@", [entries lastObject]]];
	[scanTask startTask:self];

	for (id loopItem in entries) {
		[loopItem scanForced:NO];
	}
	[scanTask stopTask:self];
}

- (void)reloadEntrySources:(NSNotification *)notif {
	NSArray *entries = [catalog leafEntries];
	[entriesBySource removeAllObjects];

	for (QSCatalogEntry *thisEntry in entries) {
		NSString *source = [[thisEntry info] objectForKey:kItemSource];

		NSMutableArray *sourceArray = [entriesBySource objectForKey:source];
		if (!sourceArray) {
			sourceArray = [NSMutableArray arrayWithCapacity:1];
			if (source) [entriesBySource setObject:sourceArray forKey:source];
		}

		[sourceArray addObject:thisEntry];
	}
}

- (void)reloadIDDictionary:(NSNotification *)notif {
	NSArray *entries = [catalog deepChildrenWithGroups:YES leaves:YES disabled:YES];
	[entriesByID removeAllObjects];
	for (QSCatalogEntry *thisEntry in entries) {
		[entriesByID setObject:thisEntry forKey:[thisEntry identifier]];
	}
}


- (void)reloadSets:(NSNotification *)notif {
	NSMutableSet *newDefaultSet = [NSMutableSet setWithCapacity:1];
	//NSLog(@"cat %@ %@", catalog, [catalog leafEntries]);
	for(QSCatalogEntry * entry in [catalog leafEntries]) {
		//NSLog(@"entry %@", entry);
		[newDefaultSet addObjectsFromArray:[entry contents]];
	}

	//NSLog(@"%@", newDefaultSet);
	[self setDefaultSearchSet:newDefaultSet];
	//NSLog(@"Total %4d items in search set", [newDefaultSet count]);
	//	NSLog(@"Rebuilt Default Set in %f seconds", -[date timeIntervalSinceNow]);
	if ([notif object])
		[self recalculateTypeArraysForItem:[notif object]];
}


- (QSCatalogEntry *)entryForID:(NSString *)theID {
	QSCatalogEntry *entry = [entriesByID objectForKey:theID];
	//if (!entry)
	//	NSLog(@"cant find entry %@", theID);
	return entry;
}
- (QSCatalogEntry *)firstEntryContainingObject:(QSObject *)object {
	NSArray *entries = [catalog deepChildrenWithGroups:NO leaves:YES disabled:NO];
	for(QSCatalogEntry * entry in entries) {
		//NSString *ID = [entry identifier];
		if ([[entry _contents] containsObject:object])
			return entry;
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
        
        NSString *errorString;
        NSData *data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:thisShelf]];
        dictionaryArray = [NSPropertyListSerialization propertyListFromData:data
                                                           mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                                     format:NULL
                                                           errorDescription:&errorString];
        if (dictionaryArray == nil) {
            NSLog(@"Error reading shelf file %@: %@", thisShelf, errorString);
            [errorString release];
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
	// Scan immediately if any indexes were not found
	// if (indexesValid) [NSThread detachNewThreadSelector:@selector(scanCatalogWithDelay:) toTarget:self withObject:nil];
	// else [self startThreadedScan];

#ifdef DEBUG
	if (DEBUG_CATALOG)
		NSLog(@"Indexes loaded (%dms) ", (int)(-[date timeIntervalSinceNow] *1000));
#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexed object:nil];
  if (invalidIndexes) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanInvalidIndexes) name:NSApplicationDidFinishLaunchingNotification object:nil];
	return indexesValid;
}

- (BOOL)scanInvalidIndexes {
	for(QSCatalogEntry * entry in invalidIndexes) {

		NSLog(@"Forcing %@ to scan", entry);
		[entry scanForced:NO];
	}
	[invalidIndexes release];
	invalidIndexes = nil;
	return YES;
}

/*
 - (BOOL)loadIndexesForEntries:(NSArray *)theEntries {

	 return YES;
 }
 */



- (void)recalculateTypeArraysForItem:(QSCatalogEntry *)entry {

	//NSDate *date = [NSDate date];

	NSString *currentItemID = [entry identifier];
	NSDictionary *typeDictionary = [self typeArraysFromArray:[entry contents]];

	//NSLog(@"%@", [typeDictionary allKeys]);
	NSArray *typeKeys = [typeDictionary allKeys];
	for (NSString *key in typeKeys) {
		NSMutableDictionary *typeEntry = [typeArrays objectForKey:key];
		if (!typeEntry) {
			typeEntry = [NSMutableDictionary dictionaryWithCapacity:1];
			[typeArrays setObject:typeEntry forKey:key];
		}
		[typeEntry setObject:[typeDictionary objectForKey:key] forKey:currentItemID];
	}
	//NSLog(@"%@", typeArrays);
	// if (DEBUG) NSLog(@"Rebuilt Type Array for %@ in %dms", currentItemID, (int) (-[date timeIntervalSinceNow] *1000));

}


- (NSArray *)arrayForType:(NSString *)string {
	NSMutableSet *typeSet = [NSMutableSet setWithCapacity:1];
	for(NSArray *typeEntry in [[typeArrays objectForKey:string] allValues]) {
		[typeSet addObjectsFromArray:typeEntry];
	}

	// NSLog(@"found %d objects for type %@\r%@", [typeSet count] , string, [typeArrays objectForKey:string]);
	return [typeSet allObjects];
}


- (NSDictionary *)typeArraysFromArray:(NSArray *)array {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	NSMutableArray *typeEntry;
	for(QSObject *object in array) {
		for (NSString *key in [object dataDictionary]) {
			if ([key hasPrefix:@"QSObject"]) continue;
			typeEntry = [dict objectForKey:key];
			if (!typeEntry) {
				typeEntry = [NSMutableArray arrayWithCapacity:1];
				[dict setObject:typeEntry forKey:key];
			}
			[typeEntry addObject:object];
		}
		
	}
	return dict;
}

- (void)loadMissingIndexes {
	NSArray *entries = [catalog leafEntries];
	id entry;
	for (entry in entries) {
		if (![entry canBeIndexed] || ![entry _contents]) {
				//NSLog(@"Missing: %@", [entry name]);
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
	NSArray *dictionaryArray = [[shelfArrays objectForKey:key] arrayByPerformingSelector:@selector(dictionaryRepresentation)];
	[dictionaryArray writeToFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"qsshelf"] atomically:YES];
}


- (void)scanCatalogIgnoringIndexes:(BOOL)force {
	if (scannerCount >= 1) {
		NSLog(@"Multiple Scans Attempted");
#if 0
		if (scannerCount>2) {
			//[NSException raise:@"Multiple Scans Attempted" format:@""]
			return;
		}
#endif
		return;
	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	QSTask *mtScanTask = [scanTask mainThreadProxy];
	[mtScanTask setStatus:@"Catalog Rescan"];
	[mtScanTask startTask:self];
	[mtScanTask setProgress:-1];
	scannerCount++;
	[NSThread setThreadPriority:0];
	NSArray *children = [catalog deepChildrenWithGroups:NO leaves:YES disabled:NO];
	int i;
	int c = [children count];
	for (i = 0; i<c; i++) {
		[mtScanTask setProgress:(float) i/c];
		[[children objectAtIndex:i] scanForced:force];
	}

	[mtScanTask setProgress:1.0];
	[mtScanTask stopTask:self];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogIndexingCompleted object:nil];
	scannerCount--;
	[pool release];
}


- (void)startThreadedScan {
	[NSThread detachNewThreadSelector:@selector(scanCatalog:) toTarget:self withObject:nil];
}
- (void)startThreadedAndForcedScan {
	[NSThread detachNewThreadSelector:@selector(forceScanCatalog:) toTarget:self withObject:nil];
}
- (IBAction)forceScanCatalog:(id)sender {
	[self scanCatalogIgnoringIndexes:YES];
}

- (IBAction)scanCatalog:(id)sender {
	[self scanCatalogIgnoringIndexes:NO];
	//NSLog(@"scanned");
}
- (void)scanCatalogWithDelay:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// NSLog(@"delayed load");

	[scanTask setStatus:@"Rescanning Catalog"];
	[scanTask startTask:self];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:8.0]];
	[NSThread setThreadPriority:0];
	[catalog scanForced:NO];
  // [activityController removeTask:@"Scan"];
	[scanTask stopTask:self];
	[pool release];
}

- (BOOL)itemIsOmitted:(QSBasicObject *)item {
	return [omittedIDs containsObject:[item identifier]];
}
- (void)setItem:(QSBasicObject *)item isOmitted:(BOOL)omit {
	if (!omittedIDs && omit) omittedIDs = [[NSMutableSet set] retain];
	if (omit) [omittedIDs addObject:[item identifier]];
	else [omittedIDs removeObject:[item identifier]];
	[self writeCatalog:self];
}

- (float) estimatedTimeForSearchInSet:(id)set {
	float estimate = (set ? [set count] : [defaultSearchSet count]) * searchSpeed;
#ifdef DEBUG
	if (VERBOSE)
        NSLog(@"Estimate: %fms avg: %dµs", estimate * 1000, (int)(searchSpeed * 1000000));
#endif
	return MIN(estimate, 0.5);
}

#ifdef DEBUG
- (NSMutableArray *)scoreTest:(id)sender {
	NSArray *array = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", nil];
	int i, j;
	int count = [array count];

	NSDate *totalDate = [NSDate date];
	NSDate *date;
	//NSMutableArray *newResultArray;

	//NSTimeInterval moo = 0;
	//NSTimeInterval moo2 = 0;
	NSAutoreleasePool *pool;
	for(i = 0; i<count; i++) {
		date = [NSDate date];
		for(j = 0; j<25; j++) {
			//	NSData *scores;
			NSString *string = [array objectAtIndex:i];
			pool = [[NSAutoreleasePool alloc] init];
			/*newResultArray = */[self scoredArrayForString:string inSet:nil mnemonicsOnly:NO];
			//if (VERBOSE) NSLog(@"Searched for \"%@\" in %3fms (%d items) ", string, (1000 * -[date timeIntervalSinceNow]) , [newResultArray count]);

			[pool release];
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
	if (!set) set = [defaultSearchSet allObjects];
	NSMutableArray *rankObjects = [QSDefaultObjectRanker rankedObjectsForAbbreviation:searchString inSet:set inContext:searchString mnemonicsOnly:mnemonicsOnly];
#ifdef DEBUG
	NSDate *date = [NSDate date];
	
	int count = [set count];
	float speed = -[date timeIntervalSinceNow] / count;
	if (count)
        searchSpeed = ((speed + searchSpeed) / 2.0f);

	if (VERBOSE)
        NSLog(@"Ranking: %fms avg: %d¬µs", -([date timeIntervalSinceNow] * 1000), (int)(speed * 1000000));

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
	[catalog release];
	catalog = [newCatalog retain];
}

- (NSMutableSet *)defaultSearchSet { return defaultSearchSet;  }
- (void)setDefaultSearchSet:(NSMutableSet *)newDefaultSearchSet {
	//NSLog(@"SetSet %@", newDefaultSearchSet);
	if(newDefaultSearchSet != defaultSearchSet){
		[defaultSearchSet release];
		defaultSearchSet = [newDefaultSearchSet retain];
	}
}


- (NSMutableDictionary *)appSearchArrays { return [[appSearchArrays retain] autorelease];  }

- (void)setAppSearchArrays:(NSMutableDictionary *)newAppSearchArrays {
	[appSearchArrays release];
	appSearchArrays = [newAppSearchArrays retain];
}


- (NSMutableDictionary *)catalogArrays { return [[catalogArrays retain] autorelease];  }

- (void)setCatalogArrays:(NSMutableDictionary *)newCatalogArrays {
	[catalogArrays release];
	catalogArrays = [newCatalogArrays retain];
}


- (NSMutableDictionary *)typeArrays { return [[typeArrays retain] autorelease];  }

- (void)setTypeArrays:(NSMutableDictionary *)newTypeArrays {
	[typeArrays release];
	typeArrays = [newTypeArrays retain];
}

- (NSMutableDictionary *)shelfArrays { return [[shelfArrays retain] autorelease];  }

- (void)setShelfArrays:(NSMutableDictionary *)newShelfArrays {
	[shelfArrays release];
	shelfArrays = [newShelfArrays retain];
}


- (QSTask *)scanTask {
	return scanTask;
}

- (void)setScanTask:(QSTask *)value {
	if (scanTask != value) {
		[scanTask release];
		scanTask = [value retain];
	}
}

- (NSOperationQueue *)previewImageQueue {
	return previewImageQueue;
}

@end

@implementation QSLibrarian (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	[self registerPresets:info inBundle: bundle scan:[(QSApp *)NSApp completedLaunch]];
	if ([NSApp completedLaunch]) {
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
