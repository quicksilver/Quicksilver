//
// QSHTMLLinkParser.m
// Quicksilver
//
// Created by Alcor on 11/7/04.
// Copyright 2004 Blacktree. All rights reserved.
//

// FIXME: Is the space in @"&amp; " intentional?

#import "QSHTMLLinkParser.h"
#import <QSCore/QSResourceManager.h>
#import "HTMLReader.h"

@implementation QSHTMLLinkParser

- (id)init {
	if (self = [super init]) {}
	return self;
}

- (BOOL)validParserForPath:(NSString *)path {
	BOOL isDirectory;
	[[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    
	return !isDirectory;
}

- (NSArray *)objectsFromData:(NSData *)data encoding:(NSStringEncoding)encoding settings:(NSDictionary *)settings source:(NSURL *)source {
	NSString *string = [[NSString alloc] initWithData:data encoding:encoding?encoding:NSUTF8StringEncoding];
    if (data && !string) {
        // no string, most likely becuase the encoding was wrong. Try to sniff the encoding
        encoding = [NSString stringEncodingForData:data encodingOptions:@{NSStringEncodingDetectionAllowLossyKey: @NO, NSStringEncodingDetectionDisallowedEncodingsKey:@[[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding]]} convertedString:&string usedLossyConversion:nil];
    }
    
	//NSLog(@"data %d %@, settings %@, source %@", [data length] , string, settings, source);
	NSString *prefix;
	if (prefix = [settings objectForKey:@"contentPrefix"]) {
		NSRange prefixRange = [string rangeOfString:prefix];
		if (prefixRange.location != NSNotFound) {
			string = [string substringFromIndex:NSMaxRange(prefixRange) +1];
		}
	}
	NSString *suffix;
	if (suffix = [settings objectForKey:@"contentSuffix"]) {
		NSRange suffixRange = [string rangeOfString:suffix];
		if (suffixRange.location != NSNotFound) {
			string = [string substringToIndex:suffixRange.location];
		}
	}
	if (prefix || suffix) {
		data = [string dataUsingEncoding:encoding];
	}
	NSMutableArray *foundLinks = [NSMutableArray array];
	HTMLDocument *document = [HTMLDocument documentWithString:string];
	QSObject *newObject = nil;
	NSMutableArray *objects = [NSMutableArray array];
	NSCharacterSet *wncs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	for (HTMLElement *elem in [document nodesMatchingSelector:@"a"]) {
		NSString *href = elem.attributes[@"href"];
		if (!href || [href isEqualToString:@"#"] || [elem.attributes[@"aria-hidden"] isEqualToString:@"true"] || [href rangeOfString:@"javascript:"].location == 0) {
			continue;
		}
		NSString *urlString = [[href stringByReplacingOccurrencesOfString:@"&amp; " withString:@"&"] stringByReplacingOccurrencesOfString:@"%s" withString:QUERY_KEY];
		urlString = [[NSURL URLWithString:[urlString URLEncoding] relativeToURL:source] absoluteString];
		// skip over URLs that have already been found
		if ([foundLinks containsObject:urlString]) {
			continue;
		}
		[foundLinks addObject:urlString];
		
		NSString *name = [[[elem.textComponents arrayByEnumeratingArrayUsingBlock:^NSString *(NSString *string) {
			return [string stringByTrimmingCharactersInSet:wncs];
		}] componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:wncs];
		NSString *imageurl = nil;
		HTMLElement *img = [elem firstNodeMatchingSelector:@"img"];
		NSImage *loadedIcon = nil;
		if (img && img.attributes[@"src"]) {
			imageurl = img.attributes[@"src"];
			NSRange dataRange = [imageurl rangeOfString:@"data:"];
			if (dataRange.location == 0) {
				// img url starts with data: style image (e.g. data:image/png). Cut everything before the first comma
				@try {
					NSArray *parts = [imageurl componentsSeparatedByString:@","];
					imageurl = [[parts subarrayWithRange:NSMakeRange(1, parts.count-1)] componentsJoinedByString:@","];
					loadedIcon = [[NSImage alloc] initWithData:[imageurl dataUsingEncoding:NSUTF8StringEncoding]];
					if (!loadedIcon) {
						// couldn't convert data: string to image
						// last attempt: try to get the icon from data-src (common with lazy-loaded images)
						if (img.attributes[@"data-src"]) {
							imageurl = img.attributes[@"data-src"];
						} else {
							// couldn't find any images :(
							imageurl = nil;
						}
					}
				} @catch (NSException *e){
					// bail, it's a dodgy image src
					imageurl = nil;
				}
			}
			if (![name length]) {
                // look for a link title here if none exists
				for (NSString *attribute in @[@"title", @"alt"]) {
					if (img.attributes[attribute]) {
						name = img.attributes[attribute];
						break;
					}
				}
			}
		}
		name = [name stringByTrimmingCharactersInSet:wncs];
		if (![name length] && elem.attributes[@"title"]) {
			name = elem.attributes[@"title"];
		}
		if (![name length] && !img) {
			// gets the text of e.g. buttons
			name = [elem.textContent stringByTrimmingCharactersInSet:wncs];
		}
		
		// still no name, but we have an image - use the last path component of the image url
		imageurl = [[NSURL URLWithString:imageurl relativeToURL:source] absoluteString];
		if (![name length] && imageurl) {
			name = [imageurl lastPathComponent];
		}
		// if there's *still* no title (empty tag), skip it
		if (![name length]) {
			continue;
		}
		// make sure it's an actual URL
		newObject = [QSObject URLObjectWithURL:urlString title:name];
		[newObject assignURLTypesWithURL:urlString];
		
		[newObject setLabel:name];
		
		if (loadedIcon) {
			[newObject setIcon:loadedIcon];
			[newObject setIconLoaded:YES];
		} else if (imageurl.length) {
			// load the image from the web
			[newObject setObject:imageurl forMeta:kQSObjectIconName];
			[newObject setIconLoaded:NO];
		}
		if (newObject) {
			[objects addObject:newObject];
		}
	}
	return objects;
}

@end
