//
// QSHelpersPrefPane.m
// Quicksilver
//
// Created by Alcor on 10/3/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSHelpersPrefPane.h"
#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSMacros.h"

#import "NSBundle_BLTRExtensions.h"

#define NAME @"name"
#define IDENT @"ident"
#define MENU @"menu"
#define TITLE @"title"
#define INFO @"info"

@implementation QSHelpersPrefPane
- (id)init {
	self = [super initWithBundle:[NSBundle bundleForClass:[QSHelpersPrefPane class]]];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadHelpersList:) name:QSPlugInLoadedNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[helperInfo release];
	[super dealloc];
}

- (void)awakeFromNib {
	[self reloadHelpersList:nil];
}

- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object {
	int index = [popUp indexOfItemWithRepresentedObject:object];
	if (index == -1 && [popUp numberOfItems]) index = 0;
	[popUp selectItemAtIndex:index];
}

- (NSMenu *)menuForTable:(NSString *)table includeDefault:(BOOL)includeDefault {
	NSDictionary *mediators = [QSReg tableNamed:table];
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"popUp"];
	if (![mediators count]) {
		if (!DEBUG) return nil;
		[menu addItemWithTitle:@"None Available" action:nil keyEquivalent:@""];
		return [menu autorelease];
	}
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSEnumerator *keyEnum = [mediators keyEnumerator];
	NSString *path, *key, *title;
	NSMenuItem *item = nil;
	while(key = [keyEnum nextObject]) {
		path = [workspace absolutePathForAppBundleWithIdentifier:key];
		NSString *class = [mediators objectForKey:key];
		NSBundle *bundle = [QSReg bundleForClassName:class];
		title = [bundle safeLocalizedStringForKey:class value:@"" table:nil];
		if (![title length] && path) {
			title = [[NSBundle bundleWithPath:path] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
			if (!title) title = [[NSFileManager defaultManager] displayNameAtPath:path];
		}
		if (![title length])
			title = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
		if (title) {
			item = (NSMenuItem *)[menu addItemWithTitle:title action:nil keyEquivalent:@""];
			NSImage *image = nil;
			if (path) {
				image = [workspace iconForFile:path];
			}
			if (!image)
				image = [QSResourceManager imageNamed:@"PlugInIcon"];
			[item setImage:image];
		}
		[[item image] setSize:NSMakeSize(16, 16)];
		[item setRepresentedObject:key];
	}
	if (includeDefault) {
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Default" action:nil keyEquivalent:@""];
	}
	return [menu autorelease];
}

- (NSString *)mainNibName { return @"QSHelpersPrefPane"; }

- (void)reloadHelpersList:(id)sender {
	NSMutableArray *helpers = [NSMutableArray array];
	foreachkey(key, header, [QSReg tableNamed:@"QSRegistryHeaders"]) {
		if ([[header objectForKey:@"type"] isEqual:@"mediator"]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:header forKey:INFO];
			if ([[header objectForKey:@"feature"] intValue] > [NSApp featureLevel]) continue;
			NSMenu *menu = [self menuForTable:key includeDefault:[[header objectForKey:@"allowDefault"] boolValue]];
			if (!menu) continue;
			if (menu)
				[dict setObject:menu forKey:MENU];
			[dict setObject:key forKey:IDENT];
			[helpers addObject:dict];
		}
	}
	[self setHelperInfo:helpers];
	[helperTable reloadData];
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView {
	return [helperInfo count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqual:@"helper"]) {
		return nil;
	} else {
		return [[[helperInfo objectAtIndex:rowIndex] objectForKey:INFO] objectForKey:NAME];
	}
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqual:@"helper"] && anObject) {
		NSDictionary *info = [helperInfo objectAtIndex:rowIndex];
		int index = [anObject intValue];
		NSMenu *menu = [info objectForKey:MENU];
		NSDictionary *settings = [info objectForKey:INFO];
		anObject = [[menu itemAtIndex:index] representedObject];
		NSString *mediatorType = [info objectForKey:IDENT];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if (![anObject isEqual:[defaults objectForKey:mediatorType]]) {
			[defaults setObject:anObject forKey:mediatorType];
			[QSReg removePreferredInstanceOfTable:mediatorType];
			if ([settings objectForKey:@"requiresRelaunch"]) [NSApp requestRelaunch:self];
		}
	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(NSCell*)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqual:@"helper"]) {
		NSDictionary *info = [helperInfo objectAtIndex:rowIndex];
		id object = [QSReg getMediatorID:[info objectForKey:IDENT]];
		if (!object)
			object = [[NSUserDefaults standardUserDefaults] objectForKey:[info objectForKey:IDENT]];
		NSMenu *menu = [[helperInfo objectAtIndex:rowIndex] objectForKey:MENU];
		[aCell setEnabled:[menu numberOfItems] >1];
		[aCell setMenu:menu];
		int index = [(NSPopUpButtonCell*)aCell indexOfItemWithRepresentedObject:object];
		if (index == -1 && [(NSPopUpButtonCell*)aCell numberOfItems]) index = 0;
		[(NSPopUpButtonCell*)aCell selectItemAtIndex:index];
	}
}

- (NSMutableArray *)helperInfo { return helperInfo;  }
- (void)setHelperInfo:(NSMutableArray *)aHelperInfo {
	if(aHelperInfo != helperInfo){
		[helperInfo release];
		helperInfo = [aHelperInfo retain];
	}
}
@end
