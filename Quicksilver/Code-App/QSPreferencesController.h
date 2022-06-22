#import <Cocoa/Cocoa.h>

#import "QSPreferencePane.h"
#include <PreferencePanes/PreferencePanes.h>
#define kQSPreferencesSplitWidth @"QSPreferencesSplitWidth"

@class WebView;

@interface QSPreferencesController : NSWindowController <NSToolbarDelegate, NSWindowDelegate, NSSplitViewDelegate>
{
	IBOutlet NSTextField *descView;
	IBOutlet NSTableView *externalPrefsTable;
	IBOutlet NSButton *helpButton;
	IBOutlet NSImageView *iconView;
	IBOutlet QSFancyTableView *internalPrefsTable;
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

    IBOutlet NSPanel *pluginInfoPanel;
    IBOutlet WebView *pluginHelpHTMLView;

//	IBOutlet NSSegmentedControl *historyView;

	NSToolbar *toolbar;
	NSMutableDictionary *currentPaneInfo;
	QSPreferencePane *currentPane;

	NSMutableDictionary *modulesByID;
	NSMutableArray *modules;

	BOOL relaunchRequested;

	BOOL showingSettings;
	BOOL reloading;
}
//- (IBAction)back:(id)sender;
//- (IBAction)next:(id)sender;
//- (IBAction)selectModule:(id)sender;
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

- (void)setWindowTitleWithInfo:(NSDictionary *)info;
- (void)setShowSettings:(BOOL)flag;
- (void)loadPlugInInfo:(NSNotification *)notif;
- (void)selectSettingsPane:(id)sender;
- (void)matchSplitView:(NSSplitView *)split;

- (IBAction)showHelpForPluginPane:(id)sender;

@end
