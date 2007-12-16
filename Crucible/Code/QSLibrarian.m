
#import "QSLibrarian.h"
#import "QSNotifications.h"

#import "QSPreferenceKeys.h"
#import "QSExecutor.h"
#import "QSObjectRanker.h"

#import "QSObject.h"

#import "QSPaths.h"
#import "QSMnemonics.h"
#import "QSObject_PropertyList.h"

#import "QSTask.h"

#import "QSTaskController.h"
#define compGT(a,b) (a < b)
#import "UKMainThreadProxy.h"

float gMinScore=0.333333;


static int presetSort(id item1, id item2, QSLibrarian *librarian){
	return [[item1 name]caseInsensitiveCompare:[item2 name]];
}



id QSLib;

//QSRankedObject *makeRankObject(NSString *searchString,QSBasicObject *object,float modifier,BOOL mnemonicsOnly,NSDictionary *definedMnemonics){
//    QSRankedObject *rankedObject=nil;
//    if ([object isKindOfClass:[QSRankedObject class]]){ // Reuse old ranked object if possible
//        rankedObject=(QSRankedObject *)object;
//        object=[rankedObject object];
//    }
//    NSString *matchedString=nil;
//    if (!searchString)searchString=@"";
//    float newScore=1.0;
//	
//	
//    QSRankInfo *info=object->rankData;
//	if (!info) info=[object getRankData];
//	
//	if (info->omitted)
//		return nil;
//	if (!info->name)return nil;
//    if (searchString && !mnemonicsOnly){ // get base score for both name and label
//        newScore = [info->name scoreForAbbreviation:searchString];//QSScoreForAbbreviation((CFStringRef)info->name, (CFStringRef)searchString,nil);
//        
//        if (info->label){
//            float labelScore=[info->label scoreForAbbreviation:searchString];//QSScoreForAbbreviation((CFStringRef)info->label, (CFStringRef)searchString,nil);
//			
//            if (labelScore>newScore){
//				newScore=labelScore;
//				matchedString=info->label;
//			}
//		}
//    }
//    
//    
//    if (newScore){ // Add modifiers
//		if ([definedMnemonics objectForKey:info->identifier])
//            modifier+=10.0f;
//        newScore+=modifier;
//		
//		if(mnemonicsOnly)
//			newScore+=[object rankModification];
//    }
//    NSDictionary *myShortcuts=info->mnemonics; 
//	int useCount=0;
//	
//	// get number of times this abbrev. has been used
//	if ([searchString length])
//		useCount=[[myShortcuts objectForKey:searchString]intValue]; 
//	
//	
//	if (useCount){
//		newScore+=(1-1/(useCount+1));
//		
//	} else if (newScore){
//		// otherwise add points for similar starting abbreviations
//		NSEnumerator *enumerator = [myShortcuts keyEnumerator];
//		id key;
//		while ((key = [enumerator nextObject])) {
//			if (prefixCompare(key, searchString)==NSOrderedSame){
//				newScore+=(1-1/([[myShortcuts objectForKey:key]floatValue]))/4;
//			}
//		}
//		
//	}
//	
//	if (newScore)  newScore+=sqrt([object retainCount])/100; // If an object appears many times, increase score, this may be bad
//	
//	//*** in the future, increase for recent document, increase for partial match, increase for higher source index
//	
//	// Create the ranked object
//	if (rankedObject)
//		[rankedObject setScore:newScore];
//	if (newScore>gMinScore){
//		if (rankedObject){
//			[rankedObject setRankedString:matchedString];
//			return [rankedObject retain];
//		}else{
//			return [[QSRankedObject alloc]initWithObject:(id)object matchString:matchedString score:(float)newScore];
//			
//		}
//	}
//	return nil;
//}
//

static float searchSpeed=0.0;

@implementation QSLibrarian

+ (id)sharedInstance{
    if (!QSLib) QSLib = [[[self class] allocWithZone:[self zone]] init];
    return QSLib;
}

+ (void) createDirectories{
	NSFileManager *manager=[NSFileManager defaultManager];
	NSString *path=[pIndexLocation stringByStandardizingPath];
	if (![manager fileExistsAtPath:path isDirectory:nil])[manager createDirectoriesForPath:path];
	path=[pShelfLocation stringByStandardizingPath];
	if (![manager fileExistsAtPath:path isDirectory:nil])[manager createDirectoriesForPath:path];
}
+ (void) removeIndexes{
	[[NSFileManager defaultManager]removeFileAtPath:[pIndexLocation stringByStandardizingPath]handler:nil];	
	[self createDirectories];
}
- (void) loadDefaultCatalog{
	//    [self setCatalog:[NSMutableDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Catalog" ofType:@"plist"]]];
}

