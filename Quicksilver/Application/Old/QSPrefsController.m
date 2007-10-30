

#import "QSPrefsController.h"
#import "QSPreferenceKeys.h"

#import "QSObject.h"
#import "QSObjectSource.h"
#import "QSResourceManager.h"
#import "QSController.h"
#import "QSImageAndTextCell.h"
#define COLUMNID_NAME		@"name"
#define COLUMNID_TYPE	 	@"TypeColumn"
#define COLUMNID_STATUS	 	@"StatusColumn"
#define UNSTABLE_STRING		@"(Unstable Entry)"
#define QSPasteboardType @"QSPastebardType"
//#import "KeyComboPanel.h"

#import "QSNotifications.h"
//#import "KeyBroadcaster.h"
#import "NTViewLocalizer.h"

//#import "QSFSBrowserMediator.h"
#import "QSNotifyMediator.h"

#import "QSInterfaceMediator.h"

#import "NDHotKeyEvent_QSMods.h"
#import "QSMacros.h"

#import "QSApp.h"
//#import "HotKeyCenter.h"

//#import "QSToolbarView.h"
#import "QSBackgroundView.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#include <PreferencePanes/PreferencePanes.h>

#import "NSBundle_BLTRExtensions.h"
#include <unistd.h>

//typedef int CGSConnection;
typedef enum {
    CGSGlobalHotKeyEnable = 0,
    CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;

extern CGSConnection _CGSDefaultConnection(void);

extern CGError CGSGetGlobalHotKeyOperatingMode(
                                               CGSConnection connection, CGSGlobalHotKeyOperatingMode *mode);

extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, 
                                               CGSGlobalHotKeyOperatingMode mode);



@interface NSPreferencePane (QSExtensions)	
- (NSImage *) icon;
@end
//
//char KeyCodeToAscii(short virtualKeyCode) {
//    unsigned long state;
//    long keyTrans;
//    char charCode;
//    Ptr kchr;
//    state = 0;
//    kchr = (Ptr) GetScriptVariable(smCurrentScript, smKCHRCache);
//    keyTrans = KeyTranslate(kchr, virtualKeyCode, &state);
//    charCode = keyTrans;
//    if (!charCode) charCode = (keyTrans>>16);
//    return charCode;
//}

@implementation NSSegmentedControl (SelectedIndex)
- (int)indexOfSelectedItem{return [self selectedSegment];}
@end

id QSPrefs;
@implementation QSPrefsController

+ (void)initialize{
    [self setKeys:[NSArray arrayWithObject:@"currentItem"] triggerChangeNotificationsForDependentKey:@"selectedCatalogEntryIsEditable"];
    
}

+ (void)showPrefs{
	[NSApp activateIgnoringOtherApps:YES];
	[[self sharedInstance]showWindow:nil];		
}

+ (id)sharedInstance{
    if (!QSPrefs) QSPrefs = [[[self class] allocWithZone:[self zone]] init];
    return QSPrefs;
}
- (id)init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        defaults=[[NSUserDefaults standardUserDefaults]retain];
        modules=[[NSMutableArray arrayWithCapacity:1]retain];
		
    }
    return self;
}
+ (void)showPaneWithIdentifier:(NSString *)identifier{
	[[self sharedInstance]showPaneWithIdentifier:identifier];
}

- (void)showPaneWithIdentifier:(NSString *)identifier{
	NSWindow *win=[self window];
	int index=[[modules valueForKey:kItemID]indexOfObject:identifier];
	//NSLog(@"pref %@ %d",[modules valueForKey:kItemID],index);
	[modulesTable selectRow:index byExtendingSelection:NO];
	[win makeKeyAndOrderFront:win];
}

- (void)plugInLoaded:(NSNotification *)notif{
	NSLog(@"plugInLoad");
}

- (IBAction)resetColors:(id)sender{
	NSLog(@"Resetting colors");
	
	NSArray *colorDefaults=[NSArray arrayWithObjects:
		kQSAppearance1B,kQSAppearance1A,kQSAppearance1T,
		kQSAppearance2B,kQSAppearance2A,kQSAppearance2T,
		kQSAppearance3B,kQSAppearance3A,kQSAppearance3T,
		nil];
	
	//NSString *key;
	foreach(key,colorDefaults){
		[defaults willChangeValueForKey:key];
		[defaults removeObjectForKey:key];
		[defaults didChangeValueForKey:key];
	}
	[defaults synchronize];
	
	[self populateFields];
}


