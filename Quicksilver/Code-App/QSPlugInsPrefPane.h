#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import <QSInterface/QSPreferencePane.h>
#import "QSPlugIn.h"

@interface QSPlugInsPrefPane : QSPreferencePane {
	IBOutlet NSTableView *pluginSetsTable;
	IBOutlet NSTableView *plugInTable;
	NSString *plugInName;
	IBOutlet WebView *plugInText;
	IBOutlet NSTextField *statusField;
	IBOutlet NSDrawer *infoDrawer;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSTreeController *setsArrayController;
	NSMutableArray *plugInArray;
	NSMutableArray *plugins;
	NSMutableSet *disabledPlugIns;
	NSInteger viewMode;

	NSString *search;
	NSString *category;

	IBOutlet NSView *sidebar;
	IBOutlet NSPanel *pluginInfoPanel;
    
    IBOutlet NSButton *refreshButton;
    IBOutlet NSButton *infoButton;
    IBOutlet NSButton *docsButton;
}
@property (copy,readwrite,nonatomic) NSString *plugInName;
+ (void)getMorePlugIns;
- (NSInteger) viewMode;
- (void)setViewMode:(NSInteger)newViewMode;


- (IBAction)showPlugInsFolder:(id)sender;
- (IBAction)updatePlugIns:(id)sender;
- (IBAction)reloadPlugIns:(id)sender;
- (IBAction)copyInstallURL:(id)sender;
- (IBAction)downloadInBrowser:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)installSelectedPlugIns:(id)sender;

- (IBAction)deleteSelection:(id)sender;

- (void)reloadPlugInsList:(NSNotification *)notif;

- (NSMutableArray *)plugins;
- (void)setPlugins:(NSArray *)newPlugins;


- (NSString *)search;
- (void)setSearch:(NSString *)newSearch;
- (NSString *)category;
- (void)setCategory:(NSString *)newCategory;

- (void)reloadFilters;
- (NSArray *)selectedPlugIns;

- (void)reloadFiltersIgnoringViewMode:(BOOL)ignoreView;

@end
