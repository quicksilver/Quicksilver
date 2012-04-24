#import <Foundation/Foundation.h>
#import "QSObjectView.h"

#import <Quartz/Quartz.h>

@interface NSObject (QSSearchViewController)
- (void)searchView:(id)view changedResults:(id)array;
- (void)searchView:(id)view changedString:(id)string;
- (void)searchView:(id)view resultsVisible:(BOOL)visible;
@end

// These tags are set within Interface Builder, and are used to define the current search mode
typedef enum QSSearchMode {
	SearchFilterAll = 1, // Filter Catalog
	SearchFilter = 2, // Filter Results
	SearchSnap = 3, // Snap to Best
	SearchShuffle = 4, // Not Sure (not used?)
} QSSearchMode;

@class QSResultController;
@interface QSSearchObjectView : QSObjectView <NSTextInput
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
// NSTextViewDelegate for the NSTextView (the text mode view) as used in transmogrifyWithText:(NSString *)string
	, NSTextViewDelegate
#endif
> 
{   
	NSMutableString *partialString;
	NSString 		*matchedString;
	NSString 		*visibleString;

	BOOL validSearch;

    BOOL browsingHistory;

    
	NSTimer *resetTimer;
	NSTimer *searchTimer;
	NSTimer *resultTimer;

	NSTimeInterval lastTime;
	NSTimeInterval lastProc;

	float resultsPadding;
	NSRectEdge preferredEdge;
	NSRectEdge lastEdge;

	BOOL shouldResetSearchString;
	BOOL shouldResetSearchArray;
	BOOL showsResultsWhenSelected;

	id selectedObject;

	BOOL hFlip;
	BOOL vFlip;
	NSText *currentEditor;

	BOOL 			recordsHistory; //ACC
	NSMutableArray *historyArray;
	int 			historyIndex;
	NSMutableArray *parentStack; // The parents for the current browse session
	NSMutableArray *childStack; // The children for the current browse session
    
    NSFont *textCellFont; // for text entry mode
    NSColor *textCellFontColor; // for text entry mode
    QLPreviewPanel* previewPanel;
    QSSearchMode savedSearchMode;

@public
	QSResultController *resultController;
	QSSearchMode searchMode;

	NSMutableArray *sourceArray; // The original source array for searches
	NSMutableArray *searchArray; // Interim array for searching smaller and smaller pieces
	NSMutableArray *resultArray; // Final filtered array for current search string

	unsigned selection;
	BOOL browsing;
	BOOL validMnemonic;
	BOOL hasHistory;
	BOOL allowText;
	BOOL allowNonActions;
    
    QSObject *quicklookObject;
}

- (void)clearSearch;

- (void)clearObjectValue;
- (void)moveSelectionBy:(int)d;
- (void)selectObjectValue:( QSObject *)newObject ;
- (void)pageScroll:(int)direction;

- (NSMutableArray *)sourceArray;
- (void)setSourceArray:(NSMutableArray *)newSourceArray;
- (NSMutableArray *)searchArray;
- (void)setSearchArray:(NSMutableArray *)newSearchArray;
- (NSMutableArray *)resultArray;
- (void)setResultArray:(NSMutableArray *)newResultArray;

- (BOOL)shouldResetSearchString;
- (void)setShouldResetSearchString:(BOOL)flag;
- (BOOL)shouldResetSearchArray;
- (void)setShouldResetSearchArray:(BOOL)flag;
- (NSString *)matchedString;
- (void)setMatchedString:(NSString *)newMatchedString;

- (IBAction)toggleResultView:sender;
- (void)selectIndex:(int)index;
- (void)selectObject:(QSBasicObject *)obj;
- (void)resetString;
- (IBAction)defineMnemonic:(id)sender;
- (void)saveMnemonic;
- (BOOL)mnemonicDefined;
- (BOOL)impliedMnemonicDefined;
- (IBAction)removeImpliedMnemonic:(id)sender;

- (IBAction)removeMnemonic:(id)sender;
- (void)rescoreSelectedItem;

- (IBAction)showResultView:sender;

- (void)dropObject:(QSBasicObject *)newSelection;

- (IBAction)transmogrify:sender;

