//
//  QSPreferencePane.m
//  Quicksilver
//
//  Created by Alcor on 11/2/04.

//

#import <QSCrucible/NDHotKeyEvent.h>
#import <QSCrucible/NDHotKeyEvent_QSMods.h>

#import "QSApp.h"

#import "QSUpdateController.h"

#import "QSModifierKeyEvents.h"
#import "QSController.h"

#import "QSMainPreferencePanes.h"

@implementation QSSearchPrefPane

-(void) awakeFromNib{
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	
	NDHotKeyEvent *activationKey=[NDHotKeyEvent getHotKeyForKeyCode:[[defaults objectForKey:kHotKeyCode] unsignedShortValue]
														  character:0
												  modifierFlags:[[defaults objectForKey:kHotKeyModifiers] unsignedIntValue]];
	[hotKeyButton setTitle:[activationKey stringValue]];	
	
//	[[NSNotificationCenter defaultCenter]addObserver:self 
//											selector:@selector(updateInterfacePopUp) name:QSPlugInLoadedNotification object:nil];
	
	NSUserDefaultsController *defaultsController=[NSUserDefaultsController sharedUserDefaultsController];
	
	[defaultsController addObserver:self
						 forKeyPath:@"values.QSModifierActivationCount"
							options:0
							context:nil];
	
	[defaultsController addObserver:self
						 forKeyPath:@"values.QSModifierActivationKey"
							options:0
							context:nil];
	
	
}



- (void)setModifier:(int)modifier count:(int)count{
	QSModifierKeyEvent *event=[QSModifierKeyEvent eventWithIdentifier:@"QSModKeyActivation"];
	[event disable];
	//QSLog(@"setmod %d %d",modifier,count);
	if (count){
		event=[[[QSModifierKeyEvent alloc]init]autorelease];
		[event setModifierActivationMask:modifier];
		[event setModifierActivationCount:count];
		[event setTarget:[NSApp delegate]];
		[event setIdentifier:@"QSModKeyActivation"];
		[event setAction:@selector(activateInterface:)];
		[event enable];
	}
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	[self setModifier:[defaults integerForKey:@"QSModifierActivationKey"]
				count:[defaults integerForKey:@"QSModifierActivationCount"]];
}


- (IBAction)changeHotkey:(id)sender {
	// KeyCombo* keyCombo=[KeyCombo keyComboWithKeyCode:[[defaults objectForKey:kHotKeyCode] shortValue]
	//                                   andModifiers:[[defaults objectForKey:kHotKeyModifiers] shortValue]];
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	NDHotKeyEvent *activationKey=[QSHotKeyEvent getHotKeyForKeyCode:[[defaults objectForKey:kHotKeyCode] unsignedShortValue]
														  character:0
												  safeModifierFlags:[[defaults objectForKey:kHotKeyModifiers] unsignedIntValue]];
	[hotKeyButton setTitle:[activationKey stringValue]];
	
    CGSConnection conn = _CGSDefaultConnection();
    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
    NSEvent *theEvent=[NSApp nextEventMatchingMask:NSKeyDownMask untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0] inMode:NSDefaultRunLoopMode dequeue:YES];
    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
    
    //[[HotKeyCenter sharedCenter] removeHotKey:kActivationHotKey];
    
    if (theEvent){
      //  if (VERBOSE) QSLog(@"got event: %@",theEvent);
        BOOL success;
        
		// QSLog(@"[%c]",KeyCodeToAscii([theEvent keyCode])); //
        //keyCombo=nil;
        if(1){
            activationKey=[QSHotKeyEvent getHotKeyForKeyCode:[theEvent keyCode]
												   character:0
											   modifierFlags:[theEvent modifierFlags]];
			
            [hotKeyButton setTitle:[activationKey stringValue]];
			
            [hotKeyButton setState:NSOffState];
            [hotKeyButton setNeedsDisplay:YES];
		//	QSLog(@"%d %d %d %d %@",[theEvent keyCode],[theEvent modifierFlags],[activationKey keyCode],[activationKey modifierFlags],[NSNumber numberWithShort:[activationKey modifierFlags]]);
            [defaults setObject:[NSNumber numberWithUnsignedShort:[activationKey keyCode]] forKey:kHotKeyCode];
            [defaults setObject:[NSNumber numberWithUnsignedInt:[activationKey modifierFlags]] forKey:kHotKeyModifiers];
            
			[[QSHotKeyEvent hotKeyWithIdentifier:kActivationHotKey]setEnabled:NO];
			
			
			[activationKey setTarget:[NSApp delegate] selector:@selector(activateInterface:)];
			success=[activationKey setEnabled:YES];
			[(QSHotKeyEvent *)activationKey setIdentifier:kActivationHotKey];
			
			
            if (success) {
			//	if (VERBOSE) QSLog(@"success");
            }
            else {
                QSLog(@"Error: couldn't register hot key!");
                [hotKeyButton setTitle:@"Error!"];
            }
        }     
    }
}     

