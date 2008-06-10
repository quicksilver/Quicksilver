#import <QSCrucible/NDAlias.h>

#import "QSDefaultsObjectSource.h"

#define kDefaultsObjectSourceBundleID @"bundle"
#define kDefaultsObjectSourceKeyList @"keypath"
#define kDefaultsObjectSourceType @"type"

@implementation QSDefaultsObjectSource
/*
 - (id) init{
	 if ((self=[super init])){
		 defaultsModifiedDate=[NSDate timeIntervalSinceReferenceDate];
		 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateSelf) name:kABDatabaseChangedExternallyNotification object:nil];
	 }
	 return self;
 }
 - (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	 return ([indexDate timeIntervalSinceReferenceDate]>defaultsModifiedDate);
 }
 
 - (void)invalidateSelf{
	 defaultsModifiedDate=[NSDate timeIntervalSinceReferenceDate];
	 [super invalidateSelf];
 }
 */


- (BOOL)isVisibleSource{return fALPHA;}
- (BOOL)usesGlobalSettings{return NO;}

- (void)enableEntry:(QSCatalogEntry *)entry{
	if (!fALPHA) return;
	NSMutableDictionary *settings=[[entry info] objectForKey:kItemSettings];
	   NSString *path=[self prefFileForBundle:[settings objectForKey:kDefaultsObjectSourceBundleID]];

	if ([[settings objectForKey:@"watchTarget"]boolValue]){
		[[QSVoyeur sharedInstance]addPathToQueue:path notifyingAbout:UKKQueueNotifyAboutDelete|UKKQueueNotifyAboutWrite];
		if (VERBOSE)QSLog(@"Watching Path %@",path);
		[[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:entry 
															  selector:@selector(invalidateIndex:)
																  name:nil
																object:path];
	}    
}

- (NSView *) settingsView{
    if (![super settingsView])
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
    return [super settingsView];
}
- (NSImage *) iconForEntry:(NSDictionary *)dict{
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    NSString *bundlePath=[workspace absolutePathForAppBundleWithIdentifier:
        [[dict objectForKey:kItemSettings] objectForKey:kDefaultsObjectSourceBundleID]];
    
    NSImage *icon=nil;
    if (bundlePath)
        icon=[workspace iconForFile:bundlePath];
    if (icon) return icon;
	
    return [NSImage imageNamed:@"DocPrefs"];
}

- (NSString *)prefFileForBundle:(NSString *)bundleID{
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/"]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",bundleID]];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
    NSMutableDictionary *settings=[theEntry objectForKey:kItemSettings];
    if (![settings objectForKey:kDefaultsObjectSourceBundleID]) return YES;
    NSFileManager *manager=[NSFileManager defaultManager];
    NSString *itemPath=[self prefFileForBundle:[settings objectForKey:kDefaultsObjectSourceBundleID]];
    if (![manager fileExistsAtPath:itemPath isDirectory:nil]) return YES;
    NSDate *modDate=[[manager fileAttributesAtPath:itemPath traverseLink:NO]fileModificationDate];
    if ([modDate compare:indexDate]==NSOrderedDescending)return NO; //FS item modification is more recent than index
    return YES;
    return [super indexIsValidFromDate:indexDate forEntry:theEntry];
}

- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{
    NSMutableDictionary *settings=[theEntry objectForKey:kItemSettings];
    NSArray *keyList=[settings objectForKey:kDefaultsObjectSourceKeyList];
    NSString *applicationID=[settings objectForKey:kDefaultsObjectSourceBundleID];
    
    if (!(keyList && applicationID)) return nil;
    NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
    
    id thisObject=nil;
    
    thisObject=[[NSDictionary dictionaryWithContentsOfFile:[self prefFileForBundle:applicationID]]objectForKey:[keyList objectAtIndex:0]];
    
    
    if (!thisObject){
        //QSLog(@"Using CFPreferences to access bundle: %@",applicationID);
        CFPreferencesAppSynchronize ((CFStringRef) applicationID);
        thisObject= (NSArray *)CFPreferencesCopyAppValue((CFStringRef) [keyList objectAtIndex:0],(CFStringRef) applicationID);
        [thisObject autorelease];
    }    
    
    
    [self addObjectsForKeyList:keyList keyNumber:1 ofType:[[settings objectForKey:kDefaultsObjectSourceType]intValue] inObject:thisObject toArray:array];
    return array;
}

