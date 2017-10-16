//
// QSPreferencePane.m
// Quicksilver
//
// Created by Alcor on 11/2/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSMainPreferencePanes.h"
#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "QSMacros.h"
#import "QSApp.h"
#import "QSHelp.h"
#import "QSUpdateController.h"
#import "QSNotifications.h"
#import "QSController.h"

#import "QSInterfaceMediator.h"
#import "QSPreferenceKeys.h"

#import "NSBundle_BLTRExtensions.h"

#import "QSHotKeyEvent.h"

#import "QSModifierKeyEvents.h"

// Imports for the actions pref pane
#import "QSExecutor.h"
#import "QSLibrarian.h"
#import "QSTableView.h"

#define QSTableRowsType @"QSTableRowsType"

#import "NSSortDescriptor+BLTRExtensions.h"
#import "NSIndexSet+Extensions.h"
#import "QSPlugInManager.h"
#import "QSPlugIn.h"
#import "LaunchAtLoginController.h"

@interface QSPreferencePane (Helper)
- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object;
@end

@implementation QSPreferencePane (Helper)

- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object {
	NSInteger index = [popUp indexOfItemWithRepresentedObject:object];
	if (index == -1 && [popUp numberOfItems]) index = 0;
	[popUp selectItemAtIndex:index];
}

@end

@implementation QSSearchPrefPane

- (void)awakeFromNib {

	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController addObserver:self forKeyPath:@"values.QSModifierActivationCount" options:0 context:nil];
	[defaultsController addObserver:self forKeyPath:@"values.QSModifierActivationKey" options:0 context:nil];

    [self updateKeyboardPopUp];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateKeyboardPopUp) name:(NSString*)kTISNotifyEnabledKeyboardInputSourcesChanged object:nil];
}

- (void)dealloc {
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.QSModifierActivationCount"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.QSModifierActivationKey"];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setModifier:(NSInteger)modifier count:(NSInteger)count {
	QSModifierKeyEvent *event = [QSModifierKeyEvent eventWithIdentifier:@"QSModKeyActivation"];
    [event disable];
	if (count) {
		event = [[QSModifierKeyEvent alloc] init];
		[event setModifierActivationMask:modifier];
		[event setModifierActivationCount:count];
		[event setTarget:[NSApp delegate]];
		[event setIdentifier:@"QSModKeyActivation"];
		[event setAction:@selector(activateInterface:)];
		[event enable];
	}
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[self setModifier:[defaults integerForKey:@"QSModifierActivationKey"] count:[defaults integerForKey:@"QSModifierActivationCount"]];
}

- (BOOL)showChildrenInSplitView {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"QSResultsShowChildren"];
}

- (void)setShowChildrenInSplitView:(BOOL)flag {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setBool:flag forKey:@"QSResultsShowChildren"];

	[defaults synchronize];
	[NSApp requestRelaunch:nil];
}

- (void)updateKeyboardPopUp {
    [keyboardPopUp removeAllItems];

    NSMutableDictionary *sourceNames = [NSMutableDictionary dictionaryWithCapacity:5];

    for (NSString *type in [NSArray arrayWithObjects:(NSString *)kTISTypeKeyboardLayout, (NSString *)kTISTypeKeyboardInputMode, nil]) {
        NSDictionary *filter = [NSDictionary dictionaryWithObject:type forKey:(NSString *)kTISPropertyInputSourceType];
        CFArrayRef sourceList= TISCreateInputSourceList((__bridge CFDictionaryRef)filter, false);
        if (!sourceList) {
            continue;
        }
        CFIndex count = CFArrayGetCount(sourceList);

        for (int i = 0; i < count; i++ ) {
            TISInputSourceRef source = (TISInputSourceRef)CFArrayGetValueAtIndex(sourceList, i);
            NSString *title = (__bridge NSString *)TISGetInputSourceProperty(source, kTISPropertyLocalizedName);
            NSString *sourceId = (__bridge NSString *)TISGetInputSourceProperty(source, kTISPropertyInputSourceID);
            [sourceNames setObject:sourceId forKey:title];
        }

        CFRelease(sourceList);
    }

    for(NSString *title in [sourceNames allKeys]) {
        NSMenuItem *item = [[keyboardPopUp menu] addItemWithTitle:title action:nil keyEquivalent:@""];
        [item setRepresentedObject:[sourceNames objectForKey:title]];
    }

    NSString *forcedKeyboardId = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSForcedKeyboardIDOnActivation"];
    [self selectItemInPopUp:keyboardPopUp representedObject:forcedKeyboardId];
    NSString *selectedKeyboardId = [[keyboardPopUp selectedItem] representedObject];
    if (![selectedKeyboardId isEqualToString:forcedKeyboardId]) {
        [[NSUserDefaults standardUserDefaults] setObject:selectedKeyboardId forKey:@"QSForcedKeyboardIDOnActivation"];
    }
}