- (void)windowDidLoad{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogCacheChanged:) name:@"CatalogCacheChanged" object:nil];
    
    plistEditable=[[NSFileManager defaultManager] isWritableFileAtPath:[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"Contents/Info.plist"]];
//	[[self window] setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:3.0],@"duration",@"QSExtraExtraEffect",@"transformFn",@"show",@"type",nil]];
//	[[self window] setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSPurgeEffect",@"transformFn",@"hide",@"type",nil]];
	
	[[self window] center];
    [[self window] setFrameAutosaveName:@"preferences"];
    
    [[self window] setRepresentedFilename:[@"~/Library/Preferences/com.blacktree.Quicksilver.plist" stringByStandardizingPath]];
    [[[self window]standardWindowButton:NSWindowDocumentIconButton]setImage:[NSImage imageNamed:@"DocPrefs"]];
	
    //    [[self window]setFrame:[toolbarTabView contentRect] display:NO];
    //    [[self window]center];
    //}
    //[[self window] setFrameAutosaveName: @"preferences"];


	// [toolbarTabView setFrame:[[[self window]contentView]frame]];
	// [toolbarTabView setTabViewType:NSNoTabsNoBorder];
	//  [toolbarTabView setDrawsBackground:NO];
	////  [toolbarTabView selectFirstTabViewItem:self];

	/*
	 NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:@"preferencesToolbar"] autorelease];
	 [toolbar setDelegate:self];
	 [toolbar setAllowsUserCustomization:NO];
	 [toolbar setAutosavesConfiguration: NO];
	 [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	 
	 // if ([[toolbar class] instancesRespondToSelector:@selector(setSelectedItemIdentifier:)])
	 //     [toolbar performSelector:@selector(setSelectedItemIdentifier:) withObject:[[toolbarTabView selectedTabViewItem] identifier]];
	 
	 
	 // [toolbar _setToolbarView:[QSToolbarView newViewForToolbar:toolbar inWindow:[self window] attachedToEdge:NSMaxYEdge]];
	 [[self window] setToolbar:toolbar];
	 //   NSLog(@"tv %@",[toolbar _toolbarView]);
	 //   [toolbar _loadViewIfNecessary];
	 //NSLog(@"tv %@",[[[itemTabView tabView]tabViewItems]lastObject]);
	 //[[toolbar _toolbarView]_setDrawsBaseline:NO];
     */

	[NTViewLocalizer localizeView:modulesTabView table:@"Preferences" bundle:[NSBundle mainBundle]];

	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loadPlugInInfo:) name:QSPlugInLoadedNotification object:nil];


	NSEnumerator *moduleEnumerator=[[modulesTabView tabViewItems]objectEnumerator];
    NSTabViewItem *moduleTab=nil;
	[modules removeAllObjects];
    while (moduleTab=[moduleEnumerator nextObject]){
        NSImage *icon=[QSResourceManager imageNamed:[moduleTab identifier]];
		[modules addObject:[NSDictionary dictionaryWithObjectsAndKeys:[moduleTab label],kItemName,[moduleTab view],@"view",icon,kItemIcon,nil]];
	}
	//[modules addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"-",kItemName,nil]];
	// [[modulesTabView retain] removeFromSuperview];

	[self loadPlugInInfo:nil];
}

