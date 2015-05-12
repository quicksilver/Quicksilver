

#import <AppKit/AppKit.h>

@class QSObjectView, QSSearchObjectView, QSTableView;

@interface QSResultController : NSWindowController

@property (strong) IBOutlet QSSearchObjectView *objectView;

@property (strong) NSArray *currentResults;
@property (strong) QSObject *selectedItem;

// TODO: Most of you are meant to become private
@property (strong) IBOutlet QSTableView *resultTable;

@property (strong) IBOutlet NSTextField *searchStringField;	// What the user types when searching (seen in the results view)
@property (strong) IBOutlet NSTextField *searchModeField;	// Seen in the result view. Either: @"Filter Catalog", @"Filter Results" or @"Snap to Best"
@property (strong) IBOutlet NSTextField *selectionView;
@property (strong) IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet QSTableView *resultChildTable;

@property (strong) IBOutlet NSTextField *resultCountField;

// FIXME: Isn't that a little too much outlets ?
@property (strong) IBOutlet NSMenuItem *filterCatalog;  // NSMenuItem (see ResultController.xib)
@property (strong) IBOutlet NSMenuItem *filterResults;  // NSMenuItem (see ResultController.xib)
@property (strong) IBOutlet NSMenuItem *snapToBest;     // NSMenuItem (see ResultController.xib)
@property (strong) IBOutlet NSMenu     *searchModeMenu; // NSMenu opened when clicking the gear (see ResultController.xib)
@property (strong) IBOutlet NSMenuItem *sortByScore;    // NSMenuItem (see ResultController.xib)
@property (strong) IBOutlet NSMenuItem *sortByName;     // NSMenuItem (see ResultController.xib)

+ (id)sharedInstance;

- (id)initWithObjectView:(QSObjectView *)objectView;

- (IBAction)defineMnemonic:(id)sender;
- (IBAction)setScore:(id)sender;
- (IBAction)clearMnemonics:(id)sender;
- (IBAction)omitItem:(id)sender;
- (IBAction)assignAbbreviation:(id)sender;


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