- (void)addObjectsForKeyList:(NSArray *)keyList keyNumber:(int)index ofType:(int)type inObject:(id)thisObject toArray:(NSMutableArray *)array{
	
    if ([keyList count]>index){
        NSString *thisKey=[keyList objectAtIndex:index];
		// QSLog(thisKey);
		
        if ([thisKey isEqualToString:@"*"] && [thisObject isKindOfClass:[NSArray class]]){
            int i;
            
            for (i=0 ;i<[(NSArray *)thisObject count];i++){
                [self addObjectsForKeyList:keyList keyNumber:index+1 ofType:type inObject:[thisObject objectAtIndex:i] toArray:array];
            }
        }else if ([thisObject isKindOfClass:[NSDictionary class]]){
            [self addObjectsForKeyList:keyList keyNumber:index+1 ofType:type inObject:[thisObject objectForKey:thisKey] toArray:array];
        }else{
			//   if (VERBOSE) QSLog(@"can't parse object:\r %@\r%@\r%@",keyList,thisObject,array);  
        }
    }else{
        NSString *path=nil;
        QSObject *newObject=nil;
		NSFileManager *fm=[NSFileManager defaultManager];
        switch (type){
            case DefaultsPathEntry:
                newObject=[fm fileExistsAtPath:thisObject]?[QSObject fileObjectWithPath:thisObject]:nil;
                break;
            case DefaultsURLEntry:
                newObject=[QSObject URLObjectWithURL:thisObject title:nil];
                break;
            case DefaultsAliasEntry:
                path=[[NDAlias aliasWithData:thisObject]quickPath];
                if (path && [fm fileExistsAtPath:path])
                    newObject=[QSObject fileObjectWithPath:path];
                    break;
            case DefaultsTextEntry:
                newObject=[QSObject objectWithString:thisObject];
                break;
            case DefaultsFileDataEntry:
				
				// initWithCoder
                path=[[NDAlias aliasWithData:[thisObject objectForKey:@"_CFURLAliasData"]]quickPath];
                
                if (path){
                    newObject=[fm fileExistsAtPath:path]?[QSObject fileObjectWithPath:path]:nil;
				} else{
                    newObject=[QSObject URLObjectWithURL:[thisObject objectForKey:@"_CFURLString"] title:nil];
				}
					break;
                
        }
        
        if (newObject)
			[array addObject:newObject];
    }
}

- (void)populateFields{    
    NSMutableDictionary *settings=[[self currentEntry] objectForKey:kItemSettings];
    NSArray *keys=[settings objectForKey:kDefaultsObjectSourceKeyList];
    [keyField setStringValue:(keys?[keys componentsJoinedByString:@"\n"]:@"")];
    [bundleIDField setStringValue:([settings objectForKey:kDefaultsObjectSourceBundleID]?[settings objectForKey:kDefaultsObjectSourceBundleID]:@"")];
	[entryTypePopUp selectItemAtIndex:[entryTypePopUp indexOfItemWithTag:[[settings objectForKey:kDefaultsObjectSourceType]intValue]]];
}

- (IBAction)setValueForSender:(id)sender{
    NSMutableDictionary *settings=[[self currentEntry] objectForKey:kItemSettings];
    if (!settings){
        settings=[NSMutableDictionary dictionaryWithCapacity:1];
        [[self currentEntry] setObject:settings forKey:kItemSettings];
    }
    if (sender==bundleIDField){
        [settings setObject:[sender stringValue] forKey:kDefaultsObjectSourceBundleID];
    }
    else if (sender==keyField){
        // QSLog(@"%@",[[sender stringValue]componentsSeparatedByString:@","]);
        if ([[sender stringValue]length])
            [settings setObject:[[sender stringValue]componentsSeparatedByString:@"\n"] forKey:kDefaultsObjectSourceKeyList];
        else [settings removeObjectForKey:kDefaultsObjectSourceKeyList];
    }
	else if (sender==entryTypePopUp){
        [settings setObject:[NSNumber numberWithInt:[[sender selectedItem]tag]] forKey:kDefaultsObjectSourceType];
    }
    [[self currentEntry] setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate]; 
    [self populateFields];    
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
}

@end
