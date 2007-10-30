//
//  QSHelpersPrefPane.m
//  Quicksilver
//
//  Created by Alcor on 10/3/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSHelpersPrefPane.h"
#import "QSResourceManager.h"

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
		
		//	plugInArray = [[NSMutableArray alloc] init];
		///		disabledPlugIns = [[NSMutableSet alloc] init];
		//	[disabledPlugIns addObjectsFromArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"QSDisabledPlugIns"]];
		
		//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInsList:) name:QSPlugInInstalledNotification object:nil]; 	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadHelpersList:) name:QSPlugInLoadedNotification object:nil];
    }
    return self;
}

- (void)awakeFromNib {
	[self reloadHelpersList:nil];
	
	//	[self populatePopUp:chatMediatorsPopUp table:[QSReg elementsForPointID:kQSChatMediators] includeDefault:NO];
	//	[self populatePopUp:mailMediatorsPopUp table:[QSReg elementsForPointID:kQSMailMediators] includeDefault:YES];
	//	[self populatePopUp:finderProxyPopUp table:[QSReg elementsForPointID:kQSFSBrowserMediators] includeDefault:NO];
	//	[self populatePopUp:notifierMediatorsPopUp table:[QSReg elementsForPointID:kQSNotifiers] includeDefault:NO];
}

- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object {
	
	int index = [popUp indexOfItemWithRepresentedObject:object];
	if (index == -1 && [popUp numberOfItems]) index = 0;
	//QSLog(@"index %d", index);
	[popUp selectItemAtIndex:index];
}

- (NSMenu *)menuForTable:(NSString *)table includeDefault:(BOOL)includeDefault {
	NSDictionary *mediators = [QSReg elementsByIDForPointID:table];
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"popUp"] autorelease];
	//QSLog(@"%@ %@", table, mediators);
	if (![mediators count]) {
		if (!DEBUG) return nil;
		//[popUp insertItemWithTitle:@"None Installed" atIndex:0];
		[menu addItemWithTitle:@"None Available" action:nil keyEquivalent:@""];
		return menu;
	}
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSEnumerator *keyEnum = [mediators keyEnumerator];
	NSString *path, *key, *title;
	NSMenuItem *item = nil;
	while(key = [keyEnum nextObject]) {
		title = nil;
		path = [workspace absolutePathForAppBundleWithIdentifier:key];
		BElement *element = [mediators objectForKey:key];
		NSString *class = [element className];
		NSBundle *bundle = [[element plugin] bundle];
		
		if (!title) {
			title = [bundle safeLocalizedStringForKey:class value:@"" table:nil];
		}
		if (![title length] && path) {
			title = [[NSBundle bundleWithPath:path] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
			if (!title) title = [[NSFileManager defaultManager] displayNameAtPath:path];
		}
		if (![title length]) title = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
		
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
	return menu;
}

- (NSString *)mainNibName {
	return @"QSHelpersPrefPane";
}

- (void)reloadHelpersList:(id)sender {
	//[NSMutableArray arrayWithObjects:@"Command Line", @"Email", @"Notification", @"Instant Messaging", @"File Managment", nil];
	NSMutableArray *helpers = [NSMutableArray array];
	//QSLog(@"helper %@", [QSReg elementsForPointID:@"QSRegistryHeaders"]);
	
	foreachkey(key, header, [QSReg elementsByIDForPointID:@"QSRegistryHeaders"]) {
		header = [header plistContent];
		if ([[header objectForKey:@"type"] isEqual:@"mediator"]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:header forKey:INFO];
			if ([[header objectForKey:@"feature"] intValue] >[NSApp featureLevel]) continue;
		
			NSMenu *menu = [self menuForTable:key includeDefault:[[header objectForKey:@"allowDefault"] boolValue]];
			//QSLog(@"helper %@ %@", key, menu);
			if (!menu /* && !fDEV*/) continue;
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
		
		if (![anObject isEqual:
			[[NSUserDefaults standardUserDefaults] objectForKey:mediatorType]]) {
			//QSLog(@"%@ %@", anObject, mediatorType);
			[[NSUserDefaults standardUserDefaults] setObject:anObject forKey:mediatorType];
			[QSReg removePreferredInstanceOfTable:mediatorType];
			
			if ([settings objectForKey:@"requiresRelaunch"]) [NSApp requestRelaunch:self];
		}
	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	
	if ([[aTableColumn identifier] isEqual:@"helper"]) {
		//	QSLog(@"cell %@", aCell);
		NSDictionary *info = [helperInfo objectAtIndex:rowIndex];
		//NSString *regSelector = ;
		
		id object = nil;
		
		
		object = [QSReg getMediatorID:[info objectForKey:IDENT]];
		
		if (!object)
			object = [[NSUserDefaults standardUserDefaults] objectForKey:[info objectForKey:IDENT]];
		
		NSMenu *menu = [[helperInfo objectAtIndex:rowIndex] objectForKey:MENU];
		
		//		[aCell setUsesItemFromMenu:menu];
		
		
		[aCell setEnabled:[menu numberOfItems] >1];
		[aCell setMenu:menu];
		
		
		int index = [aCell indexOfItemWithRepresentedObject:object];
		if (index == -1 && [aCell numberOfItems]) index = 0;
		//QSLog(@"index %d", index);
		[aCell selectItemAtIndex:index];
		
		
		
		//	if (![mediators count]) {
		//			//[popUp insertItemWithTitle:@"None Installed" atIndex:0];
		//			[aCell setTitle:@"None Available"];
		//			return;
		//}
	}
}



- (NSMutableArray *)helperInfo { return [[helperInfo retain] autorelease];  }
- (void)setHelperInfo:(NSMutableArray *)aHelperInfo {
    [helperInfo autorelease];
    helperInfo = [aHelperInfo retain];
}
@end
