//
// QSense.m
// QSqSense
//
// Created by Alcor on 11/22/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSSense.h"

#define MIN_ABBR_OPTIMIZE 0
#define IGNORED_SCORE 0.9
#define SKIPPED_SCORE 0.2



CGFloat QSScoreForAbbreviationWithRanges(CFStringRef str, CFStringRef abbr, id mask, CFRange strRange, CFRange abbrRange);

CGFloat QSScoreForAbbreviation(CFStringRef str, CFStringRef abbr, id mask) {
	return QSScoreForAbbreviationOrTransliteration(str, abbr, mask);
}

CGFloat QSScoreForAbbreviationOrTransliteration(CFStringRef str, CFStringRef abbr, id mask) {
	CGFloat score = QSScoreForAbbreviationWithRanges(str, abbr, mask, CFRangeMake(0, CFStringGetLength(str)), CFRangeMake(0, CFStringGetLength(abbr)));
	if (score == 0) {
		CFMutableStringRef mutableString = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, str);
		CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false);
		
		if (CFStringCompare(str, mutableString, 0) != kCFCompareEqualTo) {
			// only do this if the two strings are not equal (otherwise it's a wasted compute)
			score = QSScoreForAbbreviationWithRanges(mutableString, abbr, nil, CFRangeMake(0, CFStringGetLength(mutableString)), CFRangeMake(0, CFStringGetLength(abbr)));
		}
		if (mutableString) {
			CFRelease(mutableString);
		}
		// log the string and score
		if (score > 0) {
			NSLog(@"%@ -> %@ = %f", str, abbr, score);
		}
		return score;
	}
	if (score > 0) {
		NSLog(@"%@ -> %@ = %f", str, abbr, score);
	}
	return score;
}

CGFloat QSScoreForAbbreviationWithRanges(CFStringRef str, CFStringRef abbr, id mask, CFRange strRange, CFRange abbrRange) {
	if (!abbrRange.length)
		return IGNORED_SCORE; //deduct some points for all remaining letters

	if (abbrRange.length > strRange.length)
		return 0.0;

	static CFCharacterSetRef wordSeparator = NULL;
	static CFCharacterSetRef uppercase = NULL;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		wordSeparator = CFCharacterSetCreateMutableCopy(NULL, CFCharacterSetGetPredefined(kCFCharacterSetWhitespace));
		CFCharacterSetAddCharactersInString((CFMutableCharacterSetRef)wordSeparator, (CFStringRef)@".");

		uppercase = CFCharacterSetGetPredefined(kCFCharacterSetUppercaseLetter);
	});

	// Create an inline buffer version of str.  Will be used in loop below
	// for faster lookups.
	CFStringInlineBuffer inlineBuffer;
	CFStringInitInlineBuffer(str, &inlineBuffer, CFRangeMake(0, CFStringGetLength(str)));
	CFLocaleRef userLoc = CFLocaleCopyCurrent();

	CGFloat score = 0.0, remainingScore = 0.0;
	CFIndex i, j;
	CFRange matchedRange, remainingStrRange, adjustedStrRange = strRange;

	// Search for steadily smaller portions of the abbreviation
	for (i = abbrRange.length; i > 0; i--) {
		CFStringRef curAbbr = CFStringCreateWithSubstring (NULL, abbr, CFRangeMake(abbrRange.location, i) );
		// terminality
		// axeen

		BOOL found = CFStringFindWithOptionsAndLocale(str, curAbbr,
													  CFRangeMake(adjustedStrRange.location, adjustedStrRange.length - abbrRange.length + i),
													  kCFCompareCaseInsensitive | kCFCompareDiacriticInsensitive | kCFCompareLocalized,
													  userLoc, &matchedRange);
		CFRelease(curAbbr);

		if (!found) {
			continue;
		}

		remainingStrRange.location = matchedRange.location + matchedRange.length;
		remainingStrRange.length = strRange.location + strRange.length - remainingStrRange.location;

		// Search what is left of the string with the rest of the abbreviation
		remainingScore = QSScoreForAbbreviationWithRanges(str, abbr, mask, remainingStrRange, CFRangeMake(abbrRange.location + i, abbrRange.length - i));

		if (remainingScore) {
			score = (remainingStrRange.location - strRange.location);
			// ignore skipped characters if is first letter of a word
			if (matchedRange.location > strRange.location) {
				// if some letters were skipped
				UniChar previousChar = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, matchedRange.location - 1);
				UniChar character = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, matchedRange.location);

				if (CFCharacterSetIsCharacterMember(wordSeparator, previousChar)) {
					// We're on the first letter of a word
					for (j = matchedRange.location - 2; j >= strRange.location; j--) {
						if (CFCharacterSetIsCharacterMember(wordSeparator, CFStringGetCharacterFromInlineBuffer(&inlineBuffer, j)))
							score--;
						else
							score -= SKIPPED_SCORE;
					}
				} else if (CFCharacterSetIsCharacterMember(uppercase, character)) {
					for (j = matchedRange.location - 1; j >= strRange.location; j--) {
						if (CFCharacterSetIsCharacterMember(uppercase, CFStringGetCharacterFromInlineBuffer(&inlineBuffer, j)))
							score--;
						else
							score -= SKIPPED_SCORE;
					}
				} else {
					// reduce the score by the distance / 1.5: a larger penalty for skipping characters in the middle of a word
					score -= (matchedRange.location-strRange.location)/1.4;
				}
			}
			score += remainingScore * remainingStrRange.length;
			score /= strRange.length;
			CFRelease(userLoc);
			if (mask) {
				[mask addIndexesInRange:NSMakeRange(matchedRange.location, matchedRange.length)];
			}
			return score;
		}
	}
	CFRelease(userLoc);
	return 0;
}
