/* QSPlugInsPrefPane */

#import <Cocoa/Cocoa.h>

#import <PreferencePanes/PreferencePanes.h>
//#import "QSFilteringArrayController.h"

//#import "QSPreferencePane.h"

@interface QSPlugInsPrefPane : QSPreferencePane
{
	IBOutlet QSTableView *pluginSetsTable;
    IBOutlet id plugInTable;
    IBOutlet id plugInText;
	IBOutlet NSTextField *statusField;
	IBOutlet NSDrawer *infoDrawer;
	IBOutlet NSPopUpButton *viewPopUp;
	IBOutlet NSPopUpButton *categoryPopUp;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSArrayController *setsArrayController;
	NSMutableArray *plugInArray;
	NSMutableArray *plugins;
	NSMutableSet *disabledPlugIns;
	int viewMode;
	
	NSString *search;
	NSString *category;
	
	IBOutlet NSView *sidebar;
}
+ (void)getMorePlugIns;
- (int)viewMode;
- (void)setViewMode:(int)newViewMode;


- (IBAction)showPlugInsFolder:(id)sender;
- (IBAction)updatePlugIns:(id)sender;
- (IBAction)showPlugInsRSS:(id)sender;
- (IBAction)reloadPlugIns:(id)sender;
- (IBAction)copyInstallURL:(id)sender;
- (IBAction)downloadInBrowser:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)installSelectedPlugIns:(id)sender;
- (IBAction)showHelp:(id)sender;

- (IBAction)deleteSelection:(id)sender;

- (void)reloadPlugInsList:(NSNotification *)notif;
- (BOOL)showInfoForPlugIn:(NSBundle *)bundle;

- (NSMutableArray *)plugins;
- (void)setPlugins:(NSMutableArray *)newPlugins;


- (NSString *)search;
- (void)setSearch:(NSString *)newSearch;
- (NSString *)category;
- (void)setCategory:(NSString *)newCategory;

- (void)reloadPlugInsList:(NSNotification *)notif;
- (void)reloadFilters;
- (NSArray *)selectedPlugIns;

- (void)setViewMode:(int)newViewMode;
- (void)reloadFiltersIgnoringViewMode:(BOOL)ignoreView;
@end