- (NSString *)serviceMenuKeyEquivalent{
	return [NSApp keyEquivalentForService:@"Quicksilver/Send to Quicksilver"];
}

- (void)setServiceMenuKeyEquivalent:(NSString *)string{
	[[NSUserDefaults standardUserDefaults]setObject:string forKey:@"QSServiceMenuKeyEquivalent"];
	[NSApp setKeyEquivalent:string forService:@"Quicksilver/Send to Quicksilver"];
}

@end


@implementation QSAppearancePrefPane
- (IBAction)customize:(id)sender{
	
	[[QSReg preferredCommandInterface] customize:sender];
}
- (IBAction)preview:(id)sender{
//	[[QSReg preferredCommandInterface]setPreview:[sender state]];
	if ([[[QSReg preferredCommandInterface] window]isVisible]){
		[[[QSReg preferredCommandInterface] window] orderOut:sender];
	}else{
		[[[QSReg preferredCommandInterface] window] orderFront:sender];
	}
	   
}
- (void)mainViewDidLoad{
	[self updateInterfacePopUp];
	
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateInterfacePopUp) name:QSPlugInLoadedNotification object:nil];
	
	[customizeButton setHidden:![[QSReg preferredCommandInterface]respondsToSelector:@selector(customize:)]];
}

- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object{
	
	int index=[popUp indexOfItemWithRepresentedObject:object];
	if(index==-1 && [popUp numberOfItems])index=0;
	//QSLog(@"index %d",index);
	[popUp selectItemAtIndex:index];
	
	
}

