

#import <Cocoa/Cocoa.h>
#import "QSLibrarian.h"


@interface NSSegmentedControl (SelectedIndex)
    - (int)indexOfSelectedItem;
@end;

@interface QSPrefsController : NSWindowController {
    //NSMutableArray *itemArray;
    
    IBOutlet NSTabView *modulesTabView;    
    IBOutlet NSTableView *modulesTable;
    
    IBOutlet NSBox *modulesView;
    //General
    IBOutlet NSButton *startAtLoginSwitch;
    IBOutlet NSButton *hideDockIconSwitch;
    IBOutlet NSButton *hideStatusMenuSwitch;
    IBOutlet NSMatrix *featureLevelMatrix;
    

    //Services
    
    IBOutlet NSPopUpButton *finderProxyPopUp;
    IBOutlet NSPopUpButton *mailMediatorsPopUp;
    IBOutlet NSPopUpButton *chatMediatorsPopUp;
    IBOutlet NSPopUpButton *notifierMediatorsPopUp;

    IBOutlet NSButton *hotKeyButton;
    
    IBOutlet NSPopUpButton *interfacePopUp;
    //IBOutlet NSButton *itemOptionsButton;
    
    
    QSLibrarian *librarian;
    NSUserDefaults *defaults;
    
    NSMutableArray *modules;
    BOOL plistEditable;
    
    
}

- (void) mainViewDidLoad;
- (IBAction)changeHotkey:(id)sender;
- (IBAction)selectModule:(id)sender;
- (void)populateFields;
- (IBAction)setValueForSender:(id)sender;
- (IBAction)applySettings:(id)sender;
- (IBAction)resetColors:(id)sender;
-(BOOL)shouldLaunchAtLogin;
-(void)setShouldLaunchAtLogin:(BOOL)launch;
- (void)populatePopUp:(NSPopUpButton *)popUp table:(NSDictionary *)mediators;
//- (IBAction)tableViewAction:(id)sender;

- (void)loadPlugInInfo:(NSNotification *)notif;
- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex;
- (BOOL)setValue:(NSString *)newMediator forMediator:(NSString *)mediatorType;

@end
