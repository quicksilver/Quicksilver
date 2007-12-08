//
//  NSString_CompletionExtensions.h
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.

//

#import <Foundation/Foundation.h>

NSAttributedString * highlightString(NSString *string,NSString *keyString);

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

@interface NSAttributedString (Sizing)
- (NSSize)sizeForWidth:(float)width;
@end

@interface NSString (URLEncoding)
- (NSString *) URLEncoding;
- (NSString *) URLDecoding;
@end

@interface NSString(uuid)
+ (NSString *)uniqueString;
@end

@interface NSString (Truncation)

-(NSString *) stringTruncatedToWidth:(float)width withAttributes:(NSDictionary *)attributes;
@end



@interface NSString (Hex)
-(NSString *) decodedPasteboardType;
-(NSString *) decodedHexString;

-(NSString *) encodedPasteboardType;
-(NSString *) encodedHexString;
-(unsigned) hexIntValue;
- (NSComparisonResult)versionCompare:(NSString *)other;
-(NSString *) encodedPasteboardType;
@end


@interface NSString (Replacement)
- (NSArray *)lines;
- (NSString *) stringByReplacing:(NSString *)search with:(NSString *)replacement;

@end

@interface NSString (Fit)
- (NSDictionary *) attributesToFitNumbersInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;
- (NSDictionary *) attributesToFitRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;
@end


@interface NSString (Blacktree)
- (NSString *)stringByResolvingWildcardsInPath;
-(NSString *)firstUnusedFilePath;
- (NSArray *)componentsSeparatedByStrings:(NSArray *)strings;
@end