@end

@implementation QSAppearancePrefPane

/* The colour picker in the Appearance preference pane is mapped as follows:
 
 1B  1A  1T
 
 2B  2A  2T
 
 3B  3A  3T
 
 'B' stands for 'Background'
 'A' stands for 'Accents and Highlights'
 'T' stands for 'Text'
 '1' refers to the main window
 '2' refers to the results window header/footer
 '3' refers to the results window background
 
 */
 
- (IBAction)customize:(id)sender {
	[[QSReg preferredCommandInterface] performSelector:@selector(customize:) withObject:sender];
}
- (IBAction)preview:(id)sender {
	id win = [[QSReg preferredCommandInterface] window];
	if ([win isVisible])
		[win orderOut:sender];
	else
		[win orderFront:sender];
}
- (void)mainViewDidLoad {
	[self updateInterfacePopUp];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateInterfacePopUp) name:QSPlugInLoadedNotification object:nil];
	[customizeButton setHidden:![[QSReg preferredCommandInterface] respondsToSelector:@selector(customize:)]];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateInterfacePopUp {
	NSMenuItem *item;
	[interfacePopUp removeAllItems];
	NSDictionary *interfaces = [QSReg tableNamed:kQSCommandInterfaceControllers];
	NSMutableDictionary *interfaceNames = [NSMutableDictionary dictionaryWithCapacity:[interfaces count]];
	
	// localize titles/names of interfaces
	NSString *title;
	for(NSString *key in interfaces) {
		title = [[QSReg bundleForClassName:[interfaces objectForKey:key]] safeLocalizedStringForKey:key value:key table:nil];
		[interfaceNames setObject:key forKey:title];
	}

	// sort localized names
	NSArray *titles = [interfaceNames allKeys];
	titles = [titles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// add interfaces to popup menu
	for(title in titles) {
		item = (NSMenuItem *)[[interfacePopUp menu] addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:[interfaceNames objectForKey:title]];
	}
	
	// select active interface
	[self selectItemInPopUp:interfacePopUp representedObject:[QSReg preferredCommandInterfaceID]];
}

- (NSString *)commandInterface {
	return [QSReg preferredCommandInterfaceID];
}

- (IBAction)setCommandInterface:(id)sender {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *newInterface = [[sender selectedItem] representedObject];
	[defaults setObject:newInterface forKey:kQSCommandInterfaceControllers];
	[self setValue:newInterface forMediator:kQSCommandInterfaceControllers];
	[nc postNotificationName:QSReleaseAllCachesNotification object:self];
	[nc postNotificationName:QSInterfaceChangedNotification object:self];
	[defaults synchronize];
	[customizeButton setHidden:![[QSReg preferredCommandInterface] respondsToSelector:@selector(customize:)]];
}

- (BOOL)setValue:(NSString *)newMediator forMediator:(NSString *)mediatorType {
	[[NSUserDefaults standardUserDefaults] setObject:newMediator forKey:mediatorType];
	[QSReg removePreferredInstanceOfTable:mediatorType];
	return YES;
}

- (IBAction)resetColors:(id)sender {
#if 0
	NSArray *colorDefaults = [NSArray arrayWithObjects:kQSAppearance1B, kQSAppearance1A, kQSAppearance1T, kQSAppearance2B, kQSAppearance2A, kQSAppearance2T, kQSAppearance3B, kQSAppearance3A, kQSAppearance3T, nil];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	for(NSString * key in colorDefaults) {
		[defaults willChangeValueForKey:key];
		[defaults removeObjectForKey:key];
		[defaults didChangeValueForKey:key];
	}
#endif
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *colourDefaults = [NSArray arrayWithObjects: kQSAppearance1B, kQSAppearance1A, kQSAppearance1T, kQSAppearance2B, kQSAppearance2A, kQSAppearance2T, kQSAppearance3B, kQSAppearance3A, kQSAppearance3T, nil];
    @synchronized(defaults) {
    for (NSString *eachDefault in colourDefaults) {
            [defaults willChangeValueForKey:eachDefault];
            [defaults removeObjectForKey:eachDefault];
            [defaults didChangeValueForKey:eachDefault];
        }
    }
	[defaults synchronize];
}

@end

@implementation QSApplicationPrefPane

- (NSNumber *)panePriority {
	return [NSNumber numberWithInteger:10];
}

- (BOOL)shouldLaunchAtLogin {
	LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
	BOOL shouldLaunch = [launchController willLaunchAtLogin:[[NSBundle mainBundle] bundleURL]];
	return shouldLaunch;
}

- (void)setShouldLaunchAtLogin:(BOOL)launch {
	LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
	[launchController setLaunchAtLogin:launch forURL:[[NSBundle mainBundle] bundleURL]];
}

- (BOOL)dockIconIsHidden {
	return ![[NSUserDefaults standardUserDefaults] boolForKey:kHideDockIcon];
}

- (void)setDockIconIsHidden:(BOOL)flag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!flag forKey:kHideDockIcon];
    if (![defaults objectForKey:@"QSShowMenuIcon"])
        [defaults setInteger:1 forKey:@"QSShowMenuIcon"];
    [defaults synchronize];
	[NSApp requestRelaunch:nil];
}

