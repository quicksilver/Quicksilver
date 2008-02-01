//
//  QSense.m
//  QSqSense
//
//  Created by Alcor on 11/22/04.

//

#import "QSense.h"

#define MIN_ABBR_OPTIMIZE 0
#define IGNORED_SCORE 0.9
#define SKIPPED_SCORE 0.15

float QSScoreForAbbreviationWithRanges( CFStringRef str,CFStringRef abbr,id mask,CFRange strRange,CFRange abbrRange );

float QSScoreForAbbreviation( CFStringRef str, CFStringRef abbr, id mask) {
	//QSLog(@" %@ %@ %@",str,abbr,mask);
	return QSScoreForAbbreviationWithRanges( str, abbr, mask,
											CFRangeMake( 0, CFStringGetLength( str ) ),
											CFRangeMake( 0, CFStringGetLength( abbr ) ) );
	//return [self scoreForAbbreviation:abbreviation inRange:NSMakeRange(0,[self length]) fromRange:NSMakeRange(0,[abbreviation length]) hitMask:mask];	
}

float QSScoreForAbbreviationWithRanges( CFStringRef str, CFStringRef abbr, id mask, CFRange strRange, CFRange abbrRange ) {
	float score, remainingScore;
	int i, j;
	CFRange matchedRange, remainingStrRange, adjustedStrRange = strRange;
	if( !abbrRange.length )
        return IGNORED_SCORE; //deduct some points for all remaining letters

	if( abbrRange.length > strRange.length )
        return 0.0;
    
	//	if (abbrRange.length>MIN_ABBR_OPTIMIZE){
	UniChar u = CFStringGetCharacterAtIndex( abbr,abbrRange.location );
	UniChar uc = toupper(u);
	UniChar chars[strRange.length];
	Boolean found = NO;
	CFStringGetCharacters( str, strRange, chars );
	
	for( i = 0; i < strRange.length; i++ ) {
		if ( chars[i] == u || chars[i] == uc ) {
			found = YES;
			break;
		}
	}
	if( !found )
        return 0.0;
	adjustedStrRange.length -= i;
	adjustedStrRange.location += i;
	//	}
	
	
	for( i = abbrRange.length; i > 0; i-- ) { //Search for steadily smaller portions of the abbreviation
		CFStringRef curAbbr = CFStringCreateWithSubstring( NULL, abbr, CFRangeMake( abbrRange.location, i ) );
		//terminality
		
		//axeen
		BOOL found = CFStringFindWithOptions( str, curAbbr, CFRangeMake( adjustedStrRange.location, adjustedStrRange.length  -abbrRange.length + i ),
										   kCFCompareCaseInsensitive, &matchedRange );
		CFRelease( curAbbr );
		
		if( !found )
            continue;
		//if (matchedRange.location+abbrRange.length>strRange.location+strRange.length) continue;
		
		if( mask )
            [mask addIndexesInRange:NSMakeRange( matchedRange.location, matchedRange.length )];
		
		remainingStrRange.location = matchedRange.location + matchedRange.length;
		remainingStrRange.length = strRange.location + strRange.length - remainingStrRange.location;
		
		// Search what is left of the string with the rest of the abbreviation
		remainingScore = QSScoreForAbbreviationWithRanges( str, abbr, mask, remainingStrRange, CFRangeMake(abbrRange.location + i, abbrRange.length - i ) );
		
		if ( remainingScore ) {
			score = remainingStrRange.location - strRange.location;
			// ignore skipped characters if is first letter of a word
			if ( matchedRange.location > strRange.location ) {
                //if some letters were skipped
				static CFCharacterSetRef whitespace = NULL;
				if( !whitespace )
                    whitespace = CFCharacterSetGetPredefined( kCFCharacterSetWhitespace );
				static CFCharacterSetRef uppercase = NULL;
				if( !uppercase )
                    uppercase = CFCharacterSetGetPredefined( kCFCharacterSetUppercaseLetter );
				
				j = 0;
				if( CFCharacterSetIsCharacterMember( whitespace, CFStringGetCharacterAtIndex( str, matchedRange.location - 1 ) ) ) {
					for( j = matchedRange.location - 2; j >= (int)strRange.location; j-- ) {
						if( CFCharacterSetIsCharacterMember( whitespace, CFStringGetCharacterAtIndex( str, j ) ) )
                            score--;
						else
                            score -= SKIPPED_SCORE;
					}
					
				} else if ( CFCharacterSetIsCharacterMember( uppercase, CFStringGetCharacterAtIndex( str, matchedRange.location ) ) ) {
					for ( j = matchedRange.location - 1; j >= (int)strRange.location; j-- ) {
						if( CFCharacterSetIsCharacterMember( uppercase, CFStringGetCharacterAtIndex( str, j ) ) )
							score--;
						else
							score -= SKIPPED_SCORE;
					}
				} else {
					score -= matchedRange.location - strRange.location;
				}
				
			}
			
			score += remainingScore * remainingStrRange.length;
			score /= strRange.length;
			return score;
		}
	}
	return 0;
}

/*
 
 UniChar ch;
	CFStringInlineBuffer buf;
	CFStringInitInlineBuffer(string, &buf, CFRangeMake(rangeLoc, rangeLen));
	while (numCharsProcessed < rangeLen) {
	    ch = CFStringGetCharacterFromInlineBuffer(&buf, numCharsProcessed);
	}
 
 
 
 
 
 
 
 {
	 matchedRange=[self rangeOfString:[abbreviation substringWithRange:NSMakeRange(abbrRange.location,1)]
							  options:NSCaseInsensitiveSearch
								range:strRange];
	 
	 if (matchedRange.location==NSNotFound) return 0.9;
	 strRange.length-=matchedRange.location-strRange.location;
	 strRange.location=matchedRange.location;
 }
 */