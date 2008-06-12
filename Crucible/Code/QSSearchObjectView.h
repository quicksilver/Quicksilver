#import <Foundation/Foundation.h>
#import "QSObjectView.h"

@interface NSObject (QSSearchViewController)
- (void)searchView:(id)view changedResults:(id)array;
- (void)searchView:(id)view changedString:(id)string;
- (void)searchView:(id)view resultsVisible:(BOOL)visible;
@end

typedef enum QSSearchMode {
    SearchFilterAll = 1,
    SearchFilter = 2,
    SearchSnap = 3,
    SearchShuffle = 4,
} QSSearchMode;


@class QSResultController;
@interface QSSearchObjectView : QSObjectView <NSTextInput> {
	NSArrayController *resultArrayController;
	
    NSMutableString *partialString;
    NSString 		*matchedString;
	NSString 		*visibleString;
	
    BOOL validSearch;
    
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
    
    NSUserDefaults *defaults;
	id editor;
	
	BOOL hFlip;
	BOOL vFlip;
	NSText *currentEditor;
	
	BOOL 			recordsHistory; //ACC 
	NSMutableArray *historyArray;
	int 			historyIndex;
	NSMutableArray *parentStack; // The parents for the current browse session
	NSMutableArray *childStack; // The children for the current browse session
	
@public
    
    QSResultController *resultController;
    QSSearchMode searchMode;
	
	NSMutableArray *sourceArray; // The original source array for searches
    NSMutableArray *searchArray; // Interim array for searching smaller and smaller pieces
    NSMutableArray *resultArray; // Final filtered array for current search string
	
    NSData *scoreData;
    unsigned selection;
    BOOL browsing;
	BOOL validMnemonic;
    BOOL hasHistory;
    BOOL moreComing;
    BOOL allowText;
    BOOL allowNonActions;
}

- (void)clearSearch;

- (void)clearObjectValue;
- (void)moveSelectionBy:(int)d;
- (void)selectObjectValue:( QSObject *)newObject ;
- (void)pageScroll:(int)direction;

- (NSArray *)sourceArray;
- (void)setSourceArray:(NSArray *)newSourceArray;
- (NSArray *)searchArray;
- (void)setSearchArray:(NSArray *)newSearchArray;
- (NSArray *)resultArray;
- (void)setResultArray:(NSArray *)newResultArray;

- (BOOL)shouldResetSearchString;
- (void)setShouldResetSearchString:(BOOL)flag;
- (BOOL)shouldResetSearchArray;
- (void)setShouldResetSearchArray:(BOOL)flag;
- (NSString *)matchedString;
- (void)setMatchedString:(NSString *)newMatchedString;
- (NSData *)scoreData;
- (void)setScoreData:(NSData *)newScoreData;

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

- (QSSearchObjectView *)directSelector;
- (QSSearchObjectView *)actionSelector;
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

- (void)setVisibleString:(NSString *)string;
- (NSString *)visibleString;
- (void)setVisibleString:(NSString *)newVisibleString;

- (BOOL)handleShiftedKeyEvent:(NSEvent *)theEvent;
- (BOOL)handleSlashEvent:(NSEvent *)theEvent;
- (BOOL)handleTildeEvent:(NSEvent *)theEvent;
- (BOOL)handleRepeaterEvent:(NSEvent *)theEvent;
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