- (IBAction)checkNow:(id)sender {
	[[QSUpdateController sharedInstance] checkForUpdates:YES];
}

- (void)deleteSupportFiles {

	NSFileManager *fm = [NSFileManager defaultManager];
    NSError * err = nil;
	[fm removeItemAtPath:QSApplicationSupportSubPath(@"Actions.plist", NO) error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:QSApplicationSupportSubPath(@"Catalog.plist", NO) error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:pIndexLocation error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:QSApplicationSupportSubPath(@"Mnemonics.plist", NO) error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:QSApplicationSupportSubPath(@"PlugIns", NO) error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:QSApplicationSupportSubPath(@"PlugIns.plist", NO) error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:QSApplicationSupportSubPath(@"Shelves", NO) error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[fm removeItemAtPath:[@"~/Library/Caches/Quicksilver" stringByStandardizingPath] error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
	[[NSUserDefaults standardUserDefaults] synchronize];
	[fm removeItemAtPath:[[NSString stringWithFormat:@"~/Library/Preferences/%@.plist",kQSBundleID]stringByStandardizingPath] error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
}

- (void)deleteApplication {
    NSError * err = nil;
	[[NSFileManager defaultManager] removeItemAtPath:[[NSBundle mainBundle] bundlePath] error:&err];
    if (err) {
        NSLog(@"QSMainPreferencePanes:%s: Error: %@", __PRETTY_FUNCTION__, err);
        err = nil;
    }
}
// !!! Andre Berg 20091013: this is no longer needed since I upgraded the all the calls to removeFileAtPath:handler: to the new 10.5+ API (removeItemAtPath:error:);
// this should also have the side effect of being faster...
- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo {
	NSLog(@"error: %@", errorInfo);
	return YES;
}

- (IBAction)resetQS:(id)sender {
	if (!NSRunAlertPanel(@"Reset Quicksilver", @"Would you like to delete all preferences and application support files, returning Quicksilver to the default state? This operation cannot be undone and requires a relaunch", @"Cancel", @"Reset and Relaunch", nil) ) {
		[self deleteSupportFiles];
		[NSApp relaunch:self];
	}
}

- (IBAction)runSetup:(id)sender {
	[(QSController *)[NSApp delegate] runSetupAssistant:nil];
}
- (IBAction)uninstallQS:(id)sender {
	if (!NSRunAlertPanel(@"Uninstall Quicksilver", @"Would you like to delete Quicksilver, all its preferences, and application support files? This operation cannot be undone.", @"Cancel", @"Uninstall", nil) ) {
		[self deleteSupportFiles];
		[self deleteApplication];
		[NSApp terminate:self];
	}
}

@end


@implementation QSActionsPrefPane

- (NSString *)mainNibName { return @"QSActionsPrefPane"; }

#define kQSAllActionsCategory @"QSAllActions"

- (id)init {
	if (self = [super initWithBundle:[NSBundle bundleForClass:[QSActionsPrefPane class]]]) {
		displayMode = 0;
	}
	return self;
}

- (void)awakeFromNib {
	[self updateGroups];
	[groupController addObserver:self forKeyPath:@"selectedObjects" options:0 context:@"test"];
	[actionController setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"userRank" ascending:YES]];
	[groupController setSelectionIndex:0];
	[self selectCategories:[groupController selectedObjects]];
}

- (void)selectCategories:(NSArray *)categories {
	NSMutableSet *newActions = [NSMutableSet set];
	switch (displayMode) {
		case 0: {
			for(id category in categories) {
				NSString *type = [category objectForKey:@"group"];
				[newActions addObjectsFromArray: ([type isEqual:kQSAllActionsCategory])?[QSExec actions]:[QSExec actionsArrayForType:type] ];
			}
			break;
		}
		case 1: {
			for(id category in categories) {
				NSString *plugin = [category objectForKey:@"group"];
				[newActions addObjectsFromArray: ([plugin isEqual:kQSAllActionsCategory])?[QSExec actions]:[QSExec getArrayForSource:plugin] ];
			}
			break;
		}
		default: break;
	}
	[self setActions:[[newActions allObjects] mutableCopy]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self selectCategories:[groupController selectedObjects]];
}

- (NSMutableArray *)actions { return actions;  }
- (void)setActions:(NSMutableArray *)newActions {
	if(newActions != actions){
		actions = newActions;
	}
}
- (NSMutableArray *)groups { return groups; }
- (void)setGroups:(NSMutableArray *)newGroups {
	if(newGroups != groups){
		groups = newGroups;
	}
}

- (NSInteger) displayMode { return displayMode;  }
- (void)setDisplayMode:(NSInteger)newDisplayMode {
	displayMode = newDisplayMode;
	[self updateGroups];
	[groupController setSelectionIndex:0];
}

- (void)updateGroups {
	NSMutableArray *array = [NSMutableArray array];
	switch (displayMode) {
		case 0: {
			NSDictionary *infoTable = [QSReg tableNamed:@"QSTypeDefinitions"];
			NSArray *newGroups = [infoTable allKeys];
			for(NSString * group in newGroups) {
				NSDictionary *info = [infoTable objectForKey:group];
				if (!info) continue;
				NSString *name = [info objectForKey:@"name"];
				if (!name) name = group;
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  group, @"group", name, @"name", [QSResourceManager imageNamed:[info objectForKey:@"icon"]], @"icon", nil]];
			}
			NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
			[array sortUsingDescriptors:[NSArray arrayWithObject:desc]];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:kQSAllActionsCategory, @"group", @"All Actions", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:0];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"*", @"group", @"Any Type", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:1];
			break;
		}
		case 1: {
			foreachkey(pluginId, plugin, [[QSPlugInManager sharedInstance] loadedPlugIns]) {
				NSString *name = [plugin shortName];
				if (!name) name = [plugin identifier];
				NSArray *actionsArray = [QSExec getArrayForSource:[plugin identifier]];
				if ([actionsArray count]) {
					name = [name stringByAppendingFormat:@" - %lu", (unsigned long)[actionsArray count]];
					[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [plugin identifier] , @"group", name, @"name", [plugin icon] , @"icon", nil]];
				}
			}
			NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
			[array sortUsingDescriptors:[NSArray arrayWithObject:desc]];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:kQSAllActionsCategory, @"group", @"All Plugins", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:0];
			break;
		}
		default:
			break;
	}
	[self setGroups:array];
}

