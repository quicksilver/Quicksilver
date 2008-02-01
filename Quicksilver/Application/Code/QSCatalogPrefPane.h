

#import <Cocoa/Cocoa.h>
//#import "QSLibrarian.h"


//#import "QSPreferencePane.h"

#define QSCodedCatalogEntryPasteboardType @"QSCatalogEntry"

//
//@interface NSSegmentedControl (SelectedIndex)
//- (int)indexOfSelectedItem;
//@end;
//@class QSPrefsController;
@interface QSCatalogPrefPane : QSPreferencePane {
	
    IBOutlet QSTableView *catalogSetsTable;
    //NSMutableArray *itemArray;
	
    IBOutlet NSArrayController *catalogSetsController;

    IBOutlet NSTreeController *treeController;
    IBOutlet NSArrayController *contentsController;
    IBOutlet NSTabView *itemOptionsTabView;
    IBOutlet NSTabViewItem *itemTabView;
    IBOutlet NSDrawer *itemContentsDrawer;
    IBOutlet NSSplitView *catalogSplitView;
    
    
    //Item
    IBOutlet NSPopUpButton *sourcePopUp;
    IBOutlet QSOutlineView *itemTable;
    IBOutlet QSTableView *itemContentsTable;
    IBOutlet NSTextField *itemNameField;
    IBOutlet NSImageView *itemIconField;
    IBOutlet NSButton *itemAddButton;
    
    IBOutlet NSButton *itemAddGroupButton;
    IBOutlet NSButton *itemDeleteButton;
    IBOutlet NSBox *itemOptionsView;
    
    
    IBOutlet NSPopUpButton *itemViewSwitcher;
    
    QSCatalogEntry *currentItem;
    NSMutableDictionary *currentItemSettings;
    IBOutlet NSButton *currentItemDeleteButton;
    IBOutlet NSButton *currentItemAddButton;
    NSArray *currentItemContents;
    
    BOOL currentItemHasSettings;
    
    IBOutlet NSView *messageView;
    IBOutlet NSTextField *messageTextField;
    
    QSLibrarian *librarian;
    NSUserDefaults *defaults;
    NSDictionary *presetsDictionary;
    
    NSArray *draggedEntries;
    NSArray *draggedIndexPaths;
	
	NSMutableDictionary *iconCache;
	
    IBOutlet NSView *sidebar;
}

- (IBAction) addSource:(id)sender;
//- (IBAction) addSourcePreset:(id)sender;
//- (IBAction) removeItem:(id)sender;

- (IBAction) saveItem:(id)sender;
//- (IBAction)tableViewAction:(id)sender;
- (IBAction)copyPreset:(id)sender;

//-(IBAction) toggleCatalogOptions:(id)sender;
- (IBAction)restoreDefaultCatalog:(id)sender;
    //- (void)populateItemFields;

- (void)populateCatalogEntryFields;

- (IBAction)setValueForSenderForCatalogEntry:(id)sender;
               //- (IBAction)restoreDefaults:(id)sender;
- (IBAction)applySettings:(id)sender;
- (IBAction)rescanCurrentItem:(id)sender;

//-(IBAction) toggleCatalogOptions:(id)sender;
//-(void) hideCatalogOptions;
//-(void) showCatalogOptions;
//- (void)convertPreset:(NSMutableDictionary *)presetDict;
//- (void)convertPresetArray:(NSArray *)array;
- (NSArray *)currentItemContents;
- (void)setCurrentItemContents:(NSArray *)newCurrentItemContents;


//- (BOOL)outlineView:(NSOutlineView *)outlineView removeChild:(int)index ofItem:(id)item;
//- (BOOL)outlineView:(NSOutlineView *)outlineView addChild:(id)childItem toItem:(id)item atIndex:(int)index;
//- (BOOL)outlineView:(NSOutlineView *)outlineView removeRows:(NSIndexSet *)rows;

- (BOOL)outlineView:(NSOutlineView *)aTableView itemIsSeparator:(id)item;
- (void) updateCurrentItemContents;

-(void)updateEntrySelection;

- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex;

- (QSCatalogEntry *)currentItem;
- (void)setCurrentItem:(QSCatalogEntry *)newCurrentItem;
+ (void) addEntryForCatFile:(NSString *)path;
+ (void) showEntryInCatalog:(QSCatalogEntry *)entry;

- (void) selectEntry:(QSCatalogEntry *)entry;
-(QSCatalogEntry *)entryForCatFile:(NSString *)path;
@end
