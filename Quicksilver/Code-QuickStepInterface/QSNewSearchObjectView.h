#import <Foundation/Foundation.h>
#import "QSObjectView.h"

#import "QSIncrementalSearchController.h"

@interface NSObject (QSSearchViewController)
- (void)searchView:(id)view changedResults:(id)array;
- (void)searchView:(id)view changedString:(id)string;
- (void)searchView:(id)view resultsVisible:(BOOL)visible;
@end



@class QSResultController;
@class QSCollection;

@interface QSSearchObjectView : QSObjectView <NSTextInput> {
	QSIncrementalSearchController *sController;
	NSArrayController *rController;
	NSMutableArray *results;
	QSResultController *resultController;
    NSString *matchedString;
	
    BOOL allowText;
    BOOL allowNonActions;
	
	
	float resultsPadding;
    NSRectEdge preferredEdge;
    NSRectEdge lastEdge;
	
	NSText *currentEditor;
}
@end



@interface QSOldSearchObjectView : QSObjectView <NSTextInput> {
	QSIncrementalSearchController *sController;
	NSMutableArray *results;
	NSArrayController *rController;
	
	
	id selectedObject;
	
    NSMutableArray *parentStack;
	NSMutableArray *history;
    NSMutableArray *future;
	
	NSTimeInterval lastTime;
    NSTimeInterval lastProc;
	NSString *partialString;
    BOOL validSearch;
    

    NSTimer *resultTimer;
    

	
    NSRectEdge preferredEdge;
    NSRectEdge lastEdge;
    

    BOOL showsResultsWhenSelected;
    
    
    NSUserDefaults *defaults;
	id editor;
	
	BOOL hFlip;
	BOOL vFlip;
	NSText *currentEditor;
	@public
	QSResultController *resultController;
    QSSearchMode searchMode;

    NSData *scoreData;
    unsigned selection;
    BOOL browsing;
    BOOL validMnemonic;
    BOOL hasHistory;
    BOOL moreComing;
    BOOL allowText;
    BOOL allowNonActions;
}


//- (void)updateHistory;
//-(void)clearSearch;
//
//- (void)clearObjectValue;
//- (void)moveSelectionBy:(int)d;
//- (BOOL)objectIsInCollection:(QSObject *)thisObject;
//- (void)pageScroll:(int)direction;
//- (NSArray *)searchArray;
//- (void)setSearchArray:(NSArray *)newSearchArray;
//- (NSMutableArray *)resultArray;
//- (void)setResultArray:(NSMutableArray *)newResultArray;
//- (BOOL)shouldResetSearchString;
//- (void)setShouldResetSearchString:(BOOL)flag;
//- (BOOL)shouldResetSearchArray;
//- (void)setShouldResetSearchArray:(BOOL)flag;
//- (NSString *)matchedString;
//- (void)setMatchedString:(NSString *)newMatchedString;
//- (NSData *)scoreData;
//- (void)setScoreData:(NSData *)newScoreData;
//
//- (IBAction) toggleResultView:sender;
//- (void)selectIndex:(int)index;
//- (void)selectObject:(QSBasicObject *)obj;
//- (void)resetString;
//- (IBAction)defineMnemonic:(id)sender;
//- (void)saveMnemonic;
//- (BOOL)mnemonicDefined;
//- (BOOL)impliedMnemonicDefined;
//- (IBAction)removeImpliedMnemonic:(id)sender;
//
//- (IBAction)removeMnemonic:(id)sender;
//- (void)rescoreSelectedItem;
//- (void)browse:(int)direction;
//
//- (IBAction) showResultView:sender;
//
//- (void) dropObject:(QSBasicObject *)newSelection;
//
//- (IBAction) transmogrify:sender;
//
//- (IBAction)sortByScore:(id)sender;
//- (IBAction)sortByName:(id)sender;
//- (void)reloadResultTable;
//- (BOOL)executeText:(NSEvent *)theEvent;
//- (void)selectIndex:(int)index;
//- (void)performSearchFor:(NSString *)string from:(id)sender;
//- (IBAction) hideResultView:sender;
//- (BOOL)handleBoundKey:(NSEvent *)theEvent;
//- (IBAction) updateResultView:sender;
//
//- (void)partialStringChanged;
//- (void)reset:(id)sender;
//- (NSRectEdge)preferredEdge;
//- (void)setPreferredEdge:(NSRectEdge)newPreferredEdge;
//- (QSSearchMode)searchMode;
//- (void)setSearchMode:(QSSearchMode)newSearchMode;
//
//- (id)selectedObject;
//- (void)setSelectedObject:(id)newSelectedObject;
//
//
//- (QSOldSearchObjectView *)directSelector;
//- (QSOldSearchObjectView *)indirectSelector;
//
//- (QSOldSearchObjectView *)directSelector;
//- (QSOldSearchObjectView *)actionSelector;
//- (QSOldSearchObjectView *)indirectSelector;
//- (BOOL)allowText;
//- (void)setAllowText:(BOOL)flag;
//- (BOOL)allowNonActions;
//- (void)setAllowNonActions:(BOOL)flag;
//
//- (NSText *)currentEditor;
//- (void)setCurrentEditor:(NSText *)aCurrentEditor;
//
//- (void)setResultsPadding:(float)aResultsPadding;
//- (NSString *)stringForEvent:(NSEvent *)theEvent;
//
//	//TextInputMethods
//- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange;
//- (unsigned int)characterIndexForPoint:(NSPoint)thePoint;
//- (long)conversationIdentifier;
//- (NSRect)firstRectForCharacterRange:(NSRange)theRange;
//- (BOOL)hasMarkedText;
//- (NSRange)markedRange;
//- (NSRange)selectedRange;
//- (void)setMarkedText:(id)aString selectedRange:(NSRange)selRange;
//- (void)unmarkText;
//- (NSArray *)validAttributesForMarkedText;
//
//- (void)setVisibleString:(NSString *)string;
//-(IBAction) emptyCollection:(id)sender;
@end



@interface QSCollectingSearchObjectView : QSOldSearchObjectView{
	NSMutableArray *collection;
	BOOL collecting;
}
@end
