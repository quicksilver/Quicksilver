#import "QSFileSystemObjectSource.h"
#import "QSParser.h"
#import "QSObject.h"
#import "QSObjectCell.h"

#import "QSLibrarian.h"
#import "QSRegistry.h"
#import "QSLocalization.h"

#import "QSNotifications.h"
#import "QSVoyeur.h"

#import "QSObject_FileHandling.h"

#import "QSUTI.h"

#import "NSBundle_BLTRExtensions.h"

@implementation QSFileSystemObjectSource

+ (NSMenu *)parserMenuForPath:(NSString *)path {
	NSMenu *_parserMenu = [[NSMenu alloc] initWithTitle:kQSFSParsers];

	[_parserMenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
	[_parserMenu addItem:[NSMenuItem separatorItem]];
	NSMutableDictionary *parsers = [QSReg instancesForTable:kQSFSParsers];

	NSMenuItem *item;
	for(NSString *key in parsers) {
		if (![[parsers objectForKey:key] validParserForPath:path]) continue;

		NSString *title = [[NSBundle bundleForClass:NSClassFromString(key)] safeLocalizedStringForKey:key value:key table:@"QSParser.name"];
		if ([title isEqualToString:key]) title = [[NSBundle mainBundle] safeLocalizedStringForKey:key value:key table:@"QSParser.name"];

		item = (NSMenuItem *)[_parserMenu addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
	return _parserMenu;
}

- (id)init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (NSImage *)iconForEntry:(QSCatalogEntry *)entry {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSMutableDictionary *settings = entry.sourceSettings;
	if (!settings) return [workspace iconForFile:@"/Volumes"];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = entry.fullWatchPath;
	BOOL isDirectory, exists;
	exists = [manager fileExistsAtPath:path isDirectory:&isDirectory];
	NSImage *theImage = (exists?[workspace iconForFile:path] : [QSResourceManager imageNamed:@"Question"]);
	[theImage setSize:QSSize16];
	return theImage;
	// [aCell setTextColor:(exists?[NSColor blackColor] :[NSColor grayColor])];
}

- (BOOL)isVisibleSource {return YES;}
- (BOOL)usesGlobalSettings {return NO;}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    NSString * type = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)representedObject, kUTTagClassFilenameExtension);
    if (!type) {
        return representedObject;
    }
	return type;
}

- (NSString *)UTIForString:(NSString *)editingString {
    if (QSIsUTI(editingString)) {
        // editing string is already a UTI
        return editingString;
    }
    
    NSString *type = nil;
    // Try to get the UTI from the extension/string
    if ([editingString hasPrefix:@"'"]) {
        // 'xxxx' strings are OS types
        // p_j_r WARNING When a UTI manager is created, the trimming business should be dealt with there
        NSString *OSTypeAsString = [editingString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'"]];
        type = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, (__bridge CFStringRef)OSTypeAsString, NULL);
        if ([type hasPrefix:@"dyn"]) {
            // some OS types are all uppercase (e.g. 'APPL' == application, 'fold' == folder), some are all lower. Be forgiving to the user
            for (NSString *caseChangedOSType in @[[OSTypeAsString uppercaseString], [OSTypeAsString lowercaseString]]) {
                NSString *testType = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, (__bridge CFStringRef)caseChangedOSType, NULL);
                if (![testType hasPrefix:@"dyn"]) {
                    type = testType;
                    break;
                }
            }
        }
    } else if ([[editingString lowercaseString] isEqualToString:@"folder"]) {
        // if the user has entered 'folder' (to exclude a folder), return its UTI
        type = (NSString *)kUTTypeFolder;
    } else {
        if ([editingString hasPrefix:@"."]) {
            editingString = [editingString substringFromIndex:1];
        }
        type = QSUTIForExtensionOrType(editingString, 0);
    }
	return type;
}

// The represented object should always be a UTI
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    return [self UTIForString:editingString];
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
    return UTTypeConformsTo((__bridge CFStringRef)representedObject, (__bridge CFStringRef)@"public.item");
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *menuItem = [NSMenuItem new];
    [menuItem setTitle:representedObject];
    [menu addItem:menuItem];
	return menu;
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    
	NSString *description = (__bridge_transfer NSString *)UTTypeCopyDescription((__bridge CFStringRef)representedObject);
	if (!description || [description isEqualToString:@"content"]) {
        // show the file extension if there's no description, or if is the unhelpful 'content' string
        NSString *fileExtension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)representedObject, kUTTagClassFilenameExtension);
        if (!fileExtension && QSIsUTI(representedObject)) {
            return representedObject;
        }
        return [NSString stringWithFormat:@".%@", fileExtension ? fileExtension : representedObject];
	}
	return description;
}