- (id) init{
    if ((self=[super init])){
		NSNumber *minScore=[[NSUserDefaults standardUserDefaults]objectForKey:@"QSMinimumScore"];
		if (minScore){
			gMinScore=[minScore floatValue];
			QSLog(@"Minimum Score set to %f",gMinScore);
		}
		[QSLibrarian createDirectories];
        scanTask=[[QSTask alloc]initWithIdentifier:@"QSLibrarianScanTask"];
		[scanTask setName:@"Updating Catalog"];
		[scanTask setIcon:[NSImage imageNamed:@"Catalog.icns"]];
        //Initialize Variables
        appSearchArrays=nil;
        typeArrays=[[NSMutableDictionary dictionaryWithCapacity:1]retain];
        entriesBySource=[[NSMutableDictionary alloc] initWithCapacity:1];
		
		omittedIDs=nil;
        entriesByID=[[NSMutableDictionary alloc] initWithCapacity:1];
        [self setShelfArrays:[NSMutableDictionary dictionaryWithCapacity:1]];
        [self setCatalogArrays:[NSMutableDictionary dictionaryWithCapacity:1]];
        
        
		NSDictionary *modulesEntry=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Modules",kItemName,
			@"PlugInIcon",kItemIcon,
			@"QSPresetModules",kItemID,
			@"QSGroupObjectSource",kItemSource,
			[NSMutableArray array],kItemChildren,
			[NSNumber numberWithBool:YES],kItemEnabled,nil];

		if ((int)getenv("QSDisableCatalog")  ||   GetCurrentKeyModifiers() & shiftKey){
			QSLog(@"Disabling Catalog");
		}else{
			[self setCatalog:[QSCatalogEntry entryWithDictionary:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:@"QSCATALOGROOT",kItemName,@"QSGroupObjectSource",kItemSource,[NSMutableArray arrayWithObjects:modulesEntry,nil],kItemChildren,[NSNumber numberWithBool:YES],kItemEnabled,nil]]];
		}
		//	QSLog(@"cat");
		
        
        // Register for Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogEntryChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogStructureChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadIDDictionary:) name:QSCatalogStructureChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSets:) name:QSCatalogEntryIndexed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSource:) name:QSCatalogSourceInvalidated object:nil];
        
        //Create proxy Images
        [(NSImage *)[[NSImage alloc]initWithSize:NSZeroSize] setName:@"QSDirectProxyImage"];
        [(NSImage *)[[NSImage alloc]initWithSize:NSZeroSize] setName:@"QSDefaultAppProxyImage"];
        [(NSImage *)[[NSImage alloc]initWithSize:NSZeroSize] setName:@"QSIndirectProxyImage"];
        
        
		[self loadShelfArrays];
    }
    
    return self;
}
- (void)enableEntries{
	[[catalog leafEntries]makeObjectsPerformSelector:@selector(enable)];
}

- (void) pruneInvalidChildren:(id)sender{
	[catalog pruneInvalidChildren];	
}
- (QSCatalogEntry *)catalogCustom{
	return [self entryForID:kCustomCatalogID];	
}
- (void) assignCustomAbbreviationForItem:(QSObject *)item{	
}


//- (void)saveCatalogArrays{
//	NSDate *date=[NSDate date];
//	//QSLog(@"Writing Preferences");
//	// NSFileManager *manager=[NSFileManager defaultManager];
//	
//	NSEnumerator *catalogEnumerator=[catalogArrays keyEnumerator];
//	NSString *key;
//	//NSArray *dictionaryArray;
//	//NSData *data;
//	while((key=[catalogEnumerator nextObject]))
//		[self saveCatalogArray:key];
//	if (DEBUG_CATALOG)  QSLog(@"Saved Catalog in %f seconds",-[date timeIntervalSinceNow]);
//}

- (void)setPreset:(QSCatalogEntry *)preset isEnabled:(BOOL)flag{
	[enabledPresetsDictionary setObject:[NSNumber numberWithBool:flag] forKey:[preset identifier]];
}

- (NSNumber *)presetIsEnabled:(QSCatalogEntry *)preset{
	return [enabledPresetsDictionary objectForKey:[preset identifier]];
}

