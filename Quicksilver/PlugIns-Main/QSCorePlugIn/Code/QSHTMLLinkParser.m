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
	NSString *script = [[NSBundle bundleForClass:[self class]] pathForResource:@"QSURLExtractor" ofType:@"py"];
	//NSLog(@"parsing with %@\r%@", script, source);
	NSTask *task = [NSTask taskWithLaunchPath:@"/usr/bin/env" arguments:[NSArray arrayWithObject:script]];
	NSPipe *readPipe = [NSPipe pipe];
	NSFileHandle *readHandle = [readPipe fileHandleForReading];
	NSPipe *writePipe = [NSPipe pipe];
	NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
	[task setStandardInput:writePipe];
	[task setStandardOutput:readPipe];
	// [task setStandardError:[NSPipe pipe]];
	
	[task launch];
	[writeHandle writeData:data];
	[writeHandle closeFile];
	
	NSMutableData *returnData = [[NSMutableData alloc] init];
	NSData *readData;
	while ((readData = [readHandle availableData]) && [readData length]) {
		[returnData appendData:readData];
	}
	
	string = [[NSString alloc] initWithData:returnData encoding:encoding?encoding:NSUTF8StringEncoding];
	NSArray *array = [string componentsSeparatedByStrings:[NSArray arrayWithObjects:@"\n", @"\t", nil]];
	
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *link;
	NSCharacterSet *wncs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	for(link in array) {
		if ([link count] < 4) continue;
		NSString *shortcut = [link objectAtIndex:2];
		NSString *urlString = [[[link objectAtIndex:0] stringByReplacingOccurrencesOfString:@"&amp; " withString:@"&"] stringByReplacingOccurrencesOfString:@"%s" withString:QUERY_KEY];
		NSString *text = [link objectAtIndex:1];
		NSString *imageurl = [link objectAtIndex:3];
		NSString *name;
		// make sure there's an actual URL
		if (urlString.length) {
			// empty <a></a> tags, give the name of the url
			if(!(text.length || imageurl.length)) {
				name = urlString; 
			}
			// The link is represented by an image, give it the name of the image
			else if(!text.length) {
				name = imageurl;
			}
			else {
				name = [shortcut length] ? shortcut : text;
			}
			
			// make sure it's an actual URL
			urlString = [[NSURL URLWithString:[urlString URLEncoding] relativeToURL:source] absoluteString];
			newObject = [QSObject URLObjectWithURL:urlString title:[name stringByTrimmingCharactersInSet:wncs]];
			[newObject assignURLTypesWithURL:urlString];
			
            NSString *label = [shortcut length] ? text : nil;
            [newObject setLabel:label];
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
	}
	return objects;
}

@end
