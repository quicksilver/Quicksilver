//
//  NSString_CompletionExtensions.h
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSAttributedString * highlightString(NSString *string, NSString *keyString);

NSComparisonResult prefixCompare(NSString *aString, NSString *bString);

@interface NSString (Abbreviation)
- (CGFloat) scoreForString:(NSString *)string;

- (NSArray *)hitsForString:(NSString *)testString;

- (CGFloat) scoreForAbbreviation:(NSString *)abbreviation;
//- (float) oldScoreForAbbreviation:(NSString *)abbreviation;
- (CGFloat) scoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask;
//- (float) oldScoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask;
- (CGFloat) scoreForAbbreviation:(NSString *)abbreviation inRange:(NSRange)searchRange fromRange:(NSRange)abbreviationRange hitMask:(NSMutableIndexSet *)mask;

@end

@interface NSAttributedString (Sizing)
- (NSSize) sizeForWidth:(CGFloat)width;
@end

@interface NSString (URLEncoding)
- (NSString *)URLEncoding;
- (NSString *)URLDecoding;
- (NSString *)URLEncodeValue;
@end

@interface NSString(uuid)
+ (NSString *)uniqueString;
@end

@interface NSString (Truncation)

- (NSString *)stringTruncatedToWidth:(CGFloat) width withAttributes:(NSDictionary *)attributes;
@end



@interface NSString (Hex)
- (NSString *)decodedPasteboardType;
- (NSString *)decodedHexString;

- (NSString *)encodedPasteboardType;
- (NSString *)encodedHexString;
- (NSUInteger) hexIntValue;
- (NSComparisonResult) versionCompare:(NSString *)other;
- (NSString *)encodedPasteboardType;
@end


@interface NSString (Replacement)
- (NSArray *)lines;
- (NSString *)stringByReplacing:(NSString *)search with:(NSString *)replacement;

@end

@interface NSString (Fit)
- (NSDictionary *)attributesToFitNumbersInRect:(NSRect) rect withAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesToFitRect:(NSRect) rect withAttributes:(NSDictionary *)attributes;
@end


@interface NSString (Blacktree)
/**
 Resolves file paths that contain wildcards (*).
 Returns the first path it can find, with all the wildcards resolved.
 If it can't find a file with all wildcards resolved, it returns the 
 original path (possibly with wildcards).
 Also standardizes path (resolves ~ for home path).
 **/
- (NSString *)stringByResolvingWildcardsInPath;
- (NSString *)firstUnusedFilePath;
- (NSArray *)componentsSeparatedByStrings:(NSArray *)strings;
+ (NSData *)dataForObject:(id)object forType:(NSString *)type;
@end