- (void)loadPlugInInfo:(NSNotification *)notif{
	
	NSString *currentPane=nil;
	if ([modulesTable selectedRow]>=0)
		currentPane=[[modules objectAtIndex:[modulesTable selectedRow]]objectForKey:kItemID];
	
	NSArray *loadedPanes=[modules valueForKey:kItemID];
	NSDictionary *plugInPanes=[QSReg tableNamed:kQSPreferencePanes];
	NSEnumerator *e=[plugInPanes keyEnumerator];
	NSString *paneKey=nil;
	while(paneKey=[e nextObject]){
		if ([loadedPanes containsObject:paneKey]) continue;
		
		NSString *paneClass=[plugInPanes objectForKey:paneKey];
		
		NSPreferencePane * obj=[QSReg getClassInstance:paneClass];
		NSString *locName=[[QSReg bundleForClassName:paneClass]safeLocalizedStringForKey:paneClass value:paneClass table:nil];
		[modules addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:obj,@"instance",paneKey,kItemID,locName,kItemName,[obj icon],kItemIcon,nil]];
	}
	
    NSSortDescriptor *nameDescriptor=[[[NSSortDescriptor alloc] initWithKey:kItemName ascending:YES] autorelease];
    [modules sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
	[modulesTable reloadData];
	
	int index=[[modules valueForKey:kItemID]indexOfObject:currentPane];
	if (index!=NSNotFound)[modulesTable selectRow:index byExtendingSelection:NO];
	
	[modulesTable reloadData];
	[self selectModule:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectModule:) name:NSTableViewSelectionDidChangeNotification object:modulesTable];
	
	
	//    [itemAddGroupButton setImage:[[[NSImage imageNamed:@"TintedFolderIcon"]copy]autorelease]];
	//[[itemAddGroupButton image]setSize:NSMakeSize(16,16)];
	
	
	
	
	NSMenuItem *item;
	[interfacePopUp removeAllItems];
	
	NSMutableDictionary *interfaces=[QSReg tableNamed:kQSCommandInterfaceControllers];
	NSEnumerator *keyEnum=[interfaces keyEnumerator];
	NSString *key, *title;
	while(key=[keyEnum nextObject]){
		title=[[QSReg bundleForClassName:[interfaces objectForKey:key]]safeLocalizedStringForKey:key value:key table:nil];
		item=(NSMenuItem *)[[interfacePopUp menu] addItemWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:key];
	}
	
	//	[self populatePopUp:chatMediatorsPopUp table:[QSReg tableNamed:kQSChatMediators] includeDefault:NO];
	//	[self populatePopUp:mailMediatorsPopUp table:[QSReg tableNamed:kQSMailMediators] includeDefault:YES];
	//	[self populatePopUp:finderProxyPopUp table:[QSReg tableNamed:kQSFSBrowserMediators]includeDefault:NO];
	//	[self populatePopUp:notifierMediatorsPopUp table:[QSReg tableNamed:kQSNotifiers]includeDefault:NO];
	//	
	[self populateFields];
	
	[self mainViewDidLoad];
	
}

- (void)selectItemInPopUp:(NSPopUpButton *)popUp representedObject:(id)object{
	
	int index=[popUp indexOfItemWithRepresentedObject:object];
	if(index==-1 && [popUp numberOfItems])index=0;
	//NSLog(@"index %d",index);
	[popUp selectItemAtIndex:index];
	
	
}

