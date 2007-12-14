//
//  QSSearchController.h
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 6/25/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

//typedef enum QSSearchMode {
//  SearchFilterAll = 1,
//  SearchFilter = 2,
//  SearchSnap = 3,
//  SearchShuffle = 4,
//} QSSearchMode;
//

@class QSResultController, QSCatalogSearchProvider, QSSpotlightSearchProvider;
@interface QSSearchController : NSObjectController {
  QSBasicObject *objectValue;
  IBOutlet NSSearchField *searchField;
  IBOutlet NSTableView *tableView;
  QSCatalogSearchProvider *qsSearch;
  QSSpotlightSearchProvider *spotSearch;
  
  NSString *searchText;
  NSString *searchType; // nil, Spot, GD, etc...
  NSArray *resultArray;
  NSArray *sourceArray;
  IBOutlet NSArrayController *resultArrayController;
	  //----------
  
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
	
	
	
  
  QSResultController *resultController;
  QSSearchMode searchMode;
	
//	NSMutableArray *sourceArray; // The original source array for searches
//  NSMutableArray *searchArray; // Interim array for searching smaller and smaller pieces
//  NSMutableArray *resultArray; // Final filtered array for current search string
//	
  NSData *scoreData;
  unsigned selection;
  BOOL browsing;
	BOOL validMnemonic;
  BOOL hasHistory;
  BOOL moreComing;
  BOOL allowText;
  BOOL allowNonActions;
  

}
@property(copy) NSString *searchText;
@property(copy) NSString *matchedString;
@property(retain) NSString *searchType;
@property(retain) NSArray *resultArray;
@property(retain) NSArray *sourceArray;
@property(retain) QSBasicObject *objectValue;


- (IBAction)selectSearchType:(id)sender;

  
  
  
- (void)clearSearch;

- (void)clearObjectValue;
- (void)moveSelectionBy:(int)d;
- (void)selectObjectValue:( QSObject *)newObject ;
- (void)pageScroll:(int)direction;

//- (NSMutableArray *)sourceArray;
//- (void)setSourceArray:(NSMutableArray *)newSourceArray;
//- (NSArray *)searchArray;
//- (void)setSearchArray:(NSArray *)newSearchArray;
//- (NSMutableArray *)resultArray;
//- (void)setResultArray:(NSMutableArray *)newResultArray;

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



@interface QSSearchController (History)
- (void)goForward:(id)sender;
- (void)goBackward:(id)sender;
- (void)updateHistory;
- (void)clearHistory;
- (BOOL)objectIsInCollection:(QSObject *)thisObject;
@end


@interface QSSearchController (Browsing)
- (void)browse:(int)direction;
@end
