//
//  NSString_CompletionExtensions.m
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSString_BLTRExtensions.h"
#import "NSArray_BLTRExtensions.h"
//#import "QSense.h"


NSComparisonResult prefixCompare(NSString *aString, NSString *bString) {
	int length = MIN([aString length] , [bString length]);
	if (!length) return NSOrderedSame;
	return [aString compare:bString options:NSCaseInsensitiveSearch range:NSMakeRange(0, MIN([aString length] , [bString length]) )];
}

@implementation NSString (Abbreviation)
- (float) scoreForString:(NSString *)testString {
	float score = 1;
	int i;
	// NSString *remainingString;
	NSString *characterString;
	NSRange currentRange = NSMakeRange(0, [testString length]);
	int index;
	for (i = 0; i<(int) [self length]; i++) {
		
		characterString = [self substringWithRange:NSMakeRange(i, 1)];
		
		index = [testString rangeOfString:characterString options:NSCaseInsensitiveSearch range:currentRange] .location;
		if (index == NSNotFound) return 0;
		score -= (float) (index-currentRange.location)/[testString length];
		currentRange.location = index+1;
		currentRange.length = [testString length] -index-1;
		// QSLog(@"Character at:%i", index);
	}
	score -= currentRange.length/[testString length];
	//QSLog(@"Score:%f", score*100);
	return score;
}


- (float) oldScoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask {
	return [self scoreForAbbreviation:abbreviation inRange:NSMakeRange(0, [self length]) fromRange:NSMakeRange(0, [abbreviation length]) hitMask:mask];
}
- (float) oldScoreForAbbreviation:(NSString *)abbreviation {
	return [self oldScoreForAbbreviation:abbreviation hitMask:nil];
}
- (float) scoreForAbbreviation:(NSString *)abbreviation {
	return [self scoreForAbbreviation:abbreviation hitMask:nil];
}
- (float) scoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask {
	
	//return QSScoreForAbbreviation((CFStringRef) self, (CFStringRef)abbreviation, mask);
				
	return [self scoreForAbbreviation:abbreviation inRange:NSMakeRange(0, [self length]) fromRange:NSMakeRange(0, [abbreviation length]) hitMask:mask];
}

- (float) scoreForAbbreviation:(NSString *)abbreviation inRange:(NSRange)searchRange fromRange:(NSRange)abbreviationRange hitMask:(NSMutableIndexSet *)mask {
	float score, remainingScore;
	int i, j;
	NSRange matchedRange, remainingSearchRange;
	if (!abbreviationRange.length) return 0.9; //deduct some points for all remaining letters
	if (abbreviationRange.length>searchRange.length) return 0.0;
	/*
	 {
		 matchedRange = [self rangeOfString:[abbreviation substringWithRange:NSMakeRange(abbreviationRange.location, 1)]
								  options:NSCaseInsensitiveSearch
									range:searchRange];
		 
		 if (matchedRange.location == NSNotFound) return 0.9;
		 searchRange.length -= matchedRange.location-searchRange.location;
		 searchRange.location = matchedRange.location;
	 }
	 */
	for (i = abbreviationRange.length; i>0; i--) { //Search for steadily smaller portions of the abbreviation
		matchedRange = [self rangeOfString:[abbreviation substringWithRange:NSMakeRange(abbreviationRange.location, i)]
								 options:NSCaseInsensitiveSearch
								   range:searchRange];
	
		if (matchedRange.location == NSNotFound) continue;
		if (matchedRange.location+abbreviationRange.length>NSMaxRange(searchRange) ) continue;
	
		if (mask) [mask addIndexesInRange:matchedRange];
		
		remainingSearchRange.location = NSMaxRange(matchedRange);
		remainingSearchRange.length = NSMaxRange(searchRange) -remainingSearchRange.location;
		
		// Search what is left of the string with the rest of the abbreviation
		remainingScore = [self scoreForAbbreviation:abbreviation
										  inRange:remainingSearchRange
										fromRange:NSMakeRange(abbreviationRange.location+i, abbreviationRange.length-i)
										  hitMask:mask];
		if (remainingScore) {
			score = remainingSearchRange.location-searchRange.location;
			// ignore skipped characters if is first letter of a word
			if (matchedRange.location>searchRange.location) {//if some letters were skipped
				j = 0;
				if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:matchedRange.location-1]]) {
					for (j = matchedRange.location-2; j >= (int) searchRange.location; j--) {
						if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:j]]) score--;
						else score -= 0.15;
					}
					
				} else if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[self characterAtIndex:matchedRange.location]]) {
					for (j = matchedRange.location-1; j >= (int) searchRange.location; j--) {
						if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[self characterAtIndex:j]])
							score--;
						else
							score -= 0.15;
					}
				} else {
					score -= matchedRange.location-searchRange.location;
				}
				
			}
			
			score += remainingScore*remainingSearchRange.length;
			score /= searchRange.length;
			return score;
		}
	}
	return 0;

}



- (NSArray *)hitsForString:(NSString *)testString {
	NSMutableArray *hitsArray = [NSMutableArray arrayWithCapacity:[self length]];
	int i;
	NSString *characterString;
	NSRange currentRange = NSMakeRange(0, [testString length]);
	int index;
	for (i = 0; i<(int) [self length]; i++) {
		characterString = [self substringWithRange:NSMakeRange(i, 1)];
		index = [testString rangeOfString:characterString options:NSCaseInsensitiveSearch range:currentRange] .location;
		if (index == NSNotFound) return hitsArray;
		[hitsArray addObject:[NSNumber numberWithInt:index]];
		currentRange.location = index+1;
		currentRange.length = [testString length] -index-1;
	}
	return hitsArray;
}

@end