- (void)populatePopUp:(NSPopUpButton *)popUp table:(NSDictionary *)mediators includeDefault:(BOOL)includeDefault{
	[popUp setEnabled:[mediators count]];
	
	[popUp removeAllItems];
	if (![mediators count]){
		//[popUp insertItemWithTitle:@"None Installed" atIndex:0];
		[popUp setTitle:@"None Available"];
		return;
	}
	
	NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
	NSEnumerator *keyEnum=[mediators keyEnumerator];
	NSString *path,*key,*title;
	NSMenuItem *item=nil;
	while(key=[keyEnum nextObject]){
		title=nil;
		path=[workspace absolutePathForAppBundleWithIdentifier:key];
		if (!title){
			NSString *class=[mediators objectForKey:key];
			title=[[QSReg bundleForClassName:class]safeLocalizedStringForKey:class value:class table:nil];
		}
		if (!title && path){
			title=[[NSBundle bundleWithPath:path]objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
			if (!title) title=[[NSFileManager defaultManager] displayNameAtPath:path];
		}
		
		
        if (title){
			item=(NSMenuItem *)[[popUp menu] addItemWithTitle:title action:nil keyEquivalent:@""];
			if (path){
				[item setImage:[workspace iconForFile:path]];
			}
		}
		[[item image]setSize:NSMakeSize(16,16)];
		[item setRepresentedObject:key];
	}
	
	if (includeDefault){
		[[popUp menu]addItem:[NSMenuItem separatorItem]];
		[popUp addItemWithTitle:@"Default"];
	}
}


- (void) mainViewDidLoad{
    /*
     [librarian catalog]=[[NSMutableArray alloc] initWithContentsOfFile:[p stringByStandardizingPath]];
     if (![librarian catalog]){
         [librarian catalog]=[[NSMutableArray alloc]initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Items" ofType:@"plist"]];
     }
     if (![librarian catalog])
     [librarian catalog]=[[NSMutableArray alloc]initWithCapacity:1];
     */
    // NSTableColumn *tableColumn = nil;
    QSImageAndTextCell *imageAndTextCell = nil;
//	[modulesTable setRowHeight:17];
    imageAndTextCell = [[[QSImageAndTextCell alloc] init] autorelease];
    [[modulesTable tableColumnWithIdentifier: kItemName] setDataCell:imageAndTextCell];
    [[[modulesTable tableColumnWithIdentifier: kItemName]dataCell] setFont:[NSFont systemFontOfSize:11]];
	
	
    [self populateFields];
    
    
    [featureLevelMatrix selectCellWithTag:[NSApp featureLevel]];
	//  [[featureLevelMatrix cellWithTag:0]setEnabled:!DEVELOPMENTVERSION];
    [[featureLevelMatrix cellWithTag:2]setTransparent:!fBETA];
    [[featureLevelMatrix cellWithTag:3]setTransparent:!DEBUG];
    
	
}




//- (void)showPane:(NSString *)identifier{
//  [toolbarTabView selectTabViewItemWithIdentifier:identifier];
//}



//Outline Methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    if (tableView==modulesTable){
        return [modules count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if (aTableView==modulesTable){
        return [[modules objectAtIndex:rowIndex]objectForKey:kItemName];
        
    }
    return nil;   
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex{
    if (aTableView==modulesTable){
        return ![self tableView:aTableView rowIsSeparator:rowIndex];
    }
    return NO;   
}
- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex{
    if (aTableView==modulesTable){
        return [[[modules objectAtIndex:rowIndex]objectForKey:kItemName]isEqualToString:@"-"];
        
    }
    return NO;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
    return;
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
    //   NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    //   NSFileManager *manager=[NSFileManager defaultManager];
    if (aTableView==modulesTable){   
        NSImage *icon=[[modules objectAtIndex:rowIndex]objectForKey:kItemIcon];
		[icon createRepresentationOfSize:NSMakeSize(16,16)];
        [icon setSize:NSMakeSize(16,16)];
        [(QSImageAndTextCell*)aCell setImage:icon];
        return;
    }
}


- (NSView *)viewForModule:(NSMutableDictionary *)module{
	NSView *view=[module objectForKey:@"view"];
	if (!view){
		id obj=[module objectForKey:@"instance"];
		view=[obj loadMainView];
		[module setObject:view forKey:@"view"];
	}
	return view;
}
- (IBAction)selectModule:(id)sender{
	//NSView *content=
	
    [modulesView setContentView:[self viewForModule:[modules objectAtIndex:[modulesTable selectedRow]]]];
}



- (void) showHelp:(id)sender{
	NSString *urlString=[NSString stringWithFormat:@"http://docs.blacktree.com/?page=%@",[sender toolTip]];
	NSLog(urlString);
	if (urlString)	[[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:[urlString stringByReplacing:@" " with:@"+"]]];
}


- (void)populateFields{
    [startAtLoginSwitch setState:[self shouldLaunchAtLogin]];   
    [hideDockIconSwitch setState:[(QSApp *)NSApp shouldBeUIElement]];
    [hideDockIconSwitch setEnabled:plistEditable];
    [hideStatusMenuSwitch setState:[defaults boolForKey:kHideStatusMenu]];
    [hideStatusMenuSwitch setEnabled:[(QSApp *)NSApp shouldBeUIElement]];
	
	/*
	 int index=0;
	 index=[interfacePopUp indexOfItemWithRepresentedObject:[QSReg preferredCommandInterfaceID]];
	 [interfacePopUp selectItemAtIndex:index==NSNotFound?0:index];
	 
	 index=[finderProxyPopUp indexOfItemWithRepresentedObject:[defaults objectForKey:kQSFSBrowserMediators]];
	 [finderProxyPopUp selectItemAtIndex:index==NSNotFound?0:index];
	 index=[chatMediatorsPopUp indexOfItemWithRepresentedObject:[defaults objectForKey:kQSChatMediators]];
	 [chatMediatorsPopUp selectItemAtIndex:index==NSNotFound?0:index];
	 index=[mailMediatorsPopUp indexOfItemWithRepresentedObject:[QSReg mailMediatorID]];
	 [mailMediatorsPopUp selectItemAtIndex:index==NSNotFound?0:index];
	 index=[interfacePopUp indexOfItemWithRepresentedObject:[QSReg preferredCommandInterfaceID]];
	 [notifierMediatorsPopUp selectItemAtIndex:index==NSNotFound?0:index];
	 */
	
	[self selectItemInPopUp:interfacePopUp representedObject:[QSReg preferredCommandInterfaceID]];
	//[self selectItemInPopUp:finderProxyPopUp representedObject:[defaults objectForKey:kQSFSBrowserMediators]];
	//[self selectItemInPopUp:chatMediatorsPopUp representedObject:[defaults objectForKey:kQSChatMediators]];
	//[self selectItemInPopUp:mailMediatorsPopUp representedObject:[QSReg mailMediatorID]];
	//[self selectItemInPopUp:notifierMediatorsPopUp representedObject:[defaults objectForKey:kQSNotifiers]];
	
	
	
	NDHotKeyEvent *activationKey=[NDHotKeyEvent getHotKeyForKeyCode:[[defaults objectForKey:kHotKeyCode] unsignedShortValue]
														  character:NULL
												  safeModifierFlags:[[defaults objectForKey:kHotKeyModifiers] unsignedIntValue]];
	[hotKeyButton setTitle:[activationKey stringValue]];	
	
}


- (void)requestRelaunch{
    if (NSRunAlertPanel(@"Relaunch required", @"Quicksilver needs to be relaunched for this change to take effect", @"Relaunch", @"Later", nil))
        [(QSApp *)NSApp relaunch:self];
}
- (IBAction)setValueForSender:(id)sender{
    
    if (sender==startAtLoginSwitch){
        [self setShouldLaunchAtLogin:[sender state]];
    }    else if (sender==hideDockIconSwitch){
        [NSApp setShouldBeUIElement:[sender state]];
        [hideDockIconSwitch setState:[(QSApp *)NSApp shouldBeUIElement]];
        [self populateFields];
        
        if ([NSApp isUIElement]!=[sender state])
            [self requestRelaunch];
    }
    else if (sender==hideStatusMenuSwitch){
        [defaults setBool:[sender state] forKey:kHideStatusMenu];
        
        if ([sender state]){
            [(QSController *)[NSApp delegate]deactivateStatusMenu];
        }else{
            [(QSController *)[NSApp delegate]activateStatusMenu];
        }
    }
    
	else if (sender==featureLevelMatrix){
        int newLevel=[[sender selectedCell]tag];
        [defaults setInteger:newLevel forKey:kFeatureLevel];
        [defaults synchronize];
        if (newLevel!=[NSApp featureLevel])
            [self requestRelaunch];
        
    }
    else if (sender==interfacePopUp){
        NSString *newInterface=[[sender selectedItem]representedObject];
        [defaults setObject:newInterface forKey:kQSCommandInterfaceControllers];
        [self setValue:newInterface forMediator:kQSCommandInterfaceControllers];
		[[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseAllCachesNotification object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceChangedNotification object:self];
		[defaults synchronize];
		[self populateFields];
		
    }  
//    else if (sender==finderProxyPopUp){			[self setValue:[[sender selectedItem]representedObject] forMediator:kQSFSBrowserMediators];}  
//	else if (sender==chatMediatorsPopUp){		[self setValue:[[sender selectedItem]representedObject] forMediator:kQSChatMediators];}  
//	else if (sender==mailMediatorsPopUp){
//		[self setValue:[[sender selectedItem]representedObject] forMediator:kQSMailMediators];
//		[self populateFields];
//	}  
//	else if (sender==notifierMediatorsPopUp){	[self setValue:[[sender selectedItem]representedObject] forMediator:kQSNotifiers];}  
  //  [defaults synchronize];
    //NSLog(@"setvalue");
    //    [self populateItemFields];
}


- (BOOL)setValue:(NSString *)newMediator forMediator:(NSString *)mediatorType{
	[defaults setObject:newMediator forKey:mediatorType];
	[QSReg removePreferredInstanceOfTable:mediatorType];
}


- (BOOL)windowShouldClose:(id)sender{
    [defaults synchronize];
    return YES;
}



-(BOOL)shouldLaunchAtLogin{
    NSArray *loginItems = [(NSArray *) CFPreferencesCopyValue((CFStringRef) @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
    int i;
    for (i=0;i<[loginItems count];i++)
        if ([[[[loginItems objectAtIndex:i] objectForKey:@"Path"]stringByStandardizingPath]isEqualToString:[[NSBundle mainBundle]bundlePath]]) return YES;
    return NO;
}

-(void)setShouldLaunchAtLogin:(BOOL)launch{
    NSMutableArray*        loginItems;
    
    loginItems = [(NSMutableArray*) CFPreferencesCopyValue((CFStringRef) @"AutoLaunchedApplicationDictionary", (CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
    loginItems = [[loginItems mutableCopy]autorelease];
    
    if (!loginItems){
        if (DEBUG)
            NSLog(@"Creating AutoLaunchedApplicationDictionary");
        loginItems=[NSMutableArray arrayWithCapacity:1];
    }
    
    if (launch && ![self shouldLaunchAtLogin]){
        NSLog(@"Enabling Launch at login");
        NSDictionary *loginDict=[NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] bundlePath],@"Path",[NSNumber numberWithBool:NO],@"Hide",nil];
        [loginItems addObject:loginDict];
    }else if (!launch){
        int i;
        for (i=0;i<[loginItems count];i++)
            if ([[[[loginItems objectAtIndex:i] objectForKey:@"Path"]stringByStandardizingPath]isEqualToString:[[NSBundle mainBundle]bundlePath]]) break;
        if (i<[loginItems count])
            [loginItems removeObjectAtIndex:i];
        NSLog(@"Disable Login Launch");
    }
    
    CFPreferencesSetValue((CFStringRef) @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize((CFStringRef) @"loginwindow",kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}



- (IBAction)applySettings:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:nil];
    
    [(QSController *)[NSApp delegate]rescanItems:sender];
}


//Toolbar
/*
 - (void)changeTabView:(id)sender{
	 [sender setEnabled:NO];
	 //	 [toolbarTabView selectTabViewItemWithIdentifier:[sender itemIdentifier]];
	 //	 [[self window] setTitle:[NSString stringWithFormat:@"%@",[[toolbarTabView selectedTabViewItem]label]]];
 }
 
 - (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag{
	 
	 int index=[toolbarTabView indexOfTabViewItemWithIdentifier:itemIdentifier];
	 if (index==NSNotFound) return nil;
	 NSTabViewItem *tabViewItem=[toolbarTabView tabViewItemAtIndex:index];
	 NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	 [newItem setLabel:[tabViewItem label]];
	 [newItem setPaletteLabel:[tabViewItem label]];
	 [newItem setImage:[QSResourceManager imageNamed:itemIdentifier]];
	 [newItem setToolTip:[[tabViewItem view] toolTip]];
	 
	 [newItem setTarget:self];
	 [newItem setAction:@selector(changeTabView:)];
	 return newItem;
	 
	 return nil;
 }
 
 - (NSArray *)toolbarStandardItemIdentifiers:(NSToolbar*)toolbar{
	 return [NSArray arrayWithObjects:@"prefsModules",@"prefsCatalog",@"prefsActions",nil];
 }
 
 
 - (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar{
	 //NSEnumerator *tabViewEnumerator=[[toolbarTabView tabViewItems]objectEnumerator];
	 //if (!DEBUG)
	 // return [self toolbarStandardItemIdentifiers:toolbar];
	 // NSMutableArray *tabIdentifiers=[NSMutableArray arrayWithCapacity:[toolbarTabView numberOfTabViewItems]];
	 //NSTabViewItem *thisItem;
	 
	 //	 int i;
	 //	 NSString *identifier;
	 //	 for (i=0;i<[toolbarTabView numberOfTabViewItems];i++){
	 //		 identifier=[[toolbarTabView tabViewItemAtIndex:i]identifier];
	 //		 if (identifier) [tabIdentifiers addObject:identifier];
	 //	 }
	 //	 return tabIdentifiers;
	 return nil;
 }
 
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
 - (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar{
	 return nil;
	 //return [self toolbarDefaultItemIdentifiers:toolbar];
 }
#endif
 
 
 - (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar{
	 return nil;
	 //    return [NSArray arrayWithObjects:@"generalPrefs",@"desktopPrefs",@"editorPrefs",@"viewPrefs",NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
 }
 
 
 -(BOOL)validateToolbarItem:(NSToolbarItem*)toolbarItem{
	 return  [[self toolbarStandardItemIdentifiers:nil] containsObject:[toolbarItem itemIdentifier]];
 }
 
 
 */

@end
