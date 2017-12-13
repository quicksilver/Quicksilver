//
// QSWebSource.m
// Quicksilver
//
// Created by Alcor on 7/9/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSWebSource.h"
#import "QSRegistry.h"
#import "QSKeys.h"
#import "QSParser.h"
#import "QSHTMLLinkParser.h"
#import "QSFoundation.h"

@implementation QSWebSource

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry {
	return [QSResourceManager imageNamed:@"DefaultBookmarkIcon"];
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
    NSMutableDictionary *settings = theEntry.sourceSettings;
	NSString *location = [settings objectForKey:kItemPath];
	if (location) {
		NSArray *contents = [(QSHTMLLinkParser *)[QSReg getClassInstance:@"QSHTMLLinkParser"] objectsFromURL:[NSURL URLWithString:location] withSettings:settings];
		if (contents) {
			return contents;
		}
		// return the original contents of the catalog entry if there was a problem getting data from the internet
		return [QSLib entryForID:theEntry.identifier].contents;
    }
    return nil;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
	return YES;
}

- (BOOL)isVisibleSource
{
	return YES;
}

- (NSView *)settingsView
{
	if (![super settingsView]) {
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
	return [super settingsView];
}

- (void)populateFields
{
	NSMutableDictionary *settings = self.selectedEntry.sourceSettings;
	// set values for controls in the view based on settings
	NSString *path = [settings objectForKey:kItemPath];
	[itemLocationField setStringValue:(path?path:@"")];
	NSString *parser = [settings objectForKey:kItemParser];
	NSMenu *parserMenu = [[NSMenu alloc] initWithTitle:kQSURLParsers];

	[parserMenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
	[parserMenu addItem:[NSMenuItem separatorItem]];
	NSMutableDictionary *parsers = [QSReg instancesForTable:kQSURLParsers];

	NSMenuItem *item;
	for(NSString *key in parsers) {
		NSString *title = [[NSBundle bundleForClass:NSClassFromString(key)] safeLocalizedStringForKey:key value:key table:@"QSParser.name"];
		if ([title isEqualToString:key]) title = [[NSBundle mainBundle] safeLocalizedStringForKey:key value:key table:@"QSParser.name"];
		
		item = (NSMenuItem *)[parserMenu addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
	[itemParserPopUp setMenu:parserMenu];
	NSInteger parserEntry = [itemParserPopUp indexOfItemWithRepresentedObject:parser];
	[itemParserPopUp selectItemAtIndex:(parserEntry == -1?0:parserEntry)];
}

- (IBAction)setValueForSender:(id)sender {
	NSMutableDictionary *settings = self.selectedEntry.sourceSettings;
	if (sender == itemLocationField) {
		// Box showing the URL to scan
		[settings setObject:[sender stringValue] forKey:kItemPath];
	} else if (sender == itemParserPopUp) {
		// 'Include Contents' popup menu
		NSString *parserName = [[sender selectedItem] representedObject];
		if (parserName)
			[settings setObject:[[sender selectedItem] representedObject] forKey:kItemParser];
		else
			[settings removeObjectForKey:kItemParser];
	}
	[[self selectedEntry] scanAndCache];
	[self populateFields];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:[self selectedEntry]];
}
@end
