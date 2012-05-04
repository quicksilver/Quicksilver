//
// NSString_CompletionExtensions.m
// Quicksilver
//
// Created by Alcor on Mon Mar 03 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSString_BLTRExtensions.h"
#import "NSArray_BLTRExtensions.h"

NSComparisonResult prefixCompare(NSString *aString, NSString *bString) {
	int length = MIN([aString length] , [bString length]);
	if (!length) return NSOrderedSame;
	return [aString compare:bString options:NSCaseInsensitiveSearch range:NSMakeRange(0, MIN([aString length] , [bString length]) )];
}

@implementation NSString (Abbreviation)
- (float) scoreForString:(NSString *)testString {
	float score = 1;
	int i;
	NSString *characterString;
	NSRange currentRange = NSMakeRange(0, [testString length]);
	int index;
	for (i = 0; i<(int) [self length]; i++) {
		characterString = [self substringWithRange:NSMakeRange(i, 1)];
		index = [testString rangeOfString:characterString options:NSCaseInsensitiveSearch range:currentRange].location;
		if (index == NSNotFound) return 0;
		score -= (float) (index-currentRange.location)/[testString length];
		currentRange.location = index+1;
		currentRange.length = [testString length]-index-1;
	}
	score -= currentRange.length/[testString length];
	return score;
}

#if 0
- (float) oldScoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask {
	return [self scoreForAbbreviation:abbreviation inRange:NSMakeRange(0, [self length]) fromRange:NSMakeRange(0, [abbreviation length]) hitMask:mask];
}
- (float) oldScoreForAbbreviation:(NSString *)abbreviation {
	return [self oldScoreForAbbreviation:abbreviation hitMask:nil];
}
#endif

- (float) scoreForAbbreviation:(NSString *)abbreviation {
	return [self scoreForAbbreviation:abbreviation hitMask:nil];
}
- (float) scoreForAbbreviation:(NSString *)abbreviation hitMask:(NSMutableIndexSet *)mask {
	return [self scoreForAbbreviation:abbreviation inRange:NSMakeRange(0, [self length]) fromRange:NSMakeRange(0, [abbreviation length]) hitMask:mask];
}

- (float) scoreForAbbreviation:(NSString *)abbreviation inRange:(NSRange)searchRange fromRange:(NSRange)abbreviationRange hitMask:(NSMutableIndexSet *)mask {
	float score, remainingScore;
	int i, j;
	NSRange matchedRange, remainingSearchRange;
	if (!abbreviationRange.length) return 0.9; //deduct some points for all remaining letters
	if (abbreviationRange.length>searchRange.length) return 0.0;
	for (i = abbreviationRange.length; i>0; i--) { //Search for steadily smaller portions of the abbreviation
		matchedRange = [self rangeOfString:[abbreviation substringWithRange:NSMakeRange(abbreviationRange.location, i)] options:NSCaseInsensitiveSearch range:searchRange];

		if (matchedRange.location == NSNotFound || matchedRange.location+abbreviationRange.length>NSMaxRange(searchRange)) continue;

		if (mask) [mask addIndexesInRange:matchedRange];

		remainingSearchRange.location = NSMaxRange(matchedRange);
		remainingSearchRange.length = NSMaxRange(searchRange) -remainingSearchRange.location;

		// Search what is left of the string with the rest of the abbreviation
		remainingScore = [self scoreForAbbreviation:abbreviation inRange:remainingSearchRange fromRange:NSMakeRange(abbreviationRange.location+i, abbreviationRange.length-i) hitMask:mask];
		if (remainingScore) {
			score = remainingSearchRange.location-searchRange.location;
			// ignore skipped characters if is first letter of a word
			if (matchedRange.location>searchRange.location) {//if some letters were skipped
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
	for (i = 0; i<[self length]; i++) {
		characterString = [self substringWithRange:NSMakeRange(i, 1)];
		index = [testString rangeOfString:characterString options:NSCaseInsensitiveSearch range:currentRange].location;
		if (index == NSNotFound) return hitsArray;
		[hitsArray addObject:[NSNumber numberWithInt:index]];
		currentRange.location = index+1;
		currentRange.length = [testString length]-index-1;
	}
	return hitsArray;
}

@end

@implementation NSAttributedString (Sizing)
- (NSSize)sizeForWidth:(float)width {
	NSSize size = NSZeroSize;

	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, MAXFLOAT)];

	[textStorage addLayoutManager:layoutManager];
	[layoutManager addTextContainer:container];

	unsigned numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
	NSRange lineRange;
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++) {
		NSRect rect = [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		size.height += NSHeight(rect);
		size.width = MAX(size.width, NSWidth(rect) );
		index = NSMaxRange(lineRange);
	}

	[container release];
	[layoutManager release];
	[textStorage release];

	return size;
}
@end

@implementation NSString (URLEncoding)

- (NSString *)URLEncoding {
	
    return [self URLEncodingWithEncoding:kCFStringEncodingUTF8];
}

- (NSString *)URLEncodingWithEncoding:(CFStringEncoding) encoding {
	
	NSString *string = self;
	
	if([self rangeOfString:@"%"].location != NSNotFound) {
		string = [self URLDecoding];
	}
	
	// escape embedded %-signs that don't appear to actually be escape sequences, and pre-decode the result to avoid double-encoding
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) string, CFSTR("#"), NULL, encoding) autorelease];
}

