

#import <AppKit/AppKit.h>
#import "QSIconLoader.h"
@class QSObjectView;

@class QSSearchObjectView;
@interface QSResultController : NSWindowController {
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
    int selectedResult;
    QSObject *selectedItem;
    BOOL browsing;
    BOOL needsReload;
	NSRange loadingRange;
    NSArray *currentResults;
    QSSearchObjectView *focus;
	int scrollViewTrackingRect;

//    NSArray **sourceArrayPointer;
    NSTimer *iconTimer;
    NSTimer *childrenLoadTimer;
    BOOL hideChildren;
    BOOL loadingIcons;
    BOOL loadingChildIcons;
    BOOL iconLoadValid;
    BOOL childIconLoadValid;

  //  NSRange visibleRange;
   // NSRange visibleChildRange;
}
- (NSTextField *)searchStringField;
- (NSTableView *)resultTable;


- (IBAction)defineMnemonic:(id)sender;
- (IBAction)setScore:(id)sender;
- (IBAction)clearMnemonics:(id)sender;
- (IBAction)omitItem:(id)sender;
- (IBAction)assignAbbreviation:(id)sender;

- (id)initWithFocus:(id)myFocus;

//- (void) setSplitLocation;

-(void)loadChildren;
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
- (void) setSplitLocation;

//- (IBAction)sortByName:(id)sender;
//- (IBAction)sortByScore:(id)sender;
@end


@interface QSResultController (Table)

- (void)setupResultTable;
- (IBAction)tableViewDoubleAction:(id)sender;

@end
