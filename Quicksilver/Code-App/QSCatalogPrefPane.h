#import <Cocoa/Cocoa.h>
#import "QSLibrarian.h"


#import "QSPreferencePane.h"

#define QSCodedCatalogEntryPasteboardType @"QSCatalogEntry"

//
//@interface NSSegmentedControl (SelectedIndex)
//- (int) indexOfSelectedItem;
//@end;
//@class QSPrefsController;
@interface QSCatalogPrefPane : QSPreferencePane <NSOutlineViewDataSource, NSOutlineViewDelegate> {

	IBOutlet NSTableView *catalogSetsTable;
	//NSMutableArray *itemArray;

	IBOutlet NSArrayController *catalogSetsController;

	IBOutlet NSTreeController *treeController;
	IBOutlet NSArrayController *contentsController;
	IBOutlet NSTabView *itemOptionsTabView;
	IBOutlet NSDrawer *itemContentsDrawer;

	//Item
	IBOutlet QSOutlineView *itemTable;
	IBOutlet NSTableView *itemContentsTable;
	IBOutlet NSImageView *itemIconField;
	IBOutlet NSButton *itemAddButton;
    IBOutlet NSButton *infoButton;
    IBOutlet NSButton *refreshButton;
    IBOutlet NSButton *itemRemoveButton;

	IBOutlet NSBox *itemOptionsView;

	QSCatalogEntry *currentItem;
	NSMutableDictionary *currentItemSettings;
	NSArray *currentItemContents;

	BOOL currentItemHasSettings;

	IBOutlet NSView *messageView;
	IBOutlet NSTextField *messageTextField;

//	QSLibrarian *librarian;
//	NSUserDefaults *defaults;
//	NSDictionary *presetsDictionary;

	NSArray *draggedEntries;
	NSArray *draggedIndexPaths;

//	NSMutableDictionary *iconCache;

	IBOutlet NSView *sidebar;
}

+ (id)sharedInstance;

- (IBAction)addSource:(id)sender;
//- (IBAction)addSourcePreset:(id)sender;
//- (IBAction)removeItem:(id)sender;

- (IBAction)saveItem:(id)sender;
//- (IBAction)tableViewAction:(id)sender;
- (IBAction)copyPreset:(id)sender;

//-(IBAction)toggleCatalogOptions:(id)sender;
- (IBAction)restoreDefaultCatalog:(id)sender;
	//- (void)populateItemFields;

- (void)populateCatalogEntryFields;
- (IBAction)removeItem:(id)sender;

- (IBAction)setValueForSenderForCatalogEntry:(id)sender;
			   //- (IBAction)restoreDefaults:(id)sender;
- (IBAction)applySettings:(id)sender;
- (IBAction)rescanCurrentItem:(id)sender;

//-(IBAction)toggleCatalogOptions:(id)sender;
//-(void)hideCatalogOptions;
//-(void)showCatalogOptions;
//- (void)convertPreset:(NSMutableDictionary *)presetDict;
//- (void)convertPresetArray:(NSArray *)array;
- (NSArray *)currentItemContents;
- (void)setCurrentItemContents:(NSArray *)newCurrentItemContents;


//- (BOOL)outlineView:(NSOutlineView *)outlineView removeChild:(int)index ofItem:(id)item;
//- (BOOL)outlineView:(NSOutlineView *)outlineView addChild:(id)childItem toItem:(id)item atIndex:(int)index;
//- (BOOL)outlineView:(NSOutlineView *)outlineView removeRows:(NSIndexSet *)rows;

- (BOOL)outlineView:(NSOutlineView *)aTableView itemIsSeparator:(id)item;
//- (void)updateCurrentItemContents;

- (void)updateEntrySelection;

- (QSCatalogEntry *)currentItem;
- (void)setCurrentItem:(QSCatalogEntry *)newCurrentItem;
+ (void)addEntryForCatFile:(NSString *)path;
+ (void)showEntryInCatalog:(QSCatalogEntry *)entry;

- (void)selectEntry:(QSCatalogEntry *)entry;
- (QSCatalogEntry *)entryForCatFile:(NSString *)path;

- (void)showOptionsDrawer;
@end
