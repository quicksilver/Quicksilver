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
#define SKIPPED_SCORE 0.15



CGFloat QSScoreForAbbreviationWithRanges(CFStringRef str, CFStringRef abbr, id mask, CFRange strRange, CFRange abbrRange);

CGFloat QSScoreForAbbreviation(CFStringRef str, CFStringRef abbr, id mask) {
	return QSScoreForAbbreviationWithRanges(str, abbr, mask, CFRangeMake(0, CFStringGetLength(str)), CFRangeMake(0, CFStringGetLength(abbr)));
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
	CFStringInitInlineBuffer(str, &inlineBuffer, strRange);
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

		if (mask) {
			[mask addIndexesInRange:NSMakeRange(matchedRange.location, matchedRange.length)];
		}

		remainingStrRange.location = matchedRange.location + matchedRange.length;
		remainingStrRange.length = strRange.location + strRange.length - remainingStrRange.location;

		// Search what is left of the string with the rest of the abbreviation
		remainingScore = QSScoreForAbbreviationWithRanges(str, abbr, mask, remainingStrRange, CFRangeMake(abbrRange.location + i, abbrRange.length - i));

		if (remainingScore) {
			score = remainingStrRange.location-strRange.location;
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
					score -= (matchedRange.location-strRange.location)/2;
				}
			}
			score += remainingScore * remainingStrRange.length;
			score /= strRange.length;
			CFRelease(userLoc);
			return score;
		}
	}
	CFRelease(userLoc);
	return 0;
}
