//
//  QSIncrementalSearchController.m
//  Quicksilver
//
//  Created by Alcor on 3/19/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import "QSIncrementalSearchController.h"
#import "QSPreferenceKeys.h"

#import "QSFoundation.h"

#import "QSCore.h"

#import "QSLibrarian.h"

#define defaults [NSUserDefaults standardUserDefaults]
@implementation QSIncrementalSearchController

- (id)init{
	if (self=[super init]){
		searchDelay=[defaults floatForKey:kSearchDelay];
		resetDelay=[defaults floatForKey:kResetDelay];
		partialString=[[NSMutableString alloc]init];
	} return self;
}
- (void)insertText:(NSString *)aString{
	aString=[[aString purifiedString]lowercaseString];
	//if (![partialString length])[self updateHistory];
	[partialString appendString:aString];
	[self partialStringChanged];
}

- (void)clearSearch{
	[resetTimer invalidate];
//	[self resetString];
	[partialString setString:@""];
	[self setResultsMatchedString:nil];
	[self setShouldResetSearchString:YES];
}


- (void)reset{
	//if (VERBOSE) QSLog(@"resetting: %f",delay);
	[partialString setString:@""];
	searchIsValid=YES;
	if([self searchMode]==SearchFilterAll){     
		[self setSearchArray:nil];
	}
	[self setShouldResetSearchString:NO];
}









- (void)setSearchTimerFor:(NSTimeInterval)delay{
	if ([searchTimer isValid]){
		[searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
	}else{
		[searchTimer release];
		searchTimer = [[NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(runSearch:) userInfo:nil repeats:NO]retain];
	}
}

- (void)setResetTimerFor:(NSTimeInterval)delay{
	return;
	if ([resetTimer isValid]){
		[resetTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
	}else{
		[resetTimer release];
		resetTimer = [[NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(resetString) userInfo:nil repeats:NO]retain];
	}
}

- (void)partialStringChanged{
	[self setSearchString:[[partialString copy]autorelease]];
	
	float searchDelay=nil;
	//if (fALPHA)
	//	searchDelay*=[[QSLibrarian sharedInstance] estimatedTimeForSearchInSet:searchArray]*0.9;
	//else
	
	//if (0 && moreComing){
	//		if ([searchTimer isValid]) [searchTimer invalidate];
	//	}else{
	
	[self setSearchTimerFor:searchDelay];

#warning if ([self searchMode]!=SearchFilterAll) [searchTimer fire];
	
	//}

#warning	[self setVisibleString:[partialString uppercaseString]];

	if (resetDelay){
		[self setResetTimerFor:resetDelay];
	}
}


- (QSSearchMode)searchMode { return searchMode; }
- (void)setSearchMode:(QSSearchMode)newSearchMode {
	searchMode = newSearchMode;
//	[resultController->resultTable setNeedsDisplay:YES];
//	if (browsing)
//		[defaults setInteger:newSearchMode forKey:kBrowseMode];
}



- (void)runSearchNow{
	[self runSearch:self];	
}

- (void)runSearch:(NSTimer *)timer{
	//QSLog(@"perform search, %d",self);    
	if (searchIsValid){
		//[resultController->searchStringField setTextColor:[NSColor blackColor]];
		//[resultController->searchStringField display];
		[self performSearchFor:partialString from:timer];
		//[resultController->searchStringField display];
	}
	//  QSLog(@"search performed");
}


- (void)performSearchFor:(NSString *)string from:(id)sender{
	NSDate *date=[NSDate date];
	NSMutableArray *newResultArray=[QSLib scoredArrayForString:string inSet:searchArray];
	
#warning if ([newResultArray count]>10)[newResultArray insertObject:[QSSeparatorObject separatorWithName:@"Other Matches"] atIndex:10];

	//if (DEBUG_RANKING)
	QSLog(@"Searched for \"%@\" in %3fms (%d items)",string,1000 * -[date timeIntervalSinceNow],[newResultArray count]);
	// QSLog (@"search for %@", string);
	//QSLog(@"%d valid",validSearch);
	if (searchIsValid=[newResultArray count]>0){
		[self setResultsMatchedString:string];
#warning validMnemonic=YES;
//		if ([self searchMode]==SearchFilterAll || [self searchMode]==SearchFilter)
			[self setResultArray:newResultArray];
//		if ([self searchMode]==SearchFilterAll){
//			[self setSearchArray:newResultArray];
	//		[parentStack removeAllObjects];
		}
		
//		if ([self searchMode]==SearchSnap){
//			[self selectObject:[newResultArray objectAtIndex:0]];
//			[self reloadResultTable];
//		}else{
//			[self selectIndex:0];
//		}
#warning show results
	//	int resultBehavior=[defaults integerForKey:kResultWindowBehavior];
//		
//		if ([resultArray count]>1){
//			if (resultBehavior==0)
//				[self showResultView:self];
//			else if (resultBehavior==1){
//				
//				if ([resultTimer isValid]){
//					[resultTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[defaults floatForKey:kResetDelay]]];
//				}else{
//					[resultTimer release];
//					resultTimer = [[NSTimer scheduledTimerWithTimeInterval:[defaults floatForKey:kResetDelay] target:self selector:@selector(showResultView:) userInfo:nil repeats:NO]retain];
//				}
//			}
//		}
//		
		
//}else{
//if ([defaults boolForKey:@"QSTransformBadSearchToText"])
//	[self transmogrifyWithText:partialString];
//else
//	NSBeep();
//
//[self setSearchIsValid:NO];
////		validMnemonic=NO;
////		[resultController->searchStringField setTextColor:[NSColor redColor]];
//}
	
	
	// Extend Timers
	if ([searchTimer isValid]){
		// QSLog(@"extend");
		[searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[defaults floatForKey:kSearchDelay]]];
		
	}
	
	
	if ([resetTimer isValid]){
		float resetDelay=[defaults floatForKey:kResetDelay];
		if (resetDelay) [resetTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:resetDelay]];
	}
	
}









- (NSMutableArray *)resultArray { return [[resultArray retain] autorelease]; }

- (void)setResultArray:(NSArray *)newResultArray {
	[resultArray autorelease];
	resultArray = [newResultArray retain];
}


- (NSArray *)searchArray { return [[searchArray retain] autorelease]; }

- (void)setSearchArray:(NSArray *)newSearchArray {
	[searchArray autorelease];
	searchArray = [newSearchArray retain];
}

- (BOOL)shouldResetSearchString { return shouldResetSearchString; }
- (void)setShouldResetSearchString:(BOOL)flag {
	shouldResetSearchString = flag;
}


- (NSString *)resultsMatchedString { return [[resultsMatchedString retain] autorelease]; }

- (void)setResultsMatchedString:(NSString *)newResultsMatchedString {
	[resultsMatchedString release];
	resultsMatchedString = [newResultsMatchedString copy];
}
- (NSString *)searchString {
    return [[searchString retain] autorelease]; 
}
- (void)setSearchString:(NSString *)newSearchString {
    if (searchString != newSearchString) {
        [searchString release];
        searchString = [newSearchString copy];
    }
}


@end
