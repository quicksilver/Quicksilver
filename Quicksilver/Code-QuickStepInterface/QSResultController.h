

#import <AppKit/AppKit.h>

@class QSObjectView, QSSearchObjectView;

// added by RCS
@class QSMenuButton;

@interface QSResultController : NSWindowController
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
   <NSTableViewDataSource>
#endif
{
 @public
	IBOutlet NSTextField *	searchStringField;
	IBOutlet NSView *	selectionView;
	IBOutlet NSSplitView *	splitView;

	IBOutlet NSTableView *	resultTable;
	IBOutlet NSTableView *	resultChildTable;
	QSIconLoader *resultIconLoader;
	QSIconLoader *resultChildIconLoader;
	IBOutlet NSTextField *	resultCountField;
	IBOutlet NSMenu *searchModeMenu;

    // added by RCS
    // I added an outlet for the search mode menu button. I made the corresponding assignment within the ResultWindow.xib file in Interface Builder.
    IBOutlet QSMenuButton *searchModeMenuButton;
    
    int selectedResult;
	QSObject *selectedItem;
	BOOL browsing;
	BOOL needsReload;
	NSRange loadingRange;
	NSArray *currentResults;
	QSSearchObjectView *focus;
	int scrollViewTrackingRect;

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


- (IBAction)defineMnemonic:(id)sender;
- (IBAction)setScore:(id)sender;
- (IBAction)clearMnemonics:(id)sender;
- (IBAction)omitItem:(id)sender;
- (IBAction)assignAbbreviation:(id)sender;

// added by RCS
// event handler triggered by searchModeMenuButton - this link is made in Interface Builder
- (IBAction)searchModeMenuButtonPressed:(id)sender;

- (id)initWithFocus:(id)myFocus;

//- (void)setSplitLocation;

- (void)loadChildren;
- (IBAction)setSearchMode:(id)sender;
- (void)arrayChanged:(NSNotification*)notif;
- (void)bump:(int)i;

- (void)updateSelectionInfo;
- (QSObject *)selectedItem;
- (void)setSelectedItem:(QSObject *)newSelectedItem;
- (NSArray *)currentResults;
- (void)setCurrentResults:(NSArray *)newCurrentResults;

- (QSIconLoader *)resultIconLoader;
- (void)setResultIconLoader:(QSIconLoader *)aResultIconLoader;

- (QSIconLoader *)resultChildIconLoader;
- (void)setResultChildIconLoader:(QSIconLoader *)aResultChildIconLoader;

-(void)rowModified:(int)index;
//- (IBAction)sortByName:(id)sender;
//- (IBAction)sortByScore:(id)sender;
@end


@interface QSResultController (Table)

- (void)setupResultTable;
- (IBAction)tableViewDoubleAction:(id)sender;

@end