- (NSString *)URLEncodeValue {
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
    return [result autorelease];
}

- (NSString *)URLDecoding {
	// Cocoa's stringByReplacingPercentEscapes... and CF's CFURLCreateStringByEscapingPercentEscapes... both return nil if there's a % in the string that doesn't
	// need escaping e.g. '100% free = 100% a load of crap'
	NSString *string = self;
	NSString *replacedString = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	// Try Cocoa's way of replacing % escapes
	if (replacedString !=nil) {
		// Return the replaced string if Cocoa's method works
		return replacedString;
	}
	else {
		// If it fails, do a manual replace
		string = [string stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
		string = [string stringByReplacingOccurrencesOfString:@"%22" withString:@"'"];
		string = [string stringByReplacingOccurrencesOfString:@"%3C" withString:@"<"];
		string = [string stringByReplacingOccurrencesOfString:@"%3E" withString:@">"];
		string = [string stringByReplacingOccurrencesOfString:@"%25" withString:@"%"];
		string = [string stringByReplacingOccurrencesOfString:@"%7C" withString:@"|"];
		string = [string stringByReplacingOccurrencesOfString:@"%5C" withString:@"\\"];
		return string;
	}
}
@end

@implementation NSString (Truncation)

- (NSString *)stringTruncatedToWidth:(float) width withAttributes:(NSDictionary *)attributes {

	if ([self sizeWithAttributes:attributes].width <= width) return self;

	NSString *ellipsisString = @"...";
	NSSize ellipsisSize = [ellipsisString sizeWithAttributes:attributes];

	if (width<ellipsisSize.width) return @"";

	NSMutableString *truncString = [self mutableCopy];

	float naturalWidth = [truncString sizeWithAttributes:attributes].width;
	int extra = (float) [self length] * (naturalWidth-width)/naturalWidth;

	[truncString deleteCharactersInRange:NSMakeRange(([self length]-extra) / 2, extra)];

	while ([truncString sizeWithAttributes:attributes].width + ellipsisSize.width > width) {
		[truncString deleteCharactersInRange:NSMakeRange([truncString length] / 2, 1)];
	}

	if ([truncString length])
		[truncString insertString:ellipsisString atIndex:([truncString length]+1) / 2];
	return [truncString autorelease];
}

@end

@implementation NSString(uuid)
+ (NSString *)uniqueString {
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);
	return [(NSString *)uuidStr autorelease];
}
@end

@implementation NSString (Hex)

- (NSString *)decodedPasteboardType {
	NSString *coreString = @"CorePasteboardFlavorType 0x";
		return ([self hasPrefix:coreString]) ? [NSString stringWithFormat:@"'%@'", [[self substringFromIndex:[coreString length]] decodedHexString]] : self;
}

- (NSString *)encodedPasteboardType {
	return ([self hasPrefix:@"'"] && [self hasSuffix:@"'"]) ? [NSString stringWithFormat:@"CorePasteboardFlavorType 0x%@", [[[self substringWithRange:NSMakeRange(1, [self length] -2)] encodedHexString] uppercaseString]] : self;
}