- (IBAction)sortByScore:(id)sender;
- (IBAction)sortByName:(id)sender;
- (void)reloadResultTable;
- (BOOL)executeText:(NSEvent *)theEvent;
- (void)selectIndex:(int)index;
- (void)performSearchFor:(NSString *)string from:(id)sender;
- (IBAction)hideResultView:sender;
- (BOOL)handleBoundKey:(NSEvent *)theEvent;
- (IBAction)updateResultView:sender;

- (void)partialStringChanged;
- (void)reset:(id)sender;
- (NSRectEdge) preferredEdge;
- (void)setPreferredEdge:(NSRectEdge)newPreferredEdge;
- (QSSearchMode) searchMode;
- (void)setSearchMode:(QSSearchMode)newSearchMode;

- (id)selectedObject;
- (void)setSelectedObject:(id)newSelectedObject;


- (QSSearchObjectView *)directSelector;
- (QSSearchObjectView *)indirectSelector;
- (QSSearchObjectView *)indirectSelector;

- (BOOL)allowText;
- (void)setAllowText:(BOOL)flag;
- (BOOL)allowNonActions;
- (void)setAllowNonActions:(BOOL)flag;

- (NSText *)currentEditor;
- (void)setCurrentEditor:(NSText *)aCurrentEditor;

- (void)setResultsPadding:(float)aResultsPadding;
- (NSString *)stringForEvent:(NSEvent *)theEvent;
- (void)insertSpace:(id)sender;

	//TextInputMethods
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange;
- (unsigned int) characterIndexForPoint:(NSPoint)thePoint;
- (long) conversationIdentifier;
- (NSRect) firstRectForCharacterRange:(NSRange)theRange;
- (BOOL)hasMarkedText;
- (NSRange) markedRange;
- (NSRange) selectedRange;
- (void)setMarkedText:(id)aString selectedRange:(NSRange)selRange;
- (void)unmarkText;
- (NSArray *)validAttributesForMarkedText;
- (void)setTextCellFont:(NSFont *)newCellFont;
- (void)setTextCellFontColor:(NSColor *)newCellColor;

- (void)setVisibleString:(NSString *)string;
- (NSString *)visibleString;
- (void)setVisibleString:(NSString *)newVisibleString;

/*!
 @handleChangeSearchModeEvent
 @abstract Checks for the  ⌘→ or ⌘← keys to change search mode
 @discussion If a search mode switching keyboard shortcut is pressed, this method changes the search mode,
 depending on the direction keys (forwards or backwards)
 @result YES if ⌘→ or ⌘← is pressed and the search mode changed, otherwise NO
 */
- (BOOL)handleChangeSearchModeEvent:(NSEvent *)theEvent;
- (BOOL)handleShiftedKeyEvent:(NSEvent *)theEvent;
- (BOOL)handleSlashEvent:(NSEvent *)theEvent;
- (BOOL)handleTildeEvent:(NSEvent *)theEvent;
- (BOOL)handleRepeaterEvent:(NSEvent *)theEvent;

- (void)updateObject:(QSObject *)object;
@end



@interface QSSearchObjectView (History)
- (void)goForward:(id)sender;
- (void)goBackward:(id)sender;
- (void)updateHistory;
- (void)clearHistory;
- (BOOL)objectIsInCollection:(QSObject *)thisObject;
@end


@interface QSSearchObjectView (Browsing)
- (void)browse:(int)direction;
@end

@interface QSSearchObjectView (Quicklook) <QLPreviewPanelDataSource, QLPreviewPanelDelegate>
/*!
 @canQuicklookCurrentObject
 @abstract Checks an object's eligibility for Quick Looking
 @discussion returns whether the currently selected object can by shown in the Quicklook panel
 @result YES if the object is a file or URL object, otherwise NO
 */
- (BOOL)canQuicklookCurrentObject;
/*!
 @closePreviewPanel
 @abstract Method to close the preview panel
 @discussion Closes the preview panel, returning Quicksilver to the state it was in before the panel was open
 */
- (void)closePreviewPanel;
- (IBAction)togglePreviewPanel:(id)previewPanel;
- (IBAction)togglePreviewPanelFullScreen:(id)previewPanel;
@end
