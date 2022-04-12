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
		if (!href || [href isEqualToString:@"#"]) {
			continue;
		}
		NSString *urlString = [[href stringByReplacingOccurrencesOfString:@"&amp; " withString:@"&"] stringByReplacingOccurrencesOfString:@"%s" withString:QUERY_KEY];
		urlString = [[NSURL URLWithString:[urlString URLEncoding] relativeToURL:source] absoluteString];
		
		// skip over URLs that have already been found
		if ([foundLinks containsObject:urlString]) {
			continue;
		}
		[foundLinks addObject:urlString];
		
		NSString *name = [elem.textContent stringByTrimmingCharactersInSet:wncs];
		NSString *imageurl = nil;
		HTMLElement *img = [elem firstNodeMatchingSelector:@"img"];
		if (img && img.attributes[@"src"]) {
			imageurl = img.attributes[@"src"];
			if (!name || ![name length]) {
                // look for a link title here if none exists
				for (NSString *attribute in @[@"title", @"alt", @"src"]) {
					if (img.attributes[attribute]) {
						name = img.attributes[attribute];
						if ([attribute isEqualToString:@"src"]) {
							// take just the base part
							name = [name lastPathComponent];
						}
						break;
					}
				}
			}
		}
		name = [name stringByTrimmingCharactersInSet:wncs];
		// make sure it's an actual URL
		newObject = [QSObject URLObjectWithURL:urlString title:name];
		[newObject assignURLTypesWithURL:urlString];
		
		[newObject setLabel:name];
		// If the link is an image, set this as the icon
		if (imageurl.length) {
			imageurl = [[NSURL URLWithString:imageurl relativeToURL:source] absoluteString];
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