- (void)registerPreset:(NSDictionary *)dict inBundle:(NSBundle *)bundle scan:(BOOL)scan{
	QSCatalogEntry *parent=nil;
	QSCatalogEntry *entry=[QSCatalogEntry entryWithDictionary:dict];
	NSString *path=[dict objectForKey:@"catalogPath"];
	[dict setValue:bundle forKey:@"bundle"];
	
	NSArray *grandchildren=[entry deepChildrenWithGroups:YES leaves:YES disabled:YES];
	
	[grandchildren setValue:bundle forKey:@"bundle"];
	
	if ([path isEqualToString:@"/"])
		parent=catalog;
	else if (path)
		parent=[catalog childWithPath:path];
	
	//QSLog(@"adding %@ to %p %@\r%@",entry,parent,parent,nil,[dict description]);
	if (!parent){
		parent=[catalog childWithPath:@"QSPresetModules"];
		//		QSLog(@"register failed %@ %@ %@",parent,path,[entry identifier]);
	}
	NSMutableArray *children=[parent getChildren];
	[children addObject:entry];
	[children sortUsingFunction:(int (*)(id, id, void *))presetSort context:(void *)self];
	
	if (scan) [entry scanForced:YES];
}
- (void)registerPresets:(NSArray *)newPresets inBundle:(NSBundle *)bundle scan:(BOOL)scan{
	QSLog(@"prestes %@",[newPresets description]);
	NSEnumerator *e=[newPresets objectEnumerator];
	NSMutableDictionary *dict;

	while((dict=[e nextObject])){
		[self registerPreset:dict inBundle:bundle scan:scan];
	}
	//[catalogChildren replaceObjectsInRange:NSMakeRange(0,0) withObjectsFromArray:newPresets];
}

- (void)initCatalog{
	NSArray *presets = [QSReg elementsForPointID:@"com.blacktree.catalog.presets"];
	
	foreach(preset, presets) {

	[self registerPreset:[preset plistContent]
				 inBundle:[[preset plugin] bundle]
					 scan:NO];

	}
	
	// NSMutableArray *catalogChildren=[catalog getChildren];
	
	
	// Load presets
	
	// NSMutableArray *presets=nil;
	// if (DEBUG) presets=[NSMutableArray arrayWithContentsOfFile:[pCatalogPresetsDebugLocation stringByStandardizingPath]];
	//   if (!presets) presets=[NSMutableArray arrayWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Presets" ofType:@"plist"]];
	//  if (!presets) QSLog(@"Unable to load presets");
	
	///	foreach(preset,presets){
	//	[catalogChildren addObject:[QSCatalogEntry entryWithDictionary:preset]];
	//}	
	
	
}

- (void)loadCatalogInfo{
	NSMutableArray *catalogChildren=[catalog getChildren];
	//	QSLog(@"load Catalog %p %@",catalog,[catalog getChildren]);
	//[catalogChildren addObject:[QSCatalogEntry entryWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSeparator",kItemID,nil]]];
	
	NSMutableDictionary *catalogStorage=[NSMutableDictionary dictionaryWithContentsOfFile:[pCatalogSettings stringByStandardizingPath]];
    
    enabledPresetsDictionary=[[NSMutableDictionary alloc]init];
    [enabledPresetsDictionary addEntriesFromDictionary:[catalogStorage objectForKey:@"enabledPresets"]];
	
	
	QSCatalogEntry *customEntry=[QSCatalogEntry entryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"Custom",kItemName,
		@"ToolbarCustomizeIcon",kItemIcon,
		kCustomCatalogID,kItemID,
		@"QSGroupObjectSource",kItemSource,
		[NSMutableArray array],kItemChildren,
		[NSNumber numberWithBool:YES],@"permanent",
		[NSNumber numberWithBool:YES],kItemEnabled,nil]];
	
	[catalogChildren addObject:customEntry];
	omittedIDs=[[NSMutableSet setWithArray:[catalogStorage objectForKey:@"omittedItems"]]retain];	
	//if (!enabledPresetsDictionary)enabledPresetsDictionary=[[NSMutableDictionary dictionaryWithCapacity:1]retain];
	//QSCatalogEntry *customEntry=[self entryForID:kCustomCatalogID];
    {
		foreach(entry,[catalogStorage objectForKey:@"customEntries"]){
			[[customEntry children] addObject:[QSCatalogEntry entryWithDictionary:entry]];	
		}
	}
	[self reloadIDDictionary:nil];
	//QSLog(@"load Catalog %p %@",catalog,[catalog getChildren]); 
	
}


- (void) dealloc{
    [self writeCatalog:self];   
	[super dealloc];
}



