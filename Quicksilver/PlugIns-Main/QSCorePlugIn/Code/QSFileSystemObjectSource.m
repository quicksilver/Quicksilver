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

#include "QSUTI.h"

#import "NSBundle_BLTRExtensions.h"

#import "QSFeatureLevel.h"

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
	NSEnumerator *keyEnum = [parsers keyEnumerator];
	NSString *key;
	for(key in keyEnum) {
		if (![[parsers objectForKey:key] validParserForPath:path]) continue;

		NSString *title = [[NSBundle bundleForClass:NSClassFromString(key)] safeLocalizedStringForKey:key value:key table:@"QSParser.name"];
		if ([title isEqualToString:key]) title = [[NSBundle mainBundle] safeLocalizedStringForKey:key value:key table:@"QSParser.name"];

		item = (NSMenuItem *)[_parserMenu addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
	return [_parserMenu autorelease];
}

#if 0
+ (NSMenu *)typeSetsMenu {

	NSMenu *typeSetsMenu = [[NSMenu alloc] initWithTitle:@"Types"];

	NSEnumerator *keyEnumerator = [typeSets keyEnumerator];
	NSString *key;
	[typeSetsMenu addItemWithTitle:@"Add Set" action:nil keyEquivalent:@""];

	NSMenuItem *item;
	for(key in keyEnumerator) {
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
	NSImage *theImage = (exists?[workspace iconForFile:path] : [NSImage imageNamed:@"Question"]);
	[theImage setSize:NSMakeSize(16, 16)];
	return theImage;
	// [aCell setTextColor:(exists?[NSColor blackColor] :[NSColor grayColor])];
}

- (BOOL)isVisibleSource {return YES;}
- (BOOL)usesGlobalSettings {return NO;}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
	return representedObject;
}
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
	NSString *type = QSUTIForAnyTypeString(editingString);
	if (!type) {
		if ([editingString hasPrefix:@"'"])
			return editingString;
		if ([editingString hasPrefix:@"."])
			return [editingString substringFromIndex:1];
		type = editingString;
	}
	return type;
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
	if ([representedObject hasPrefix:@"'"] || [representedObject hasPrefix:@"."])
		return NO;
	return YES;
}
#if 0
- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	NSString *desc;
	desc = (NSString *)UTTypeCopyDeclaration((CFStringRef)representedObject);
	NSArray *conforms = [desc objectForKey:(NSString *)kUTTypeConformsToKey];
	[desc release];
	if (conforms) {
		if (![conforms isKindOfClass:[NSArray class]]) conforms = [NSArray arrayWithObject:conforms];
		for(NSString * type in conforms){
			desc = (NSString *)UTTypeCopyDescription((CFStringRef)type);
			[menu addItemWithTitle:desc action:nil keyEquivalent:@""];
			[desc release];
		}
	}
	return [menu autorelease];
}
#else
- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject {
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSArray *conforms = [[(NSString *)UTTypeCopyDeclaration((CFStringRef)representedObject) autorelease] objectForKey:(NSString *)kUTTypeConformsToKey];
	if (conforms) {
		if (![conforms isKindOfClass:[NSArray class]]) conforms = [NSArray arrayWithObject:conforms];
		for(NSString * type in conforms)
			[menu addItemWithTitle:[(NSString *)UTTypeCopyDescription((CFStringRef)type) autorelease] action:nil keyEquivalent:@""];
	}
	return menu;
}
#endif

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
	NSString *description = (NSString *)UTTypeCopyDescription((CFStringRef)representedObject);
	if (!description) {
		if ([representedObject hasPrefix:@"'"])
			return [@"Type: " stringByAppendingString:representedObject];
		else if ([representedObject rangeOfString:@"."].location == NSNotFound)
			return [@"." stringByAppendingString:representedObject];
		description = representedObject;
	}
	return [description autorelease];
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

	int parserEntry = [itemParserPopUp indexOfItemWithRepresentedObject:parser];
	[itemParserPopUp selectItemAtIndex:(parserEntry == -1?0:parserEntry)];

	BOOL isDirectory, exists;
	exists = fullPath && [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];

	if ([[settings objectForKey:kItemParser] isEqualToString:@"QSDirectoryParser"] && (exists) ) {
		[itemOptionsView setContentView:itemFolderOptions];
		NSNumber *depth = [settings objectForKey:kItemFolderDepth];
		int depthInt = (depth?[depth intValue] : 1);
		if (depthInt == -1 || depthInt > 8) depthInt = 8;
		[itemFolderDepthSlider setFloatValue:9-depthInt];
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

	if (sender == itemLocationField)
		[settings setObject:[sender stringValue] forKey:kItemPath];
	else if (sender == itemSkipItemSwitch)
		[settings setObject:[NSNumber numberWithBool:[sender state]] forKey:kItemSkipItem];
	else if (sender == itemFolderDepthSlider) {
		int depth = (9-[itemFolderDepthSlider intValue]);
		if (depth>7) depth = -1;
		[settings setObject:[NSNumber numberWithInt:depth] forKey:kItemFolderDepth];
	} else if (sender == itemParserPopUp) {
		NSString *parserName = [[sender selectedItem] representedObject];
		if (parserName)
			[settings setObject:[[sender selectedItem] representedObject] forKey:kItemParser];
		else
			[settings removeObjectForKey:kItemParser];
	}
	[currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
	[self populateFields];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
}

- (BOOL)textShouldEndEditing:(NSText *)aTextObject { return YES;  }

#if 0
- (int) numberOfRowsInTableView:(NSTableView *)tableView { return [typeSets count];  }
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
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
	if (!fALPHA) return;
	NSMutableDictionary *settings = [[entry info] objectForKey:kItemSettings];
	NSString *path = [self fullPathForSettings:settings];
	NSNotificationCenter *wsNotif = [[NSWorkspace sharedWorkspace] notificationCenter];
	if ([[settings objectForKey:@"watchTarget"] boolValue]) {
		[[QSVoyeur sharedInstance] addPathToQueue:path notifyingAbout:UKKQueueNotifyAboutDelete | UKKQueueNotifyAboutWrite];
		if (VERBOSE) NSLog(@"Watching Path %@", path);
		[wsNotif addObserver:entry selector:@selector(invalidateIndex:) name:nil object:path];
	}
	NSArray *paths = [settings objectForKey:@"watchPaths"];
	for (NSString * p in paths) {
		[[QSVoyeur sharedInstance] addPathToQueue:p];
		if (VERBOSE) NSLog(@"Watching Path %@", p);
		[wsNotif addObserver:entry selector:@selector(invalidateIndex:) name:UKKQueueFileWrittenToNotification object:p];
	}
}

