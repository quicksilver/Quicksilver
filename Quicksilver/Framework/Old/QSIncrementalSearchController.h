//
//  QSIncrementalSearchController.h
//  Quicksilver
//
//  Created by Alcor on 3/19/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum QSSearchMode {
    SearchFilterAll = 1,
    SearchFilter = 2,
    SearchSnap = 3,
    SearchShuffle = 4,
} QSSearchMode;

@interface QSIncrementalSearchController : NSObject {
	NSArray *searchArray; // The currently searched array, when nil, searches catalog.
  
	NSTimer *resetTimer; // Timer to reset partial string after a delay
    NSTimer *searchTimer; // Timer to delay search until more characters are recieved
	
    NSMutableString *partialString; // String to search
	NSString *searchString;
    NSString *resultsMatchedString;  // String that yeilded the current results
	NSMutableArray *resultArray; // Current results
	
    NSTimeInterval lastTime;
    NSTimeInterval lastProc;
    BOOL shouldResetSearchString; //next characters should be treated as a new search
   // BOOL shouldResetSearchArray;
	
	BOOL waitForMore;   // Search will recieve more characters, prevents search perform until lifted
	BOOL searchIsValid; // Current search string yielded valid results
	BOOL searchPending; // A search will be performed
	BOOL resultsValid;  // Results represent the current or pending search string
	
	float searchDelay;
	float resetDelay;
	
	QSSearchMode searchMode;
}
- (void)insertText:(NSString *)text;
- (void)clearSearch;
@end
