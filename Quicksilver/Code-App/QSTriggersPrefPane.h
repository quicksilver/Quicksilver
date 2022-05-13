#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import "QSPreferencePane.h"

@class QSCommandBuilder, QSTrigger;

@interface QSTriggersArrayController : NSArrayController
@end

@interface QSTriggersPrefPane : QSPreferencePane <NSOutlineViewDelegate, NSOutlineViewDataSource> {
	IBOutlet NSButton *addButton;
	IBOutlet NSDrawer *optionsDrawer;
	IBOutlet NSView *sidebar;

    IBOutlet NSButton *infoButton;
	IBOutlet NSButton *removeButton;
	IBOutlet NSOutlineView * triggerTable;

	IBOutlet NSTableView * triggerSetsTable;
	
	// 'edit' button in the drawer's 'command' tab 
	IBOutlet NSButton *editButton;
	
	IBOutlet NSArrayController *triggerSetsController;

	IBOutlet NSArrayController *triggerArrayController;
	IBOutlet NSTreeController *triggerTreeController;

	IBOutlet NSTabView *drawerTabView;
	IBOutlet NSTabViewItem *settingsItem;

    NSMenu *typeMenu;

	NSMutableArray *triggerSets;
	QSCommandBuilder *commandEditor;

	NSSortDescriptor *sort;
	NSString *search;
	NSString *currentSet;

	QSTrigger *selectedTrigger;
	NSSplitView *splitView;
	BOOL isRearranging;
}
+ (QSTriggersPrefPane *)sharedInstance;

- (NSString *)currentSet;
- (void)setCurrentSet:(NSString *)value;

- (QSTrigger *)selectedTrigger;
- (void)setSelectedTrigger:(QSTrigger *)newSelectedTrigger;

- (NSMutableArray *)triggerSets;
- (void)setTriggerSets:(NSMutableArray *)newTriggerSets;

- (NSArray *)triggerArray;

- (NSSortDescriptor *)sort;
- (void)setSort:(NSSortDescriptor *)newSort;

- (IBAction)addTrigger:(id)sender;
- (IBAction)removeTrigger:(id)sender;
- (IBAction)editTrigger:(id)sender;
- (IBAction)selectTrigger:(id)sender;

- (IBAction)showTriggerInfo:(id)sender;
- (IBAction)hideTriggerInfo:(id)sender;
- (NSInteger)tabViewIndex;
- (void)setTabViewIndex:(NSInteger)index;

- (IBAction)editCommand:(id)sender;

- (void)populateTypeMenu;
- (void)reloadFilters;

- (void)showTrigger:(QSTrigger *)trigger;
- (void)showTriggerGroupWithIdentifier:(NSString *)groupID;

@end
