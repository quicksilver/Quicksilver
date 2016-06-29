

#import <QSInterface/QSInterface.h>
#import <QSInterface/QSInterfaceController.h>

@class QSObjectView, QSSearchObjectView, QSTableView;

@interface QSResultController : NSWindowController

@property (strong) IBOutlet QSSearchObjectView *objectView;
@property (assign) QSSearchMode searchMode;
@property (assign) QSSearchOrder searchOrder;

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
@property (strong) IBOutlet NSMenuItem *sortByModDate;  // NSMenuItem (see ResultController.xib)

+ (id)sharedInstance;

- (id)initWithObjectView:(QSObjectView *)objectView;

- (IBAction)defineMnemonic:(id)sender;
- (IBAction)setScore:(id)sender;
- (IBAction)clearMnemonics:(id)sender;
- (IBAction)omitItem:(id)sender;
- (IBAction)assignAbbreviation:(id)sender;


- (void)arrayChanged:(NSNotification*)notif;

- (void)bump:(NSInteger)i;

- (void)updateSelectionInfo;

- (QSIconLoader *)resultIconLoader;
- (void)setResultIconLoader:(QSIconLoader *)aResultIconLoader;

- (QSIconLoader *)resultChildIconLoader;
- (void)setResultChildIconLoader:(QSIconLoader *)aResultChildIconLoader;
- (void)objectIconModified:(NSNotification *)notif;

@end


@interface QSResultController (Table)

- (void)setupResultTable;
- (IBAction)tableViewDoubleAction:(id)sender;

@end