- (void) writeCatalog:(id)sender{
    NSFileManager *manager=[NSFileManager defaultManager];
    NSString *path=[pCatalogSettings stringByStandardizingPath];
    if (![manager fileExistsAtPath:[path stringByDeletingLastPathComponent] isDirectory:nil]){
        [manager createDirectoryAtPath:[path stringByDeletingLastPathComponent] attributes:nil];
    }
    else ; 
	// ***warning   **add error
    
    NSMutableArray *catalogChildren=[[self entryForID:kCustomCatalogID] children];
    
    NSMutableArray *customEntries=[NSMutableArray arrayWithCapacity:1];
    NSMutableArray *presetEntries=[NSMutableArray arrayWithCapacity:1];
    
    
    QSCatalogEntry *thisEntry;
    for(thisEntry in catalogChildren){
        if (![thisEntry isPreset] && ![thisEntry isSeparator])
            [customEntries addObject:[thisEntry dictionaryRepresentation]];
        else if (DEBUG && ![thisEntry isSeparator]) [presetEntries addObject:thisEntry];
    }
    
    
    
    NSMutableDictionary *catalogStorage=[NSMutableDictionary dictionaryWithCapacity:2];
	// if(enabledPresetsDictionary)
	[catalogStorage setObject:enabledPresetsDictionary forKey:@"enabledPresets"];
    [catalogStorage setObject:customEntries forKey:@"customEntries"];
	
	if (omittedIDs) [catalogStorage setObject:[omittedIDs allObjects] forKey:@"omittedItems"];
    [catalogStorage writeToFile:path atomically:YES];
    
    [self reloadEntrySources:nil];
    
	//    if (DEBUG) [presetEntries writeToFile:[pCatalogPresetsDebugLocation stringByStandardizingPath] atomically:YES];
	//    if (VERBOSE) QSLog(@"Catalog Saved");
}

//- (NSArray *)entriesForSource:(NSString *)source{
//    NSArray *[self leafEntriesOfEntry:catalog];
//s}

- (void)reloadSource:(NSNotification *)notif{
	   NSArray *entries=[entriesBySource objectForKey:[notif object]];
	[scanTask setStatus:[NSString stringWithFormat:@"Reloading Index for %@",[entries lastObject]]];
    [scanTask startTask:self];
 
    for (id loopItem in entries){
        [loopItem scanForced:NO];
    }
	[scanTask stopTask:self];
}

- (void)reloadEntrySources:(NSNotification *)notif{
    NSArray *entries=[catalog leafEntries];
    [entriesBySource removeAllObjects];
    
    for (QSCatalogEntry *thisEntry in entries){
        NSString *source=[[thisEntry info]objectForKey:kItemSource];
        
        NSMutableArray *sourceArray=[entriesBySource objectForKey:source];
        if (!sourceArray){
            sourceArray=[NSMutableArray arrayWithCapacity:1];
            if (source)[entriesBySource setObject:sourceArray forKey:source];
        }
        
        [sourceArray addObject:thisEntry];
    }
}
- (void)reloadIDDictionary:(NSNotification *)notif{
    NSArray *entries=[catalog deepChildrenWithGroups:YES leaves:YES disabled:YES];
    [entriesByID removeAllObjects];
    for (QSCatalogEntry *thisEntry in entries){
        [entriesByID setObject:thisEntry forKey:[thisEntry identifier]];
    }
}


- (void)reloadSets:(NSNotification *)notif{
	NSMutableSet *newDefaultSet=[NSMutableSet setWithCapacity:1];
    //QSLog(@"cat %@ %@",catalog,[catalog leafEntries]);
	foreach(entry,[catalog leafEntries]){
		//QSLog(@"entry %@",entry);
		[newDefaultSet addObjectsFromArray:[entry contents]];    
    }
    
    //QSLog(@"%@", newDefaultSet);
    [self setDefaultSearchSet:newDefaultSet];
	//QSLog(@"Total %4d items in search set",[newDefaultSet count]);
	//    QSLog(@"Rebuilt Default Set in %f seconds",-[date timeIntervalSinceNow]);
    if ([notif object])
        [self recalculateTypeArraysForItem:[notif object]];
}


- (QSCatalogEntry *) entryForID:(NSString *)theID{
	QSCatalogEntry *entry=[entriesByID objectForKey:theID];
	//if (!entry)
	//	QSLog(@"cant find entry %@",theID);
	return entry;
}
- (QSCatalogEntry *)firstEntryContainingObject:(QSObject *)object{
	NSArray *entries=[catalog deepChildrenWithGroups:NO leaves:YES disabled:NO];
	foreach(entry,entries){
		//NSString *ID=[entry identifier];
		if ([[entry _contents]containsObject:object])
			return entry;
	}
	return nil;
}


