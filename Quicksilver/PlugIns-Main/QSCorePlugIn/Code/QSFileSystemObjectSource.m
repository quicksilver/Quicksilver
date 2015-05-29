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

#if 0
@implementation QSEncapsulatedTextCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	BOOL isFirstResponder = [[controlView window] firstResponder] == controlView && ![controlView isKindOfClass:[NSTableView class]];
	BOOL isKey = [[controlView window] isKeyWindow];
	if (isFirstResponder)
		[[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:(isKey?0.5:0.25)] set];
	else
		[[[NSColor blackColor] colorWithAlphaComponent:(isKey?0.10:0.05)] set];
	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:NSInsetRect(cellFrame, 0.5, 0.5) withRadius:NSHeight(cellFrame) /2];
	[roundRect fill];
	if (isFirstResponder)
		[[NSColor alternateSelectedControlColor] set];
	else
		[[NSColor grayColor] set];
	[roundRect stroke];
	[super drawWithFrame:cellFrame inView:controlView];
}
- (NSPoint)cellBaselineOffset { return NSZeroPoint; }
- (BOOL)wantsToTrackMouse { return nil; }
@end
#endif

//static NSMutableDictionary *typeSets;

@implementation QSFileSystemObjectSource
#if 0
+ (void)initialize {
	typeSets = [[NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FileTypeGroups" ofType:@"plist"]]retain];
	[typeSets setObject:[NSImage imageUnfilteredFileTypes] forKey:@"QSImageFileTypes"];
	[typeSets setObject:[NSMovie movieUnfilteredFileTypes] forKey:@"QSMovieFileTypes"];
	[typeSets setObject:[NSSound soundUnfilteredFileTypes] forKey:@"QSSoundFileTypes"];
}
#endif

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

#if 0
+ (NSMenu *)typeSetsMenu {

	NSMenu *typeSetsMenu = [[NSMenu alloc] initWithTitle:@"Types"];

	[typeSetsMenu addItemWithTitle:@"Add Set" action:nil keyEquivalent:@""];

	NSMenuItem *item;
	for(NSString *key in typeSets) {
		//  [[NSBundle mainBundle] localizedStringForKey:theID value:theID table:@"QSCatalogPreset.name"];

		item = (NSMenuItem *)[typeSetsMenu addItemWithTitle:[[NSBundle mainBundle] safeLocalizedStringForKey:key value:key table:@"FileTypeGroupNames"] action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
	item = (NSMenuItem *)[typeSetsMenu addItemWithTitle:@"Edit..." action:@selector(editSets:) keyEquivalent:@""];
	[item setTarget:self];

	return typeSetsMenu;
}
#endif

- (id)init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (NSImage *)iconForEntry:(NSDictionary *)entry {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSMutableDictionary *settings = [entry objectForKey:kItemSettings];
	if (!settings) return [workspace iconForFile:@"/Volumes"];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = [self fullPathForSettings:settings];
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

- (BOOL)selectionIsEditable { return ![[self selection] isPreset];  }

- (void)populateFields {
	NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];

	NSString *path = [settings objectForKey:kItemPath];
	[itemLocationField setStringValue:(path?path:@"")];
	NSString *fullPath = [self fullPathForSettings:settings];

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
	NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
	if (!settings) {
		settings = [NSMutableDictionary dictionaryWithCapacity:1];
		[[self currentEntry] setObject:settings forKey:kItemSettings];
	}

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
	[currentEntry setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
    
    [[self selection] scanAndCache];
	[self populateFields];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:[self currentEntry]];
}

- (BOOL)textShouldEndEditing:(NSText *)aTextObject { return YES;  }

#if 0
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView { return [typeSets count];  }
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"Set"]) {
		return [[typeSets allKeys] objectAtIndex:row];
		return @"name";
	} else if ([[tableColumn identifier] isEqualToString:@"Types"]) {
		return [[typeSets objectForKey:[[typeSets allKeys] objectAtIndex:row]]componentsJoinedByString:@", "];
	}
	return nil;
}
#endif

- (IBAction)endContainingSheet:(id)sender {
	NSWindow *win = [sender window];
	[win makeFirstResponder:win];
	[NSApp endSheet:win];
	[win orderOut:self];
}

- (void)enableEntry:(QSCatalogEntry *)entry {
	NSMutableDictionary *settings = entry.sourceSettings;
	NSString *path = [self fullPathForSettings:settings];
	NSNotificationCenter *wsNotif = [[NSWorkspace sharedWorkspace] notificationCenter];
	if ([settings[@"watchTarget"] boolValue]) {
		[[QSVoyeur sharedInstance] addPath:path notifyingAbout:NOTE_DELETE | NOTE_WRITE];
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Watching Path %@", path);
#endif
		[wsNotif addObserver:entry selector:@selector(invalidateIndex:) name:nil object:path];
	}
	NSArray *paths = settings[@"watchPaths"];
	for (NSString * p in paths) {
		[[QSVoyeur sharedInstance] addPath:p];
#ifdef DEBIG
		if (VERBOSE) NSLog(@"Watching Path %@", p);
#endif
		[wsNotif addObserver:entry selector:@selector(invalidateIndex:) name:VDKQueueWriteNotification object:p];
	}
}

- (void)disableEntry:(QSCatalogEntry *)entry {
	NSMutableDictionary *settings = entry.sourceSettings;
	NSString *path = [self fullPathForSettings:settings];
	if ([settings[@"watchTarget"] boolValue]) {
		[[QSVoyeur sharedInstance] removePath:path];
		[[NSNotificationCenter defaultCenter] removeObserver:entry];
	}
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	NSMutableDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = nil;
	NSMutableArray *containedItems = [NSMutableArray arrayWithCapacity:1];

	path = [self fullPathForSettings:settings];

	if (![manager fileExistsAtPath:path isDirectory:nil]) return [NSArray array];
	if ([[settings objectForKey:@"watchTarget"] boolValue]) {
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

- (IBAction)showFile:(id)sender { [[NSWorkspace sharedWorkspace] selectFile:[self fullPathForSettings:[[self currentEntry] objectForKey:kItemSettings]] inFileViewerRootedAtPath:@""];  }

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
	[[self selection] setName:[[openPanel URL] lastPathComponent]];
	[currentEntry setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:[self currentEntry]];
	return YES;
}

- (NSString *)fullPathForSettings:(NSDictionary *)settings {
	if (![settings objectForKey:kItemPath]) return nil;
	NSString *itemPath = [[settings objectForKey:kItemPath] stringByResolvingWildcardsInPath];
	if (![itemPath isAbsolutePath]) {
		NSString *bundlePath = [[QSReg bundleWithIdentifier:[settings objectForKey:kItemBaseBundle]] bundlePath];
		if (!bundlePath) bundlePath = [[NSBundle mainBundle] bundlePath];
		itemPath = [bundlePath stringByAppendingPathComponent:itemPath];
	}
	return itemPath;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	NSMutableDictionary *settings = [theEntry objectForKey:kItemSettings];

    if ([[settings objectForKey:@"watchTarget"] boolValue]) {
        // no need to scan - this entry is updated automatically
        return YES;
    }
	NSString *itemPath = [self fullPathForSettings:settings];
	if (!itemPath) return YES;

	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:itemPath isDirectory:nil]) return YES;

	NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[[settings objectForKey:kItemModificationDate] doubleValue]];

	if ([specDate compare:indexDate] == NSOrderedDescending) return NO; //Catalog Specification is more recent than index

	NSNumber *depth = [settings objectForKey:kItemFolderDepth];
	 NSDate *modDate = [manager path:itemPath wasModifiedAfter:indexDate depth:[depth integerValue]];
	 return modDate == nil;
}

@end
