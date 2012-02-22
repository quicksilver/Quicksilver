#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import <QSInterface/QSPreferencePane.h>
#import "QSPlugIn.h"

@interface QSPlugInsPrefPane : QSPreferencePane {
	IBOutlet NSTableView *pluginSetsTable;
	IBOutlet NSTableView *plugInTable;
	NSString *plugInName;
	IBOutlet id plugInText;
	IBOutlet NSTextField *statusField;
	IBOutlet NSDrawer *infoDrawer;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSController *setsArrayController;
	NSMutableArray *plugInArray;
	NSMutableArray *plugins;
	NSMutableSet *disabledPlugIns;
	int viewMode;

	NSString *search;
	NSString *category;

	IBOutlet NSView *sidebar;
	IBOutlet NSPanel *pluginInfoPanel;
}
@property NSString *plugInName;
@property (readonly) NSPanel *pluginInfoPanel;
+ (void)getMorePlugIns;
- (int) viewMode;
- (void)setViewMode:(int)newViewMode;


- (IBAction)showPlugInsFolder:(id)sender;
- (IBAction)updatePlugIns:(id)sender;
- (IBAction)reloadPlugIns:(id)sender;
- (IBAction)copyInstallURL:(id)sender;
- (IBAction)downloadInBrowser:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)installSelectedPlugIns:(id)sender;
- (IBAction)showHelp:(id)sender;

- (IBAction)deleteSelection:(id)sender;

- (void)reloadPlugInsList:(NSNotification *)notif;

- (NSMutableArray *)plugins;
- (void)setPlugins:(NSArray *)newPlugins;


- (NSString *)search;
- (void)setSearch:(NSString *)newSearch;
- (NSString *)category;
- (void)setCategory:(NSString *)newCategory;

- (void)reloadPlugInsList:(NSNotification *)notif;
- (void)reloadFilters;
- (NSArray *)selectedPlugIns;

- (void)setViewMode:(int)newViewMode;
- (void)reloadFiltersIgnoringViewMode:(BOOL)ignoreView;

- (id)preferencesSplitView;
@end