- (void)disableEntry:(QSCatalogEntry *)entry {
	if (!fALPHA) return;
	NSMutableDictionary *settings = [[entry info] objectForKey:kItemSettings];
	NSString *path = [self fullPathForSettings:settings];
	if ([[settings objectForKey:@"watchTarget"] boolValue]) {
		[[QSVoyeur sharedInstance] removePathFromQueue:path];
		[[NSNotificationCenter defaultCenter] removeObserver:entry];
	}
}

- (NSArray *)objectsForEntry:(NSMutableDictionary *)theEntry {
	NSMutableDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory; //, scanContents;
	NSString *path = nil;
	NSMutableArray *containedItems = [NSMutableArray arrayWithCapacity:1];

	path = [self fullPathForSettings:settings];

	if (![manager fileExistsAtPath:path isDirectory:&isDirectory]) return [NSArray array];
	if ([[settings objectForKey:@"watchTarget"] boolValue]) {
		[[QSVoyeur sharedInstance] addPathToQueue:path];
	}

	NSString *parser = [settings objectForKey:kItemParser];

	if (parser) {
		id instance = [QSReg getClassInstance:parser];
		[containedItems setArray:[instance objectsFromPath:path withSettings:settings]];
	}

	if (!parser || ![[settings objectForKey:kItemSkipItem] boolValue]) {
		QSObject *mainObject = [QSObject fileObjectWithPath:path];
		NSString *name = [theEntry objectForKey:kItemName];
		if (!QSGetLocalizationStatus() && !name) {
			NSString *theID = [theEntry objectForKey:kItemID];
			if ([theID hasPrefix:@"QSPreset"])
				name = [[NSBundle mainBundle] safeLocalizedStringForKey:theID value:theID table:@"QSCatalogPreset.name"];
		}
		if (name) [mainObject setLabel:name];

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
	if (![openPanel runModalForDirectory:[oldFile stringByDeletingLastPathComponent] file:[oldFile lastPathComponent] types:nil]) return NO;
	[itemLocationField setStringValue:[[openPanel filename] stringByAbbreviatingWithTildeInPath]];
	[self setValueForSender:itemLocationField];
	[[self selection] setName:[[openPanel filename] lastPathComponent]];
	[currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
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

	NSString *itemPath = [self fullPathForSettings:settings];
	if (!itemPath) return YES;

	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:itemPath isDirectory:nil]) return YES;

	NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[[settings objectForKey:kItemModificationDate] floatValue]];

	if ([specDate compare:indexDate] == NSOrderedDescending) return NO; //Catalog Specification is more recent than index

	NSNumber *depth = [settings objectForKey:kItemFolderDepth];
	 NSDate *modDate = [manager path:itemPath wasModifiedAfter:indexDate depth:[depth intValue]];
	 return modDate == nil;
}

@end
