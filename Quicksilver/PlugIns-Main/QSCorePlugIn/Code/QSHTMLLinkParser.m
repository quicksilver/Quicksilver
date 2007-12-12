//
// QSHTMLLinkParser.m
// Quicksilver
//
// Created by Alcor on 11/7/04.
// Copyright 2004 Blacktree. All rights reserved.
//

// FIXME: Is the space in @"&amp; " intentional?

#import "QSHTMLLinkParser.h"

@implementation QSHTMLLinkParser

- (id)init {
	if (self = [super init]) {}
	return self;
}

- (BOOL)validParserForPath:(NSString *)path {
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory, exists;
	exists = [manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
	return !isDirectory;
}

- (NSArray *)objectsFromData:(NSData *)data encoding:(NSStringEncoding)encoding settings:(NSDictionary *)settings source:(NSURL *)source {
	NSString *string = [[NSString alloc] initWithData:data encoding:encoding?encoding:NSISOLatin1StringEncoding];
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
	 if (prefix || suffix)
		 data = [string dataUsingEncoding:encoding];
	NSString *script = [[NSBundle bundleForClass:[self class]] pathForResource:@"QSURLExtractor" ofType:@"pl"];
	//NSLog(@"parsing with %@\r%@", script, source);
	NSTask *task = [NSTask taskWithLaunchPath:@"/usr/bin/perl" arguments:[NSArray arrayWithObject:script]];
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

	[string release];

	NSMutableData *returnData = [[NSMutableData alloc] init];
	NSData *readData;
	while ((readData = [readHandle availableData]) && [readData length]) {
		[returnData appendData:readData];
	}

	string = [[NSString alloc] initWithData:returnData encoding:encoding?encoding:NSISOLatin1StringEncoding];
	[returnData release];
	NSArray *array = [string componentsSeparatedByStrings:[NSArray arrayWithObjects:@"\n", @"\t", nil]];
	[string release];

	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSEnumerator *e = [array objectEnumerator];
	NSArray *link;
	NSCharacterSet *wncs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	while(link = [e nextObject]) {
		if ([link count] < 4) continue;
		NSString *shortcut = [link objectAtIndex:2];
		NSString *url = [[[link objectAtIndex:0] stringByReplacing:@"&amp; " with:@"&"] stringByReplacing:@"%s" with:@"***"];
		NSString *text = [link objectAtIndex:1];
		NSString *imageurl = [link objectAtIndex:3];
		if (text) {
			NSString *name = [shortcut length] ? shortcut : text;
			NSString *label = [shortcut length] ? text : nil;
			if (url)
				url = [[NSURL URLWithString:url relativeToURL:source] absoluteString];
			newObject = [QSObject URLObjectWithURL:url title:[name stringByTrimmingCharactersInSet:wncs]];
			if (label) [newObject setLabel:label];
			if (imageurl) {
				imageurl = [[NSURL URLWithString:imageurl relativeToURL:source] absoluteString];
				[newObject setObject:imageurl forMeta:kQSObjectIconName];
			}
			if (newObject)
				[objects addObject:newObject];
		}
	}
	return objects;
}

@end