- (void)loadShelfArrays{
    NSString *path=[pShelfLocation stringByStandardizingPath];
    NSArray *shelves=[[NSFileManager defaultManager]directoryContentsAtPath:path];
    NSArray *dictionaryArray;
    for (NSString *thisShelf in shelves){
        if (![[thisShelf pathExtension]isEqualToString:@"qsshelf"]) continue;
        dictionaryArray=[NSArray arrayWithContentsOfFile:[path stringByAppendingPathComponent:thisShelf]];
		NSArray *objects=[QSObject objectsWithDictionaryArray:dictionaryArray];
        if (objects) [shelfArrays setObject:objects forKey:[thisShelf stringByDeletingPathExtension]];
    }
}



- (BOOL)loadCatalogArrays{
    NSDate *date=[NSDate date];
    NSArray *entries=[catalog leafEntries];
	
//	QSLog(@"entries %@",entries);
    BOOL indexesValid=YES;
	//BOOL indexValid;
    foreach(entry,entries){
		if(![entry loadIndex]){
			if (!invalidIndexes)invalidIndexes=[[NSMutableArray alloc]init];
			QSLog(@"entry %@ is invalid",entry);
			[invalidIndexes addObject:entry];
			indexesValid=NO;
		}
	}
	// Scan immediately if any indexes were not found
	//  if (indexesValid) [NSThread detachNewThreadSelector:@selector(scanCatalogWithDelay:) toTarget:self withObject:nil];
    //  else [self startThreadedScan];
    
    if (DEBUG_CATALOG)
		QSLog(@"Indexes loaded (%dms)",(int)(-[date timeIntervalSinceNow]*1000));
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryIndexed object:nil];
   if (invalidIndexes) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanInvalidIndexes) name:NSApplicationDidFinishLaunchingNotification object:nil];
    return indexesValid;
}

- (BOOL)scanInvalidIndexes{
	foreach(entry,invalidIndexes){
		
		QSLog(@"Forcing  %@ to scan",entry);
		[entry scanForced:NO];
	}
	[invalidIndexes release];
	invalidIndexes=nil;
	return YES;
}

/*
 - (BOOL)loadIndexesForEntries:(NSArray *)theEntries{
     
     return YES;
 }
 */



- (void)recalculateTypeArraysForItem:(QSCatalogEntry *)entry{
    
    //NSDate *date=[NSDate date];
    
    NSString *currentItemID=[entry identifier];
    NSDictionary *typeDictionary=[self  typeArraysFromArray:[entry contents]];
    
    //QSLog(@"%@",[typeDictionary allKeys]);
    NSArray *typeKeys=[typeDictionary allKeys];
    for (NSString *key in typeKeys){
        NSMutableDictionary *typeEntry=[typeArrays objectForKey:key];
        if (!typeEntry){
            typeEntry=[NSMutableDictionary dictionaryWithCapacity:1];
            [typeArrays setObject:typeEntry forKey:key];
        }
        [typeEntry setObject:[typeDictionary objectForKey:key] forKey:currentItemID];
    }
    //QSLog(@"%@",typeArrays);
    //  if (DEBUG)  QSLog(@"Rebuilt Type Array  for %@ in %dms",currentItemID,(int)(-[date timeIntervalSinceNow]*1000));
    
}


- (NSArray *)arrayForType:(NSString *)string{
    NSEnumerator *typeEntryEnumerator=[[typeArrays objectForKey:string] objectEnumerator];
    NSArray *typeEntry;
    NSMutableSet *typeSet=[NSMutableSet setWithCapacity:1];
    while((typeEntry=[typeEntryEnumerator nextObject]))
        [typeSet addObjectsFromArray:typeEntry];
    
    // QSLog(@"found %d objects for type %@\r%@",[typeSet count],string,[typeArrays objectForKey:string]);
    return [typeSet allObjects];    
}


