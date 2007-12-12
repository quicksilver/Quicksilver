//
//  QSCatalogSearchProvider.m
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 6/25/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import "QSCatalogSearchProvider.h"


@implementation QSCatalogSearchProvider






- (void)performSearchFor:(NSString *)string from:(id)sender {

  if (!searchString || ![string hasPrefix:searchString]) self.searchArray = sourceArray;
  NSLog(@"search for %@ %@ in %d", string, searchString, [searchArray count]);
  NSMutableArray *newResultArray = [[QSLibrarian sharedInstance] scoredArrayForString:string inSet:searchArray];
  self.searchString = string;
  self.resultArray = newResultArray;
  self.searchArray = newResultArray;
}
//  
//  
//	if (validSearch = [newResultArray count] >0) {
//		[self setMatchedString:string];
//		//        [self setScoreData:scores];
//		validMnemonic = YES;
//		if ([self searchMode] == SearchFilterAll || [self searchMode] == SearchFilter)
//			[self setResultArray:newResultArray];
//		if ([self searchMode] == SearchFilterAll) {
//			[self setSearchArray:newResultArray];
//			[parentStack removeAllObjects];
//		}
//		
//		if ([self searchMode] == SearchSnap) {
//			[self selectObject:[newResultArray objectAtIndex:0]];
//			
//      [self reloadResultTable];
//		} else if (0) { //if should retain the selection
//      // [self selectObject:[newResultArray objectAtIndex:0]];
//		} else {
//			[self selectIndex:0];
//		}
//		
//		int resultBehavior = [defaults integerForKey:kResultWindowBehavior];
//		
//		if ([resultArray count] >1) {
//			if (resultBehavior == 0)
//				[self showResultView:self];
//			else if (resultBehavior == 1) {
//				
//				if ([resultTimer isValid]) {
//					[resultTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[defaults floatForKey:kResetDelay]]];
//				} else {
//					[resultTimer release];
//					resultTimer = [[NSTimer scheduledTimerWithTimeInterval:[defaults floatForKey:kResetDelay] target:self selector:@selector(showResultView:) userInfo:nil repeats:NO] retain];
//				}
//			}
//		}
//		
//		
//	} 
//	
//
//}


@synthesize resultArray;
@synthesize sourceArray;
@synthesize matchedString;
@synthesize searchArray;
@synthesize searchString;
@end
