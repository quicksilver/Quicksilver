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

#import "NSApplication+ServicesModification.h"
#import "QSLoginItemFunctions.h"
#import "QSInterfaceMediator.h"
#import "QSPreferenceKeys.h"

#import "NSBundle_BLTRExtensions.h"

#import "QSHotKeyEvent.h"

#import "QSModifierKeyEvents.h"

typedef int CGSConnection;
typedef enum {
	CGSGlobalHotKeyEnable = 0,
	CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;

extern CGSConnection _CGSDefaultConnection(void);
extern CGError CGSGetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode *mode);
extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode mode);

@implementation QSSearchPrefPane

- (void)awakeFromNib {
#if 0
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NDHotKeyEvent *activationKey = [NDHotKeyEvent getHotKeyForKeyCode:[[defaults objectForKey:kHotKeyCode] unsignedShortValue] character:0 modifierFlags:[[defaults objectForKey:kHotKeyModifiers] unsignedIntValue]];
	[hotKeyButton setTitle:[activationKey stringValue]];
#endif
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController addObserver:self forKeyPath:@"values.QSModifierActivationCount" options:0 context:nil];
	[defaultsController addObserver:self forKeyPath:@"values.QSModifierActivationKey" options:0 context:nil];
}

- (void)dealloc {
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	[super dealloc];
}

- (void)setModifier:(int)modifier count:(int)count {
	QSModifierKeyEvent *event = [QSModifierKeyEvent eventWithIdentifier:@"QSModKeyActivation"];
	[event disable];
	if (count) {
		event = [[[QSModifierKeyEvent alloc] init] autorelease];
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

- (NSString *)serviceMenuKeyEquivalent {
	return [NSApp keyEquivalentForService:@"Quicksilver/Send to Quicksilver"];
}

- (void)setServiceMenuKeyEquivalent:(NSString *)string {
	[[NSUserDefaults standardUserDefaults] setObject:string forKey:@"QSServiceMenuKeyEquivalent"];
	[NSApp setKeyEquivalent:string forService:@"Quicksilver/Send to Quicksilver"];
}

@end

@implementation QSAppearancePrefPane
- (IBAction)customize:(id)sender {
	[[QSReg preferredCommandInterface] customize:sender];
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
	[super dealloc];
}

- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object {
	int index = [popUp indexOfItemWithRepresentedObject:object];
	if (index == -1 && [popUp numberOfItems]) index = 0;
	[popUp selectItemAtIndex:index];
}

- (void)updateInterfacePopUp {
	NSMenuItem *item;
	[interfacePopUp removeAllItems];
	NSMutableDictionary *interfaces = [QSReg tableNamed:kQSCommandInterfaceControllers];
	NSEnumerator *keyEnum = [interfaces keyEnumerator];
	NSString *key, *title;
	while(key = [keyEnum nextObject]) {
		title = [[QSReg bundleForClassName:[interfaces objectForKey:key]] safeLocalizedStringForKey:key value:key table:nil];
		item = (NSMenuItem *)[[interfacePopUp menu] addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
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
	foreach(key, colorDefaults) {
		[defaults willChangeValueForKey:key];
		[defaults removeObjectForKey:key];
		[defaults didChangeValueForKey:key];
	}
#endif
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *keys[] = { kQSAppearance1B, kQSAppearance1A, kQSAppearance1T, kQSAppearance2B, kQSAppearance2A, kQSAppearance2T, kQSAppearance3B, kQSAppearance3A, kQSAppearance3T };
	int i;
	for(i = 0; i < sizeof(keys) / sizeof(keys[0]); i++){
		[defaults willChangeValueForKey:keys[i]];
		[defaults removeObjectForKey:keys[i]];
		[defaults didChangeValueForKey:keys[i]];		
	}
	[defaults synchronize];
}

@end

@implementation QSApplicationPrefPane

- (NSNumber *)panePriority {
	return [NSNumber numberWithInt:10];
}

- (BOOL)shouldLaunchAtLogin {
	return QSItemShouldLaunchAtLogin([[NSBundle mainBundle] bundlePath]);
}

- (void)setShouldLaunchAtLogin:(BOOL)launch {
	QSSetItemShouldLaunchAtLogin([[NSBundle mainBundle] bundlePath] ,launch, NO);
}

- (BOOL)appPlistIsEditable {
	return [[NSFileManager defaultManager] isWritableFileAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]];
}

- (BOOL)dockIconIsHidden {
	return [NSApp shouldBeUIElement];
}

- (void)setDockIconIsHidden:(BOOL)flag {
	[NSApp setShouldBeUIElement:flag];
	if (flag) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if (![defaults objectForKey:@"QSShowMenuIcon"])
			[defaults setInteger:1 forKey:@"QSShowMenuIcon"];
	}
	if ([NSApp isUIElement] != flag)
		[NSApp requestRelaunch:nil];
}

- (int) featureLevel {
	if (newFeatureLevel) return newFeatureLevel;
	else return [NSApp featureLevel];
}

- (void)setFeatureLevel:(id)level {
	int newLevel = [level intValue];
	newFeatureLevel = newLevel;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (newLevel == 2 && (GetCurrentKeyModifiers() & (optionKey | rightOptionKey) )) {
		newLevel++;
		NSBeep();
		[defaults setBool:YES forKey:kCuttingEdgeFeatures];
	}
	[defaults setInteger:newLevel forKey:kFeatureLevel];
	[defaults synchronize];
	if (newLevel != [NSApp featureLevel])
		[NSApp requestRelaunch:nil];
}

- (IBAction)checkNow:(id)sender {
	[[QSUpdateController sharedInstance] threadedRequestedCheckForUpdate:sender];
}

- (void)deleteSupportFiles {
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Actions.plist", NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Catalog.plist", NO) handler:self];
	[fm removeFileAtPath:pIndexLocation handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Mnemonics.plist", NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"PlugIns", NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"PlugIns.plist", NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Shelves", NO) handler:self];
	[fm removeFileAtPath:[@"~/Library/Caches/Quicksilver" stringByStandardizingPath] handler:self];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[fm removeFileAtPath:[@"~/Library/Preferences/com.blacktree.Quicksilver.plist" stringByStandardizingPath] handler:self];
}

- (void)deleteApplication {
	[[NSFileManager defaultManager] removeFileAtPath:[[NSBundle mainBundle] bundlePath] handler:self];
}

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
	[[NSApp delegate] runSetupAssistant:nil];
}
- (IBAction)uninstallQS:(id)sender {
	if (!NSRunAlertPanel(@"Uninstall Quicksilver", @"Would you like to delete Quicksilver, all its preferences, and application support files? This operation cannot be undone.", @"Cancel", @"Uninstall", nil) ) {
		[self deleteSupportFiles];
		[self deleteApplication];
		[NSApp terminate:self];
	}
}

@end