- (NSDictionary *)typeArraysFromArray:(NSArray *)array{
    int i,j;
    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:1];
    NSArray *keys;
    QSObject *object;
    int objectCount=[array count];
    int keyCount;
    NSString *key;
    NSMutableArray *typeEntry;
    for(i=0;i<objectCount;i++){
        object=[array objectAtIndex:i];
        keys=[object allKeys];
        keyCount=[keys count];
        for (j=0;j<keyCount;j++){
            key=[keys objectAtIndex:j];
            if ([key hasPrefix:@"QSObject"]) continue;
            typeEntry=[dict objectForKey:key];
            if (!typeEntry){
                typeEntry=[NSMutableArray arrayWithCapacity:1];
                [dict setObject:typeEntry forKey:key];
            }
            [typeEntry addObject:object];
        }
        
    }
    return dict;
}
- (void)loadMissingIndexes{
//	QSLog(@"load missing");
	//NSDate *date=[NSDate date];
	NSArray *entries=[catalog leafEntries];
	//	BOOL indexesValid=YES;
	id entry;
	for (entry in entries){
		
		if (![entry canBeIndexed] || ![entry _contents]){
				//QSLog(@"Missing: %@",[entry name]);
			[entry scanAndCache];
		}else{
			//	QSLog(@"monster %d",[[catalogArrays objectForKey:[entry objectForKey:kItemID]]count]);
			
			
		}
		
	}
	
	return;
	
}



- (void)savePasteboardHistory{
    [self saveShelf:@"QSPasteboardHistory"];
}

- (void)saveShelf:(NSString *)key{
    //NSFileManager *manager=[NSFileManager defaultManager];
    NSString *path=[pShelfLocation stringByStandardizingPath];
    NSArray *dictionaryArray=[[shelfArrays objectForKey:key] arrayByPerformingSelector:@selector(archiveDictionary)];
    [dictionaryArray writeToFile:[[path stringByAppendingPathComponent:key]stringByAppendingPathExtension:@"qsshelf"] atomically:YES];
}


- (void)scanCatalogIgnoringIndexes:(BOOL)force{
	if (scannerCount>=1){
		QSLog(@"Multiple Scans Attempted");
		if(scannerCount>2){
			//[NSException raise:@"Multiple Scans Attempted" format:@""]
			return;
		}
		return;
	}

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		QSTask *mtScanTask=[scanTask mainThreadProxy];
	[mtScanTask setStatus:@"Catalog Rescan"];
    [mtScanTask startTask:self];
	[mtScanTask setProgress:-1];
	scannerCount++;
    [NSThread setThreadPriority:0];
	NSArray *children=[catalog deepChildrenWithGroups:NO leaves:YES disabled:NO];
	int i;
	int c=[children count];
	for (i=0;i<c;i++){
		[mtScanTask setProgress:(float)i/c];
		[[children objectAtIndex:i] scanForced:force];
	}
	
	[mtScanTask setProgress:1.0];
	
	[mtScanTask stopTask:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogIndexingCompleted object:nil];
	scannerCount--;
    [pool release];
}


- (void)startThreadedScan{
    [NSThread detachNewThreadSelector:@selector(scanCatalog:) toTarget:self withObject:nil];
}
- (void)startThreadedAndForcedScan{
	[NSThread detachNewThreadSelector:@selector(forceScanCatalog:) toTarget:self withObject:nil];
}
- (IBAction)forceScanCatalog:(id)sender{
    [self scanCatalogIgnoringIndexes:YES];
}

- (IBAction)scanCatalog:(id)sender{
    [self scanCatalogIgnoringIndexes:NO];
	//QSLog(@"scanned");
}
- (void)scanCatalogWithDelay:(id)sender{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //  QSLog(@"delayed load");
	
	[scanTask setStatus:@"Rescanning Catalog"];
    [scanTask startTask:self];
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:8.0]];
    [NSThread setThreadPriority:0];
    [catalog scanForced:NO];
   // [activityController removeTask:@"Scan"];
	[scanTask stopTask:self];
    [pool release];
}

- (BOOL)itemIsOmitted:(QSBasicObject *)item{
	return [omittedIDs containsObject:[item identifier]];
}
- (void)setItem:(QSBasicObject *)item isOmitted:(BOOL)omit{
	if (!omittedIDs && omit) omittedIDs=[[NSMutableSet set]retain];
	if (omit)[omittedIDs addObject:[item identifier]];
	else [omittedIDs removeObject:[item identifier]];
	
	[item setOmitted:omit];
	[self writeCatalog:self];
}




- (float)estimatedTimeForSearchInSet:(id)set{
    float estimate=(set?[(NSArray *)set count]:[(NSArray *)defaultSearchSet count])*searchSpeed;
	// if (VERBOSE)QSLog(@"Estimte: %fms avg: %d탎",estimate*1000,(int)(searchSpeed*1000000));
    return MIN(estimate,0.5);
}