- (NSString *)decodedHexString {
	char s[4]; unsigned x; int i;
	for (i = 0; i<((int) [self length] / 2); i++) {
		[[NSScanner scannerWithString:[self substringWithRange:NSMakeRange(i*2, 2)]] scanHexInt:&x];
		s[i] = (char)x;
	}
    // !!! Andre Berg 20091007: remove deprecated method
	//return [NSString stringWithCString:s length:4];
    return [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
}

- (unsigned) hexIntValue {
	unsigned x;
	[[NSScanner scannerWithString:self] scanHexInt:&x];
	return x;
}

- (NSString *)encodedHexString {
	NSMutableString *myHexString = [NSMutableString string];
	short index = 0;
	for (; index < [self length]; index++) {
		[myHexString appendFormat:@"%x", [self characterAtIndex:index]];
	}
	return myHexString;
}

- (NSComparisonResult) versionCompare:(NSString *)other { return [self hexIntValue] - [other hexIntValue]; }

@end

@implementation NSString (Replacement)
- (NSArray *)lines {
	NSMutableString *mut = [NSMutableString stringWithString:self];
	[mut replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [mut length])];
	[mut replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [mut length])];
	return [mut componentsSeparatedByString:@"\n"];
}
- (NSString *)stringByReplacing:(NSString *)search with:(NSString *)replacement {
	NSMutableString *result = [NSMutableString stringWithCapacity:[self length]];
	[result setString:self];
	[result replaceOccurrencesOfString:search withString:replacement options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	return result;}

@end


@implementation NSString (Fit)

- (NSDictionary *)attributesToFitNumbersInRect:(NSRect) rect withAttributes:(NSDictionary *)attributes {
	NSMutableDictionary *newAttributes = [attributes mutableCopy];
	if (!newAttributes) newAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
	NSFont *font = [NSFont fontWithName:[[newAttributes objectForKey:NSFontAttributeName] fontName] size:12];
	[newAttributes setObject:font forKey:NSFontAttributeName];

	NSSize baseSize = [self sizeWithAttributes:newAttributes];
//	float xScale = NSWidth(rect) / baseSize.width, yScale = NSHeight(rect) / ([font ascender] - [font descender]);
	float newFontSize = 12*MIN(NSWidth(rect) / baseSize.width, NSHeight(rect) / ([font ascender] - [font descender]));
	[newAttributes setObject:[NSFont fontWithName:[font fontName] size:newFontSize] forKey:NSFontAttributeName];
	return [newAttributes autorelease];
}

- (NSDictionary *)attributesToFitRect:(NSRect) rect withAttributes:(NSDictionary *)attributes {
	NSMutableDictionary *newAttributes = [[attributes mutableCopy] autorelease];
	if (!newAttributes) newAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
	NSFont *font = [newAttributes objectForKey:NSFontAttributeName];
	float fontSize = [font pointSize];
	NSSize textSize;
	for (; fontSize>6; fontSize--) {
		[newAttributes setObject:[NSFont systemFontOfSize:fontSize] forKey:NSFontAttributeName];
		textSize = [self sizeWithAttributes:newAttributes];
		if (textSize.width <= NSWidth(rect) && textSize.height <= NSHeight(rect) )
			return newAttributes;
	}
	return newAttributes;
}

@end


@implementation NSString (Blacktree)
- (NSArray *)componentsSeparatedByStrings:(NSArray *)strings{
	NSArray *array = nil;
	if([strings count]>0)
		array = [self componentsSeparatedByString:[strings head]];
	if([strings count]>1)	
		array = [array arrayByPerformingSelector:@selector(componentsSeparatedByStrings:) withObject:[strings tail]];
	return array;
}

- (NSString *)subStringByResolvingWildcardsInPath {
	NSRange index = [self rangeOfString:@"*"];
	NSString *resolved;
	if (index.location == NSNotFound) {
		resolved = [self stringByStandardizingPath];
		if ([[NSFileManager defaultManager] fileExistsAtPath:resolved]) {
			return resolved;
		} else {
			return nil;
		}
	}
	
	NSString *basePath = [self substringToIndex:index.location];
	NSString *remainingPath = [self substringFromIndex:(index.location + 1)];
	NSError *err = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[basePath stringByStandardizingPath] error:&err];
	if (err != nil) {
		NSLog(@"Error while resolving wildcards in path: %@", err);
		return nil;
	}
	
	for (NSString *resolvedPathPart in contents) {
		resolved = [[[basePath
					  stringByAppendingPathComponent:resolvedPathPart]
					 stringByAppendingPathComponent:remainingPath] subStringByResolvingWildcardsInPath];
		if (resolved != nil) {
			return resolved;
		}
	}
	return nil;
}

- (NSString *)stringByResolvingWildcardsInPath {
	NSString *resolvedString = [self subStringByResolvingWildcardsInPath];
	if (resolvedString == nil) {
		return self;
	}
	return resolvedString;
}

- (NSString *)firstUnusedFilePath {
	NSString *basePath = [self stringByDeletingPathExtension];
	NSString *extension = [self pathExtension];
	NSString *alternatePath = self;
	int i;
	for (i = 1; [[NSFileManager defaultManager] fileExistsAtPath:alternatePath]; i++)
		alternatePath = [NSString stringWithFormat:@"%@ %d.%@", basePath, i, extension];
	return alternatePath;
}
+ (NSData *)dataForObject:(id)object forType:(NSString *)type {
	// the string's link (only different from the title if it contains the mailto: prefix)
	NSString *linkString = [object objectForType:NSURLPboardType];
	// the string's title
	NSString *titleString = [object stringValue];
	
	// Dict containing the attributed string's attributes (most notably, a link)
	NSDictionary *attStringAttributes = [NSDictionary dictionaryWithObject:[NSURL URLWithString:[linkString URLEncoding]]
																	forKey:NSLinkAttributeName];
	
	// create the attributed string
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:titleString attributes:attStringAttributes];
	
	// For HTML pasteboard types, create a HTML data object
	if([type isEqualToString:NSHTMLPboardType]) {
		NSArray * exclude = [NSArray arrayWithObjects:@"doctype",@"html",@"head",@"body",@"xml",nil];
		NSDictionary * htmlAtt = [NSDictionary dictionaryWithObjectsAndKeys:NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute,
								  exclude,NSExcludedElementsDocumentAttribute,nil];
		
		return [attString dataFromRange:NSMakeRange(0, [attString length]) documentAttributes:htmlAtt error:nil];
	}
	// For RTF pasteboard types, create an RTF data object
	else if([type isEqualToString:NSRTFPboardType]) {
		return [attString RTFFromRange:NSMakeRange(0, [attString length])
					documentAttributes:nil];
	}
	
	return nil;
}

@end
