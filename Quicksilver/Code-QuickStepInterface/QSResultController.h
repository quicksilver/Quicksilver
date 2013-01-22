

#import <AppKit/AppKit.h>

@class QSObjectView, QSSearchObjectView;

@interface QSResultController : NSWindowController
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
   <NSTableViewDataSource>
#endif
{
 @public
	IBOutlet NSTextField *	searchStringField;	// What the user types when searching (seen in the results view)
	IBOutlet NSTextField * searchModeField;	// Seen in the result view. Either: @"Filter Catalog", @"Filter Results" or @"Snap to Best"
	IBOutlet NSView *	selectionView;
	IBOutlet NSSplitView *	splitView;

	IBOutlet NSTableView *	resultTable;
	IBOutlet NSTableView *	resultChildTable;
	QSIconLoader *resultIconLoader;
	QSIconLoader *resultChildIconLoader;
	IBOutlet NSTextField *	resultCountField;

	IBOutlet NSMenuItem *filterCatalog; // NSMenuItem (see ResultController.xib)
	IBOutlet NSMenuItem *filterResults; // NSMenuItem (see ResultController.xib)
	IBOutlet NSMenuItem *snapToBest; //  NSMenuItem (see ResultController.xib)
 	IBOutlet NSMenu *searchModeMenu; // NSMenu opened when clicking the gear (see ResultController.xib)
	IBOutlet NSMenuItem *sortByScore; // NSMenuItem (see ResultController.xib)
	IBOutlet NSMenuItem *sortByName; // NSMenuItem (see ResultController.xib)
	
	NSInteger selectedResult;
	QSObject *selectedItem;
	BOOL browsing;
	BOOL needsReload;
	NSRange loadingRange;
	NSArray *currentResults;
	QSSearchObjectView *focus;
	NSInteger scrollViewTrackingRect;

//	NSArray **sourceArrayPointer;
	NSTimer *iconTimer;
	NSTimer *childrenLoadTimer;
	BOOL loadingIcons;
	BOOL loadingChildIcons;
	BOOL iconLoadValid;
	BOOL childIconLoadValid;

  //  NSRange visibleRange;
   // NSRange visibleChildRange;
}


@property (retain) IBOutlet NSTableView *resultTable;
@property (retain) NSArray *currentResults;
@property (retain) QSObject *selectedItem;
@property (retain) NSTextField *searchStringField;

+ (id)sharedInstance;

- (IBAction)defineMnemonic:(id)sender;
- (IBAction)setScore:(id)sender;
- (IBAction)clearMnemonics:(id)sender;
- (IBAction)omitItem:(id)sender;
- (IBAction)assignAbbreviation:(id)sender;

- (id)initWithFocus:(id)myFocus;

//- (void)setSplitLocation;

- (void)loadChildren;
/*!
 setSearchFilterAllActivated
 @abstract   Sets the results view to show the 'Filter Catalog' search mode is activated
 @discussion  Sets the results view to show the 'Filter Catalog' search mode is selected 
 by setting the NSMenuItem's state and the 'searchModeField' string value to @"(Filter Catalog")
 */
- (IBAction)setSearchFilterAllActivated;
/*!
 setSearchFilterActivated
 @abstract   Sets the results view to show the 'Filter Results' search mode is activated
 @discussion  Sets the results view to show the 'Filter Catalog' search mode is selected 
 by setting the NSMenuItem's state and the 'searchModeField' string value to @"(Filter Results")
 */
- (IBAction)setSearchFilterActivated;
/*!
 setSearchSnapActivated
 @abstract   Sets the results view to show the 'Snap to Best' search mode is activated
 @discussion  Sets the results view to show the 'Filter Catalog' search mode is selected 
 by setting the NSMenuItem's state and the 'searchModeField' string value to @"(Snap to Best")
 */
- (IBAction)setSearchSnapActivated;
/*!
 setSearchMode
 @abstract   Sets the search mode for Quicksilver
 @discussion Sets the search mode which can be one of: 'Filter Results, 'Filter Catalog' or 'Snap to Best'
 @param      sender IB NSMenuItem within the 'Search Mode' menu
 */
- (IBAction)setSearchMode:(id)sender;
- (void)arrayChanged:(NSNotification*)notif;
- (void)bump:(NSInteger)i;

- (void)updateSelectionInfo;
- (QSObject *)selectedItem;
- (void)setSelectedItem:(QSObject *)newSelectedItem;
- (NSArray *)currentResults;
- (void)setCurrentResults:(NSArray *)newCurrentResults;

- (QSIconLoader *)resultIconLoader;
- (void)setResultIconLoader:(QSIconLoader *)aResultIconLoader;

- (QSIconLoader *)resultChildIconLoader;
- (void)setResultChildIconLoader:(QSIconLoader *)aResultChildIconLoader;
- (void)objectIconModified:(NSNotification *)notif;
/*!
 sortByName
 @abstract   Sets the results view to show the 'Sort by Name' search mode is activated
 @discussion  Sets the results view to show the 'Sort by Name' search mode is selected 
by altering its state to enabled (Adds a checkmark in the menu)
 @param sender The NSMenuItem clicked in the interface
 */
- (IBAction)sortByName:(id)sender;
/*!
 sortByScore
 @abstract   Sets the results view to show the 'Sort by Score' search mode is activated
 @discussion  Sets the results view to show the 'Sort by Score' search mode is selected 
 by altering its state to enabled (Adds a checkmark in the menu)
 @param sender The NSMenuItem clicked in the interface
 */
- (IBAction)sortByScore:(id)sender;
@end


@interface QSResultController (Table)

- (void)setupResultTable;
- (IBAction)tableViewDoubleAction:(id)sender;

@end