- (NSDragOperation)tableView:(NSTableView *)view validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSArray *data = [[info draggingPasteboard] propertyListForType:QSTableRowsType];
	NSIndexSet *indexes = [NSIndexSet indexSetFromArray:data];
	if ([indexes containsIndex:row] || [indexes containsIndex:row-1])
		return  NSDragOperationNone;
	else
		return operation == NSTableViewDropAbove ? NSDragOperationMove : NSDragOperationNone;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"enabled"] && mOptionKeyIsDown)
		[[actionController arrangedObjects] setValue:object forKey:@"enabled"];
	if ([[tableColumn identifier] isEqualToString:@"rank"]) {
		NSArray *currentActions = [actionController arrangedObjects];
		NSInteger newRow = [object integerValue] -1;
		if (row != newRow && row >= 0 && row < (NSInteger)[currentActions count] && newRow >= 0 && (NSUInteger)newRow<[currentActions count]) {
			[QSExec orderActions:[NSArray arrayWithObject:[currentActions objectAtIndex:row]] aboveActions:[NSArray arrayWithObject:[currentActions objectAtIndex:newRow]]];
		}
		[actionController rearrangeObjects];
	}
}

- (BOOL)tableView:(NSTableView *)view acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	[view registerForDraggedTypes:nil];
	NSArray *data = [[info draggingPasteboard] propertyListForType:QSTableRowsType];
	NSIndexSet *indexes = [NSIndexSet indexSetFromArray:data];
    
	NSArray *currentActions = [actionController arrangedObjects];
	NSArray *draggedActions = [[actionController arrangedObjects] objectsAtIndexes:indexes];
    
	BOOL ascending = [[[view sortDescriptors] objectAtIndex:0] ascending];
	if ((ascending ? [indexes lastIndex] > (NSUInteger)row : [indexes lastIndex] < (NSUInteger)row))
		// An upward or mixed drag (promotion for the most part)
		[QSExec orderActions:draggedActions aboveActions:[NSArray arrayWithObject:[currentActions objectAtIndex:ascending?row:row-1]]];
	else // A downward drag (demotion)
		[QSExec orderActions:draggedActions belowActions:[NSArray arrayWithObject:[currentActions objectAtIndex:ascending?row-1:row]]];
	[actionController setSelectedObjects:draggedActions];
	[actionController rearrangeObjects];
	return YES;
}
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
	if (![[[[tv sortDescriptors] objectAtIndex:0] key] isEqualToString:@"userRank"])
		return NO;
	[tv registerForDraggedTypes:[NSArray arrayWithObject:QSTableRowsType]];
	[pboard declareTypes:[NSArray arrayWithObject:QSTableRowsType] owner:self];
	[pboard setPropertyList:rows forType:QSTableRowsType];
	return YES;
}

- (IBAction)setFilterText:(id)sender {
	NSString *string = [sender stringValue];
	[actionController setFilterPredicate:([string length])?[NSPredicate predicateWithFormat:@"name contains[cd] %@", string]:nil];
}


@end
