//
// QSense.m
// QSqSense
//
// Created by Alcor on 11/22/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSense.h"

#define MIN_ABBR_OPTIMIZE 0
#define IGNORED_SCORE 0.9
#define SKIPPED_SCORE 0.15



float QSScoreForAbbreviationWithRanges(CFStringRef str, CFStringRef abbr, id mask, CFRange strRange, CFRange abbrRange);

float QSScoreForAbbreviation(CFStringRef str, CFStringRef abbr, id mask) {
	return QSScoreForAbbreviationWithRanges(str, abbr, mask, CFRangeMake(0, CFStringGetLength(str) ), CFRangeMake(0, CFStringGetLength(abbr)));
}

#ifdef _DDEBUG
// XCode and GDB were having problems keeping the display code in sync.
// So moved the problem piece to its own function.  Looks like NSMakeRange
// uses NS_INLINE, which is causing the problem.
// :pkohut:20091204 

void AddIndexesInRange(id mask, CFRange * matchedRange)
{
	[mask addIndexesInRange:NSMakeRange(matchedRange->location, matchedRange->length)];
}
#endif

float QSScoreForAbbreviationWithRanges(CFStringRef str, CFStringRef abbr, id mask, CFRange strRange, CFRange abbrRange) {
	float score, remainingScore;
	int i, j;
	CFRange matchedRange, remainingStrRange, adjustedStrRange = strRange;
    
	if (!abbrRange.length)
        return IGNORED_SCORE; //deduct some points for all remaining letters
    
	if (abbrRange.length > strRange.length)
        return 0.0;
	
	// Create an inline buffer version of str.  Will be used in loop below
	// for faster lookups.
	CFStringInlineBuffer inlineBuffer;
	CFStringInitInlineBuffer(str, &inlineBuffer, strRange);
	
	for (i = abbrRange.length; i > 0; i--) { //Search for steadily smaller portions of the abbreviation
		CFStringRef curAbbr = CFStringCreateWithSubstring (NULL, abbr, CFRangeMake(abbrRange.location, i) );
		//terminality
		//axeen
        CFLocaleRef userLoc = CFLocaleCopyCurrent();
		BOOL found = CFStringFindWithOptionsAndLocale(str, curAbbr,
                                                      CFRangeMake(adjustedStrRange.location, adjustedStrRange.length - abbrRange.length + i),
                                                      kCFCompareCaseInsensitive | kCFCompareDiacriticInsensitive | kCFCompareLocalized,
                                                      userLoc, &matchedRange);
		CFRelease(curAbbr);
        CFRelease(userLoc);
		
		if (!found) {
			continue;
		}
		
		if (mask) {
#ifdef _DDEBUG
			// See AddIndexesInRange note above!
			AddIndexesInRange(mask, &matchedRange);
#else
			[mask addIndexesInRange:NSMakeRange(matchedRange.location, matchedRange.length)];
#endif
		}
		
		remainingStrRange.location = matchedRange.location + matchedRange.length;
		remainingStrRange.length = strRange.location + strRange.length - remainingStrRange.location;
		
		// Search what is left of the string with the rest of the abbreviation
		remainingScore = QSScoreForAbbreviationWithRanges(str, abbr, mask, remainingStrRange, CFRangeMake(abbrRange.location + i, abbrRange.length - i) );
		
		if (remainingScore) {
			score = remainingStrRange.location-strRange.location;
			// ignore skipped characters if is first letter of a word
			if (matchedRange.location>strRange.location) {//if some letters were skipped
				static CFCharacterSetRef whitespace = NULL;
				if (!whitespace) whitespace = CFCharacterSetGetPredefined(kCFCharacterSetWhitespace);
				static CFCharacterSetRef uppercase = NULL;
				if (!uppercase) uppercase = CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter);
				j = 0;
				if (CFCharacterSetIsCharacterMember(whitespace, CFStringGetCharacterFromInlineBuffer(&inlineBuffer, matchedRange.location-1) )) {
					for (j = matchedRange.location-2; j >= (int) strRange.location; j--) {
						if (CFCharacterSetIsCharacterMember(whitespace, CFStringGetCharacterFromInlineBuffer(&inlineBuffer, j) )) score--;
						else score -= SKIPPED_SCORE;
					}
				} else if (CFCharacterSetIsCharacterMember(uppercase, CFStringGetCharacterFromInlineBuffer(&inlineBuffer, matchedRange.location) )) {
					for (j = matchedRange.location-1; j >= (int) strRange.location; j--) {
						if (CFCharacterSetIsCharacterMember(uppercase, CFStringGetCharacterFromInlineBuffer(&inlineBuffer, j) ))
							score--;
						else
							score -= SKIPPED_SCORE;
					}
				} else {
					score -= matchedRange.location-strRange.location;
				}
			}
			score += remainingScore*remainingStrRange.length;
			score /= strRange.length;
			return score;
		}
	}
	return 0;
}
