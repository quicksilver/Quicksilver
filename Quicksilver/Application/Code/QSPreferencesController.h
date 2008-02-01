/* QSPreferencesController */

#import <Cocoa/Cocoa.h>

#define kQSPreferencesSplitWidth @"QSPreferencesSplitWidth"

@interface QSPreferencesController : NSWindowController
{
    IBOutlet NSTextField *descView;
    IBOutlet NSTableView *externalPrefsTable;
    IBOutlet NSButton *helpButton;
    IBOutlet NSImageView *iconView;
    IBOutlet QSTableView *internalPrefsTable;
    IBOutlet NSView *loadingView;
    IBOutlet NSTextField *nameView;
    IBOutlet NSProgressIndicator *loadingProgress;
    IBOutlet NSArrayController *moduleController;
	
	IBOutlet NSView *toolbarTitleView;
	
    IBOutlet NSBox *mainBox;
	
    IBOutlet NSBox *prefsBox;

    IBOutlet NSBox *settingsPrefsBox;
    IBOutlet NSBox *toolbarPrefsBox;
	
	IBOutlet NSSplitView *settingsSplitView;
	IBOutlet NSView *sidebarView;
	IBOutlet NSView *settingsView;
	IBOutlet NSBox *fillerBox;
	
	IBOutlet NSSegmentedControl *historyView;
	
	NSToolbar *toolbar;
	NSMutableDictionary *currentPaneInfo;	
	QSPreferencePane *currentPane;
	
	NSMutableDictionary *modulesByID;
    NSMutableArray *modules;
	
	BOOL relaunchRequested;
	
	BOOL showingSettings;
	BOOL reloading;
}
- (IBAction)back:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)selectModule:(id)sender;
+ (QSPreferencePane *)showPaneWithIdentifier:(NSString *)identifier;
+ (void)showPrefs;
- (NSMutableArray *)modules;
- (void)setModules:(NSMutableArray *)newModules;
- (QSPreferencePane *)currentPane;
- (void)setCurrentPane:(QSPreferencePane *)newCurrentPane;
- (BOOL)relaunchRequested;
- (void)setPaneForInfo:(NSMutableDictionary *)info switchSection:(BOOL)switchSection;
- (void)setRelaunchRequested:(BOOL)flag;
- (void)preventEmptySelection;
- (NSMutableDictionary *)currentPaneInfo;
- (void)setCurrentPaneInfo:(NSMutableDictionary *)newCurrentPaneInfo;
- (void)selectPaneWithIdentifier:(NSString *)identifier;

@end