- (NSView *)settingsView {
	if (![super settingsView])
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	return [super settingsView];
}

- (BOOL)selectionIsEditable { return !self.selectedEntry.isPreset; }

- (void)populateFields {
	NSMutableDictionary *settings = self.selectedEntry.sourceSettings;

	NSString *path = [settings objectForKey:kItemPath];
	[itemLocationField setStringValue:(path ? path : @"")];
	NSString *fullPath = self.selectedEntry.fullWatchPath;

	NSString *parser = [settings objectForKey:kItemParser];

	[itemParserPopUp setMenu:[QSFileSystemObjectSource parserMenuForPath:fullPath]];

	NSInteger parserEntry = [itemParserPopUp indexOfItemWithRepresentedObject:parser];
	[itemParserPopUp selectItemAtIndex:(parserEntry == -1?0:parserEntry)];

	BOOL isDirectory, exists;
	exists = fullPath && [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];

	if ([[settings objectForKey:kItemParser] isEqualToString:@"QSDirectoryParser"] && (exists) ) {
		[itemOptionsView setContentView:itemFolderOptions];
		NSNumber *depth = [settings objectForKey:kItemFolderDepth];
		NSInteger depthInt = (depth?[depth integerValue] : 1);
		if (depthInt == -1 || depthInt > 8) depthInt = 8;
		[itemFolderDepthSlider setDoubleValue:9-depthInt];
	} else {
		[itemOptionsView setContentView:nil];
	}

	bool validItem = (settings != nil);

	[itemLocationShowButton setEnabled:exists];

	[itemSkipItemSwitch setState:([[settings objectForKey:kItemSkipItem] boolValue])];
	[itemSkipItemSwitch setEnabled:parserEntry >= 0];
	[itemParserPopUp setEnabled:validItem];
	[itemLocationField setEnabled:YES];
}

//Item Fields

- (IBAction)setValueForSender:(id)sender {
	NSMutableDictionary *settings = self.selectedEntry.sourceSettings;

	if (sender == itemLocationField) {
        // Box showing the path to the current catalog item
		[settings setObject:[sender stringValue] forKey:kItemPath];
    }
	else if (sender == itemSkipItemSwitch) {
        // "Omit source" checkbox
		[settings setObject:[NSNumber numberWithBool:[(NSButton *)sender state]] forKey:kItemSkipItem];
    }
	else if (sender == itemFolderDepthSlider) {
        // Slider for setting depth
		NSInteger depth = (9-[itemFolderDepthSlider integerValue]);
		if (depth>7) depth = -1;
		[settings setObject:[NSNumber numberWithInteger:depth] forKey:kItemFolderDepth];
	} else if (sender == itemParserPopUp) {
        // 'Include Contents' popup menu
		NSString *parserName = [[sender selectedItem] representedObject];
		if (parserName)
			[settings setObject:[[sender selectedItem] representedObject] forKey:kItemParser];
		else
			[settings removeObjectForKey:kItemParser];
	}
    [self.selectedEntry refresh:YES];
	[self populateFields];
}

- (BOOL)textShouldEndEditing:(NSText *)aTextObject { return YES;  }

- (IBAction)endContainingSheet:(id)sender {
	NSWindow *win = [sender window];
	[win makeFirstResponder:win];
	[NSApp endSheet:win];
	[win orderOut:self];
}

- (void)enableEntry:(QSCatalogEntry *)entry {
	if (entry.watchTarget) {
		[entry enableWatching];
	}
}

- (void)disableEntry:(QSCatalogEntry *)entry {
	if (entry.watchTarget) {
		[entry disableWatching];
	}
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
	NSMutableDictionary *settings = theEntry.sourceSettings;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = nil;
	NSMutableArray *containedItems = [NSMutableArray arrayWithCapacity:1];

	path = theEntry.fullWatchPath;

	if (![manager fileExistsAtPath:path isDirectory:nil]) return [NSArray array];
	if (theEntry.watchTarget) {
		[[QSVoyeur sharedInstance] addPath:path];
	}

	NSString *parser = [settings objectForKey:kItemParser];

	if (parser) {
		id instance = [QSReg getClassInstance:parser];
		[containedItems setArray:[instance objectsFromPath:path withSettings:settings]];
	}

	if (!parser || ![[settings objectForKey:kItemSkipItem] boolValue]) {
		QSObject *mainObject = [QSObject fileObjectWithPath:path];
		[containedItems addObject:mainObject];
	}
	return containedItems;
}

