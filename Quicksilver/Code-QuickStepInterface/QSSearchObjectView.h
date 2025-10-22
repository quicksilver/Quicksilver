#import <Foundation/Foundation.h>
#import "QSObjectView.h"

#import <Quartz/Quartz.h>

@interface NSObject (QSSearchViewController)
- (void)searchView:(id)view changedResults:(id)array;
- (void)searchView:(id)view changedString:(id)string;
- (void)searchView:(id)view resultsVisible:(BOOL)visible;
@end

// These tags are set within Interface Builder, and are used to define the current search mode
typedef NS_ENUM(NSUInteger, QSSearchMode) {
	SearchFilterAll = 1, // Filter Catalog
	SearchFilter = 2, // Filter Results
	SearchSnap = 3, // Snap to Best
	SearchShuffle = 4, // Not Sure (not used?)
};

@class QSResultController;
@interface QSSearchObjectView : QSObjectView <NSTextInputClient, NSTextViewDelegate, NSTouchBarDelegate>
{
    // the text mode text editor object
    NSTextView *textModeEditor;
    
	NSMutableString *partialString;
	NSString 		*matchedString;
	NSString 		*visibleString;

	BOOL validSearch;

	NSTimer *resetTimer;
	NSTimer *searchTimer;
	NSTimer *resultTimer;

	NSTimeInterval lastTime;
	NSTimeInterval lastProc;

	CGFloat resultsPadding;
	NSRectEdge preferredEdge;
	NSRectEdge lastEdge;

	BOOL shouldResetSearchString;
	BOOL shouldResetSearchArray;
	BOOL showsResultsWhenSelected;

	id selectedObject;

	BOOL hFlip;
	BOOL vFlip;
	NSText *currentEditor;

	NSMutableArray *historyArray;
	NSInteger 			historyIndex;
	NSMutableArray *parentStack; // The parents for the current browse session
	NSMutableArray *childStack; // The children for the current browse session
    
    NSFont *textCellFont; // for text entry mode
    NSColor *textCellFontColor; // for text entry mode
    QLPreviewPanel* previewPanel;
    QSSearchMode savedSearchMode;
    
    // Indicates if extras (such as indirect objects) should be updated when the 'search object' is changed. Default is NO
    BOOL updatesSilently;
	
	// whether or not the string in the underlying text editor should be 'sniffed' when editing (see QSObject_StringHandling.m - sniffString for more info)
	BOOL shouldSniff;
	BOOL hasMarkedTextState; // tracks input method composition state
    QSAction *alternateActionCounterpart;

@public
	QSResultController *resultController;
	QSSearchMode searchMode;

	NSUInteger selection;
	BOOL browsing;
	BOOL validMnemonic;
	BOOL hasHistory;
	BOOL allowText;
	BOOL allowNonActions;
	
    QSObject *quicklookObject;

}

@property (copy) NSArray *sourceArray; // The original source array for searches
@property (copy) NSArray *searchArray; // Interim array for searching smaller and smaller pieces
@property (strong) NSMutableArray *resultArray; // Final filtered array for current search string

@property (assign) BOOL updatesSilently;
@property (assign) BOOL recordsHistory;
@property (strong) QSResultController *resultController;
@property (strong) QSAction *alternateActionCounterpart;
@property (strong) NSTextView *textModeEditor;

// returns the frame size for the text editor (when you enter text mode). Allows subclasses to override the size.
- (NSRect)textEditorFrame;

- (void)clearSearch; // reset everything and be ready for a new search
- (void)clearTextView; // reset the text view. Not to be confused with clearSearch - clear search is called every time a new object is presented into the SOV, whereas keeping the underlying text is important in these cases. clearTextView should only be used in `deleteBackwards` style situations

- (void)clearAll;

- (void)clearObjectValue;
- (void)moveSelectionBy:(NSInteger)d;
/**
 Resets the current state of the view, then populates the view with
 a single object. Overrides the method from the superclass.
 @param newObject the object to select
 **/
- (void)setObjectValue:(QSBasicObject *)newObject;
/**
 Set the currently selected object. If the object was not previously
 selected, posts a SearchObjectChanged notification.
 @param newObject the object to select
 **/