- (void)updateInterfacePopUp{
	NSMenuItem *item;
	[interfacePopUp removeAllItems];
	
	NSMutableDictionary *interfaces=[QSReg elementsByIDForPointID:kQSCommandInterfaceControllers];
	NSEnumerator *keyEnum=[interfaces keyEnumerator];
	NSString *key, *title;
	while((key=[keyEnum nextObject])){
		id interface = [interfaces objectForKey:key];
		title=[[[interface plugin] bundle] safeLocalizedStringForKey:key value:key table:nil];
		item=(NSMenuItem *)[[interfacePopUp menu] addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
	
	[self selectItemInPopUp:interfacePopUp representedObject:[QSReg preferredCommandInterfaceID]];
}



- (NSString *)commandInterface{
	return [QSReg preferredCommandInterfaceID];
}

- (IBAction)setCommandInterface:(id)sender{
	NSString *newInterface=[[sender selectedItem]representedObject];
	//QSLog(newInterface);
	[[NSUserDefaults standardUserDefaults] setObject:newInterface forKey:kQSCommandInterfaceControllers];
	[self setValue:newInterface forMediator:kQSCommandInterfaceControllers];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseAllCachesNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceChangedNotification object:self];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[customizeButton setHidden:![[QSReg preferredCommandInterface]respondsToSelector:@selector(customize:)]];
}


- (BOOL)setValue:(NSString *)newMediator forMediator:(NSString *)mediatorType{
	[[NSUserDefaults standardUserDefaults] setObject:newMediator forKey:mediatorType];
	[QSReg removePreferredInstanceOfTable:mediatorType];
	return YES;
}


- (IBAction)resetColors:(id)sender{
	//QSLog(@"Resetting colors");
	
	NSArray *colorDefaults=[NSArray arrayWithObjects:
		kQSAppearance1B,kQSAppearance1A,kQSAppearance1T,
		kQSAppearance2B,kQSAppearance2A,kQSAppearance2T,
		kQSAppearance3B,kQSAppearance3A,kQSAppearance3T,
		nil];
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	foreach(key,colorDefaults){
		[defaults willChangeValueForKey:key];
		[defaults removeObjectForKey:key];
		[defaults didChangeValueForKey:key];
	}
	[defaults synchronize];
	
	//[self populateFields];
}


@end



@implementation QSApplicationPrefPane

- (NSNumber *)  panePriority{
	return [NSNumber numberWithInt:10];	
}


-(BOOL)shouldLaunchAtLogin{
	return QSItemShouldLaunchAtLogin([[NSBundle mainBundle] bundlePath]);  
}

-(void)setShouldLaunchAtLogin:(BOOL)launch{
	QSSetItemShouldLaunchAtLogin([[NSBundle mainBundle] bundlePath],launch,NO);  
}


- (BOOL)appPlistIsEditable{
	return [[NSFileManager defaultManager] isWritableFileAtPath:[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"Contents/Info.plist"]];
	
}

- (BOOL)dockIconIsHidden{
	return [NSApp shouldBeUIElement];
}

- (void)setDockIconIsHidden:(BOOL)flag{
	   [NSApp setShouldBeUIElement:flag];
	//  [hideDockIconSwitch setState:[(QSApp *)NSApp shouldBeUIElement]];
	// [self populateFields];
	if (flag){
		NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
		
		if (![defaults objectForKey:@"QSShowMenuIcon"])
			[defaults setInteger:1 forKey:@"QSShowMenuIcon"];
	}
	   if ([NSApp isUIElement]!=flag)
		   [NSApp requestRelaunch:nil];	   
}




- (int)featureLevel{
	if (newFeatureLevel) return newFeatureLevel;
	return [NSApp featureLevel];
}

- (void)setFeatureLevel:(id)level{
	
	int newLevel=[level intValue];
	newFeatureLevel=newLevel;
	if (newLevel==2 && (GetCurrentKeyModifiers() & (optionKey | rightOptionKey))){
		newLevel++;
		NSBeep();
		
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCuttingEdgeFeatures];
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:newLevel forKey:kFeatureLevel];
	[[NSUserDefaults standardUserDefaults] synchronize];
	if (newLevel!=[NSApp featureLevel])
		[NSApp requestRelaunch:nil];
	
}

-(IBAction)checkNow:(id)sender{
	[[QSUpdateController sharedInstance]threadedRequestedCheckForUpdate:sender];	
}
- (void)deleteSupportFiles{
	NSFileManager *fm=[NSFileManager defaultManager];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Actions.plist",NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Catalog.plist",NO) handler:self];
	[fm removeFileAtPath:pIndexLocation handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Mnemonics.plist",NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"PlugIns",NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"PlugIns.plist",NO) handler:self];
	[fm removeFileAtPath:QSApplicationSupportSubPath(@"Shelves",NO) handler:self];
	[fm removeFileAtPath:[@"~/Library/Caches/Quicksilver" stringByStandardizingPath] handler:self];
	[[NSUserDefaults standardUserDefaults]synchronize];
	[fm removeFileAtPath:[@"~/Library/Preferences/com.blacktree.Quicksilver.plist" stringByStandardizingPath] handler:self];
}
- (void)deleteApplication{
	NSFileManager *fm=[NSFileManager defaultManager];
	[fm removeFileAtPath:[[NSBundle mainBundle]bundlePath] handler:self];
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo{
	QSLog(@"error: %@",errorInfo);
	return YES;
}
-(IBAction)resetQS:(id)sender{
	if (!NSRunAlertPanel(@"Reset Quicksilver", @"Would you like to delete all preferences and application support files, returning Quicksilver to the default state? This operation cannot be undone and requires a relaunch", @"Cancel", @"Reset and Relaunch", nil)){
        [self deleteSupportFiles];
		[NSApp relaunch:self];
	}
}

-(IBAction)runSetup:(id)sender{
	[[NSApp delegate]runSetupAssistant:nil];
}
-(IBAction)uninstallQS:(id)sender{
	if (!NSRunAlertPanel(@"Uninstall Quicksilver", @"Would you like to delete Quicksilver, all its preferences, and application support files? This operation cannot be undone.", @"Cancel", @"Uninstall", nil)){
		
		[self deleteSupportFiles];
		[self deleteApplication];
		[NSApp terminate:self];
	}
	
}

@end