- (IBAction)showFile:(id)sender {
    NSString *filePath = self.selectedEntry.fullWatchPath;
    [[NSWorkspace sharedWorkspace] selectFile:filePath inFileViewerRootedAtPath:@""];
}

- (IBAction)chooseFile:(id)sender { [self chooseFile];  }

- (BOOL)chooseFile {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSString *oldFile = [[itemLocationField stringValue] stringByStandardizingPath];
	[openPanel setCanChooseDirectories:YES];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[oldFile stringByDeletingLastPathComponent]]];

    // open the choose file dialog box
	NSInteger result = [openPanel runModal];
    
    // user clicked cancel
    if (result == NSFileHandlingPanelCancelButton) {
        return NO;
    }
    
	[itemLocationField setStringValue:[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath]];
	[self setValueForSender:itemLocationField];
	self.selectedEntry.name = [[openPanel URL] lastPathComponent];
    [self.selectedEntry refresh:NO];
	return YES;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
	NSMutableDictionary *settings = theEntry.sourceSettings;

    if (theEntry.watchTarget) {
        // no need to scan - this entry is updated automatically
        return YES;
    }
	NSString *itemPath = theEntry.fullWatchPath;
	if (!itemPath) return YES;

	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:itemPath isDirectory:nil]) return YES;

	if ([theEntry.modificationDate compare:indexDate] == NSOrderedDescending) return NO; //Catalog Specification is more recent than index

	NSNumber *depth = [settings objectForKey:kItemFolderDepth];
    NSDate *modDate = [manager path:itemPath wasModifiedAfter:indexDate depth:[depth integerValue]];
    return modDate == nil;
}

@end

@implementation QSCatalogEntry (QSFileSystemObjectSource)

- (void)setWatchTarget:(BOOL)shouldWatch {
	[self willChangeValueForKey:kQSWatchTarget];
	[self.sourceSettings setObject:[NSNumber numberWithBool:shouldWatch] forKey:kQSWatchTarget];
	[self didChangeValueForKey:kQSWatchTarget];
	if (shouldWatch) {
		[self enableWatching];
	} else {
		[self disableWatching];
	}
}

- (BOOL)watchTarget {
	return [[self.sourceSettings objectForKey:kQSWatchTarget] boolValue];
}

- (void)enableWatching {
	NSMutableDictionary *settings = self.sourceSettings;
	NSString *path = self.fullWatchPath;
	NSNotificationCenter *wsNotif = [[NSWorkspace sharedWorkspace] notificationCenter];
	[[QSVoyeur sharedInstance] addPath:path notifyingAbout:NOTE_DELETE | NOTE_WRITE];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Watching Path %@", path);
#endif
	[wsNotif addObserver:self selector:@selector(invalidateIndex:) name:nil object:path];
	NSArray *paths = settings[kQSWatchPaths];
	for (NSString * p in paths) {
		[[QSVoyeur sharedInstance] addPath:p];
#ifdef DEBIG
		if (VERBOSE) NSLog(@"Watching Path %@", p);
#endif
		[wsNotif addObserver:self selector:@selector(invalidateIndex:) name:VDKQueueWriteNotification object:p];
	}
}

- (void)disableWatching {
	#ifdef DEBUG
		if (VERBOSE) NSLog(@"Disable watching path %@", self.fullWatchPath);
	#endif
	NSNotificationCenter *wsNotif = [[NSWorkspace sharedWorkspace] notificationCenter];
	[[QSVoyeur sharedInstance] removePath:self.fullWatchPath];
	[wsNotif removeObserver:self];
	for (NSString *p in self.sourceSettings[kQSWatchPaths]) {
		[[QSVoyeur sharedInstance] removePath:p];
		[wsNotif removeObserver:self name:VDKQueueWriteNotification object:p];
	}
}

- (NSString *)fullWatchPath {
	NSDictionary *settings = self.sourceSettings;
	if (![settings objectForKey:kItemPath]) return nil;
	NSString *itemPath = [[settings objectForKey:kItemPath] stringByResolvingWildcardsInPath];
	if (![itemPath isAbsolutePath]) {
		NSString *bundlePath = [[QSReg bundleWithIdentifier:[settings objectForKey:kItemBaseBundle]] bundlePath];
		if (!bundlePath) bundlePath = [[NSBundle mainBundle] bundlePath];
		itemPath = [bundlePath stringByAppendingPathComponent:itemPath];
	}
	return itemPath;
}

@end
