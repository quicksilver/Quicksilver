#import "QSDefaultsObjectSource.h"

#import "QSObject.h"

#import "QSObject_FileHandling.h"
#import "QSObject_URLHandling.h"
#import "QSObject_PropertyList.h"

#import "QSCatalogEntry.h"

#import "QSObject_StringHandling.h"
#import "NDAlias+QSMods.h"

#import "QSResourceManager.h"

#define kDefaultsObjectSourceBundleID @"bundle"
#define kDefaultsObjectSourceKeyList @"keypath"
#define kDefaultsObjectSourceType @"type"
#import "QSVoyeur.h"

@implementation QSDefaultsObjectSource

- (BOOL)isVisibleSource { return YES; }
- (BOOL)usesGlobalSettings { return NO; }

- (void)enableEntry:(QSCatalogEntry *)entry {
	NSDictionary *settings = entry.sourceSettings;
	if ([settings[@"watchTarget"] boolValue]) {
		NSString *path = [self prefFileForBundle:[settings objectForKey:kDefaultsObjectSourceBundleID]];
        // See VDKQueue.h for more information on queues
		[[QSVoyeur sharedInstance] addPath:path notifyingAbout:NOTE_DELETE | NOTE_WRITE];
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Watching Path %@", path);
#endif
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:entry selector:@selector(invalidateIndex:) name:nil object:path];
	}
}

- (NSView *)settingsView {
	if (![super settingsView])
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	return [super settingsView];
}
- (NSImage *)iconForEntry:(NSDictionary *)dict {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSString *bundlePath = [workspace absolutePathForAppBundleWithIdentifier:[[dict objectForKey:kItemSettings] objectForKey:kDefaultsObjectSourceBundleID]];
	NSImage *icon = nil;
	if (bundlePath)
		icon = [workspace iconForFile:bundlePath];
	if (icon) return icon;
	return [QSResourceManager imageNamed:@"DocPrefs"];
}

- (NSString *)prefFileForBundle:(NSString *)bundleID {
	return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", bundleID]];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	NSMutableDictionary *settings = [theEntry objectForKey:kItemSettings];
	if (![settings objectForKey:kDefaultsObjectSourceBundleID]) return YES;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *itemPath = [self prefFileForBundle:[settings objectForKey:kDefaultsObjectSourceBundleID]];
	if (![manager fileExistsAtPath:itemPath isDirectory:nil]) return YES;
	NSDate *modDate = [[manager attributesOfItemAtPath:itemPath error:NULL] fileModificationDate];
	if ([modDate compare:indexDate] == NSOrderedDescending) return NO; //FS item modification is more recent than index
	return YES;
	return [super indexIsValidFromDate:indexDate forEntry:theEntry];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	NSMutableDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSArray *keyList = [settings objectForKey:kDefaultsObjectSourceKeyList];
	NSString *applicationID = [settings objectForKey:kDefaultsObjectSourceBundleID];

	if (!(keyList && applicationID) ) return nil;
	NSMutableArray *array = [NSMutableArray array];
	id thisObject = nil;
	thisObject = [[NSDictionary dictionaryWithContentsOfFile:[self prefFileForBundle:applicationID]]objectForKey:[keyList objectAtIndex:0]];
	if (!thisObject) {
		CFPreferencesAppSynchronize ((__bridge CFStringRef) applicationID);
		thisObject = (__bridge_transfer NSArray *)CFPreferencesCopyAppValue((__bridge CFStringRef) [keyList objectAtIndex:0] , (__bridge CFStringRef) applicationID);
	}
	[self addObjectsForKeyList:keyList keyNumber:1 ofType:[[settings objectForKey:kDefaultsObjectSourceType] integerValue] inObject:thisObject toArray:array];
	return array;
}

