//
//  NSString_CompletionExtensions.h
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSComparisonResult prefixCompare(NSString *aString, NSString *bString);

@interface NSString (Abbreviation)
- (float) scoreForString:(NSString *)string;
- (NSArray *) hitsForString:(NSString *)testString;
- (float) scoreForAbbreviation:(NSString *)abbreviation;
- (float) oldScoreForAbbreviation:(NSString *)abbreviation;
- (float) scoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask;
- (float) oldScoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask;
- (float) scoreForAbbreviation:(NSString *)abbreviation inRange:(NSRange)searchRange fromRange:(NSRange)abbreviationRange hitMask:(NSMutableIndexSet *)mask;
@end