- (NSMutableArray *)scoreTest:(id)sender{
	
	NSArray *array=[NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",nil];
	int i,j;
	int count=[array count];
	
	
	NSDate *totalDate=[NSDate date];
	NSDate *date;
	NSMutableArray *newResultArray;
	
	//NSTimeInterval moo=0;
	//NSTimeInterval moo2=0;
	NSAutoreleasePool *pool;
	for(i=0;i<count;i++){
		date=[NSDate date];
		for(j=0;j<25;j++){
			
			
			//    NSData *scores;
			NSString *string=[array objectAtIndex:i];
			
			//date=[NSDate date];
			pool = [[NSAutoreleasePool alloc] init];
			newResultArray=[self scoredArrayForString:string inSet:nil mnemonicsOnly:NO];
			//if (VERBOSE) QSLog(@"Searched for \"%@\" in %3fms (%d items)",string,(1000 * -[date timeIntervalSinceNow]) ,[newResultArray count]);
			
			[pool release];
		}
		
		if (VERBOSE) QSLog(@"SearchTesA in %3fs, %3fs",-[date timeIntervalSinceNow],-[totalDate timeIntervalSinceNow]);	
		
		//	if (VERBOSE) QSLog(@"SearchTest in %3fs, %f",-[totalDate timeIntervalSinceNow],moo);
	}	
	return nil;
}

- (NSMutableArray *)scoredArrayForString:(NSString *)string{
    return [self scoredArrayForString:string inSet:nil];
}

- (NSMutableArray *)scoredArrayForString:(NSString *)string inNamedSet:(NSString *)setName{
    return [self scoredArrayForString:string inSet:nil];
}

- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(id)set{
    return [self scoredArrayForString:searchString inSet:set mnemonicsOnly:NO];
}
/*
 - (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(id)set mnemonicsOnly:(BOOL)mnemonicsOnly{
	 if (!set) set=[defaultSearchSet allObjects];
	 NSDictionary *definedMnemonics=[[QSMnemonics sharedInstance]definedMnemonicsForString:searchString];
	 
	 
	 int i;
	 int count=[set count];
	 NSMutableArray *rankObjects=[NSMutableArray arrayWithCapacity:count];
	 
	 id thisObject;
	 QSRankedObject *rankedObject;
	 float scoreModifier=0.0;
	 NSDate *date=[NSDate date];
	 for (i=0;i<[set count];i++){
		 thisObject=[set objectAtIndex:i];
		 rankedObject=rankObject(searchString,thisObject,scoreModifier,mnemonicsOnly,definedMnemonics);
		 if (rankedObject)
			 [rankObjects addObject:rankedObject];
	 }
	 float speed=-[date timeIntervalSinceNow]/count;
	 if (count) searchSpeed=((speed+searchSpeed)/2.0);
	 //  if (VERBOSE)QSLog(@"Ranking: %fms avg: %d탎",-([date timeIntervalSinceNow]*1000),(int)(speed*1000000));date=[NSDate date];
	 [rankObjects sortUsingSelector:@selector(scoreCompare:)];
	 //  QSLog(@"rank %@",rankObjects);
	 return rankObjects;
 }
 */
- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(NSArray *)set mnemonicsOnly:(BOOL)mnemonicsOnly{
	if (!set) set=(NSArray *)defaultSearchSet;
	NSDate *date=[NSDate date];
	NSMutableArray *rankObjects=[QSDefaultObjectRanker rankedObjectsForAbbreviation:searchString inSet:(NSArray *)set inContext:nil mnemonicsOnly:(BOOL)mnemonicsOnly];	
	int count=[set count];
	float speed=-[date timeIntervalSinceNow]/count;
    if (count) searchSpeed=((speed+searchSpeed)/2.0f);
	//   if (VERBOSE)QSLog(@"Ranking: %fms avg: %d탎",-([date timeIntervalSinceNow]*1000),(int)(speed*1000000));date=[NSDate date];
  	[rankObjects sortUsingSelector:@selector(scoreCompare:)];
	//QSLog(@"rakn %@",[rankObjects objectAtIndex:0]);
	return rankObjects;
}






//- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(id)set mnemonicsOnly:(BOOL)mnemonicsOnly{
//	return [self newScoredArrayForString:(NSString *)searchString inSet:(id)set mnemonicsOnly:(BOOL)mnemonicsOnly];
//	if (!set) set=defaultSearchSet;
//    NSDictionary *definedMnemonics=[[QSMnemonics sharedInstance]definedMnemonicsForString:searchString];
//    
//    NSEnumerator *enumer=[set objectEnumerator];
//    id thisObject;
//	
//    int count=[(NSArray *)set count];
//    NSMutableArray *rankObjects=[NSMutableArray arrayWithCapacity:count];
//    
//    QSRankedObject *rankedObject;
//    float scoreModifier=0.0;
//    NSDate *date=[NSDate date];
//    while ((thisObject=[enumer nextObject])){
//        rankedObject=makeRankObject(searchString,thisObject,scoreModifier,mnemonicsOnly,definedMnemonics);
//        if (rankedObject)
//            [rankObjects addObject:rankedObject];
//    }
//	[rankObjects makeObjectsPerformSelector:@selector(release)];
//    float speed=-[date timeIntervalSinceNow]/count;
//    if (count) searchSpeed=((speed+searchSpeed)/2.0f);
//	//   if (VERBOSE)QSLog(@"Ranking: %fms avg: %d탎",-([date timeIntervalSinceNow]*1000),(int)(speed*1000000));date=[NSDate date];
//    [rankObjects sortUsingSelector:@selector(scoreCompare:)];
//    //  QSLog(@"rank %@",rankObjects);
//    return rankObjects;
//}


- (NSMutableArray *)shelfNamed:(NSString *)shelfName{
    NSMutableArray *shelfArray=[shelfArrays objectForKey:shelfName];
    
    if (shelfName && !shelfArray){
        shelfArray=[NSMutableArray arrayWithCapacity:1];
        [shelfArrays setObject:shelfArray forKey:shelfName];
    }
    
    return shelfArray;
}

//
//- (void)registerActions:(id)actionObject{
//	[QSExec registerActions:(id)actionObject];
//}
//
//- (void)loadActionsForObject:(id)actionObject{
//	[QSExec loadActionsForObject:(id)actionObject];
//}

- (QSAction *)actionForIdentifier:(NSString *)identifier{
	return [QSExec  actionForIdentifier:(NSString *)identifier];
}

- (QSObject *)performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	return [QSExec performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject];
}

- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	return [QSExec rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject];
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	return [QSExec validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject];
	
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
    return [QSExec validIndirectObjectsForAction:action directObject:dObject];
}



//Accessors

- (QSCatalogEntry *)catalog { 
	return [[catalog retain] autorelease]; 
}

- (void)setCatalog:(QSCatalogEntry *)newCatalog {
	[catalog release];
    catalog = [newCatalog retain];
}


- (NSMutableSet *)defaultSearchSet { return [[defaultSearchSet retain] autorelease]; }

- (void)setDefaultSearchSet:(NSMutableSet *)newDefaultSearchSet {
    //QSLog(@"SetSet %@",newDefaultSearchSet);
    [defaultSearchSet autorelease];
    defaultSearchSet = [newDefaultSearchSet retain];
}


- (NSMutableDictionary *)appSearchArrays { return [[appSearchArrays retain] autorelease]; }

- (void)setAppSearchArrays:(NSMutableDictionary *)newAppSearchArrays {
    [appSearchArrays release];
    appSearchArrays = [newAppSearchArrays retain];
}


- (NSMutableDictionary *)catalogArrays { return [[catalogArrays retain] autorelease]; }

- (void)setCatalogArrays:(NSMutableDictionary *)newCatalogArrays {
    [catalogArrays release];
    catalogArrays = [newCatalogArrays retain];
}


- (NSMutableDictionary *)typeArrays { return [[typeArrays retain] autorelease]; }

- (void)setTypeArrays:(NSMutableDictionary *)newTypeArrays {
    [typeArrays release];
    typeArrays = [newTypeArrays retain];
}

- (NSMutableDictionary *)shelfArrays { return [[shelfArrays retain] autorelease]; }

- (void)setShelfArrays:(NSMutableDictionary *)newShelfArrays {
    [shelfArrays release];
    shelfArrays = [newShelfArrays retain];
}


- (QSTask *)scanTask {
    return [[scanTask retain] autorelease];
}

- (void)setScanTask:(QSTask *)value {
    if (scanTask != value) {
        [scanTask release];
        scanTask = [value retain];
    }
}



@end

@implementation QSLibrarian (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle{
#warning Make QSApp Protocol ?
	[self registerPresets:info inBundle: bundle scan:[/*(QSApp *)*/NSApp completedLaunch]];
	if ([NSApp completedLaunch]){
		[self reloadIDDictionary:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	}
	return YES;
}
@end