- (void)addObjectsForKeyList:(NSArray *)keyList keyNumber:(NSUInteger)index ofType:(NSInteger)type inObject:(id)thisObject toArray:(NSMutableArray *)array {
  if ([keyList count] > index) {
    NSString *thisKey = [keyList objectAtIndex:index];
    if ([thisKey isEqualToString:@"*"]) {
        if ([thisObject isKindOfClass:[NSArray class]]) {
            for (id indexItem in thisObject) {
                [self addObjectsForKeyList:keyList keyNumber:index+1 ofType:type inObject:indexItem toArray:array];
            }
        } else if ([thisObject isKindOfClass:[NSDictionary class]]) {
            for (NSString *indexKey in [thisObject allKeys]) {
                [self addObjectsForKeyList:keyList keyNumber:index+1 ofType:type inObject:[thisObject objectForKey:indexKey] toArray:array];
            }
        }
    } else if ([thisObject isKindOfClass:[NSDictionary class]]) {
      [self addObjectsForKeyList:keyList keyNumber:index+1 ofType:type inObject:[thisObject objectForKey:thisKey] toArray:array];
    }/* else {
      //  if (VERBOSE) NSLog(@"can't parse object:\r %@\r%@\r%@", keyList, thisObject, array);
    }*/
  } else {
    NSString *path = nil;
    QSObject *newObject = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    switch (type) {
      case DefaultsPathEntry:
        newObject = [fm fileExistsAtPath:[(NSString *)thisObject stringByExpandingTildeInPath]] ?[QSObject fileObjectWithPath:thisObject] :nil;
        break;
      case DefaultsURLEntry:
        newObject = [QSObject URLObjectWithURL:thisObject title:nil];
        break;
      case DefaultsAliasEntry:
        path = [[NDAlias aliasWithData:thisObject] quickPath];
        if (path && [fm fileExistsAtPath:path])
          newObject = [QSObject fileObjectWithPath:path];
        else if ([NSURL respondsToSelector:@selector(URLByResolvingBookmarkData:options:relativeToURL:bookmarkDataIsStale:error:)]) {
          NSURL *fileURL = [NSURL URLByResolvingBookmarkData:thisObject options:NSURLBookmarkResolutionWithoutMounting relativeToURL:nil bookmarkDataIsStale:NO error:nil];
          path = [fileURL absoluteString];
          path = [path stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
          path = [path stringByReplacingOccurrencesOfString:@"file:/" withString:@""];
          path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
          if (path) newObject = [QSObject fileObjectWithPath:path];
        }
          break;
      case DefaultsTextEntry:
        newObject = [QSObject objectWithString:thisObject];
        break;
      case DefaultsFileDataEntry:
        path = [[NDAlias aliasWithData:[thisObject objectForKey:@"_CFURLAliasData"]]quickPath];
        if (path) {
          newObject = [fm fileExistsAtPath:path] ?[QSObject fileObjectWithPath:path] :nil;
        } else {
          newObject = [QSObject URLObjectWithURL:[thisObject objectForKey:@"_CFURLString"] title:nil];
        }
          break;
    }
    if (newObject)
      [array addObject:newObject];
  }
}

- (void)populateFields {
	NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
	NSArray *keys = [settings objectForKey:kDefaultsObjectSourceKeyList];
	[keyField setStringValue:(keys?[keys componentsJoinedByString:@"\n"] :@"")];
	[bundleIDField setStringValue:([settings objectForKey:kDefaultsObjectSourceBundleID] ? [settings objectForKey:kDefaultsObjectSourceBundleID] : @"")];
	[entryTypePopUp selectItemAtIndex:[entryTypePopUp indexOfItemWithTag:[[settings objectForKey:kDefaultsObjectSourceType] integerValue]]];
}

- (IBAction)setValueForSender:(id)sender {
	NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
	if (!settings) {
		settings = [NSMutableDictionary dictionaryWithCapacity:1];
		[[self currentEntry] setObject:settings forKey:kItemSettings];
	}
	if (sender == bundleIDField) {
		[settings setObject:[sender stringValue] forKey:kDefaultsObjectSourceBundleID];
	} else if (sender == keyField) {
		// NSLog(@"%@", [[sender stringValue] componentsSeparatedByString:@", "]);
		if ([[sender stringValue] length])
			[settings setObject:[[sender stringValue] componentsSeparatedByString:@"\n"] forKey:kDefaultsObjectSourceKeyList];
		else [settings removeObjectForKey:kDefaultsObjectSourceKeyList];
	} else if (sender == entryTypePopUp) {
		[settings setObject:[NSNumber numberWithInteger:[[sender selectedItem] tag]] forKey:kDefaultsObjectSourceType];
	}
    [self.selection refresh:NO];
	[self populateFields];
}

@end