- (void)selectObjectValue:(id)newObject ;
/**
 Identical to selectObjectValue: in this class. See the interface for
 QSCollectingSearchObjectView, where this does something useful.
 @param newObject the object to select
 **/
- (void)redisplayObjectValue:(QSObject *)newObject;
/**
 Select whatever the proxy object refers to.
 **/
- (void)selectProxyObject;
- (void)pageScroll:(NSInteger)direction;

- (NSMutableArray *)resultArray;
- (void)setResultArray:(NSMutableArray *)newResultArray;

- (BOOL)shouldResetSearchString;
- (void)setShouldResetSearchString:(BOOL)flag;
- (BOOL)shouldResetSearchArray;
- (void)setShouldResetSearchArray:(BOOL)flag;
- (NSString *)matchedString; // the part of the search string that matches the object
- (void)setMatchedString:(NSString *)newMatchedString;

- (IBAction)toggleResultView:sender;
- (void)selectIndex:(NSInteger)index;
/**
 Select an object from the result array. If the object passed in
 doesn't exist in the results, nothing happens.
 @param obj the object to select
 **/
- (void)selectObject:(QSBasicObject *)obj;
- (void)objectIconModified:(NSNotification *)notif;
- (void)resetString; // update the string on screen when the search is cleared
- (IBAction)defineMnemonic:(id)sender;
- (IBAction)defineMnemonicImmediately:(id)sender;
- (void)saveMnemonic;
- (BOOL)mnemonicDefined;
- (BOOL)impliedMnemonicDefined;
- (IBAction)removeImpliedMnemonic:(id)sender;
- (IBAction)removeMnemonic:(id)sender;

- (IBAction)promoteAction:(id)sender;

- (void)rescoreSelectedItem;

- (IBAction)showResultView:(id)sender;

- (void)dropObject:(QSBasicObject *)newSelection;

- (IBAction)transmogrify:sender;

- (IBAction)sortByScore:(id)sender;
- (IBAction)sortByName:(id)sender;
- (void)reloadResultTable;
- (BOOL)executeText:(NSEvent *)theEvent;
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
- (QSSearchObjectView *)actionSelector;
- (QSSearchObjectView *)indirectSelector;

- (BOOL)allowText;
- (void)setAllowText:(BOOL)flag;
- (BOOL)allowNonActions;
- (void)setAllowNonActions:(BOOL)flag;

- (NSText *)currentEditor;
- (void)setCurrentEditor:(NSText *)aCurrentEditor;

- (void)setResultsPadding:(CGFloat)aResultsPadding;
- (void)insertSpace:(id)sender;

	//TextInputMethods
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange;
- (NSUInteger) characterIndexForPoint:(NSPoint)thePoint;
- (NSInteger) conversationIdentifier;
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
@end



@interface QSSearchObjectView (History)
/**
 Go forward in the history of used objects
 @param sender the calling object (unused)
 **/
- (void)goForward:(id)sender;
/**
 Go backward in the history of used objects
 @param sender the calling object (unused)
 **/
- (void)goBackward:(id)sender;
/**
 Add the currently selected object to the history of used objects.
 If the object is already present in the history, move it to the
 most recent position. Combined objects are kept in history as-is.
 
 This method also adds each selected object to the Recent Objects
 catalog entry. Combined objects are split and added individually.
 **/
- (void)updateHistory;
/**
 Empty the history of used objects.
 **/
- (void)clearHistory;
/**
 Searches through a QSCollectingSearchObjectView's collection for
 an object. Always returns NO in a plain QSSearchObjectView.
 @param thisObject the object to look for
 @returns YES if the object is in the collection. NO if not.
 **/
- (BOOL)objectIsInCollection:(QSObject *)thisObject;
/**
 Separate a combined object and put the components in the result
 array. Allows users to view and manage selections. Does nothing
 in a plain QSSearchObjectView.
 **/
- (void)explodeCombinedObject;
@end


@interface QSSearchObjectView (Browsing)
- (void)browse:(NSInteger)direction;
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
