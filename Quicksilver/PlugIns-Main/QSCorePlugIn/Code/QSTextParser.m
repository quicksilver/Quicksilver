//
// QSTextParser.m
// Quicksilver
//
// Created by Alcor on 4/6/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSTextParser.h"

#import <QSCore/QSCore.h>

@implementation QSTextLineParser
- (BOOL)validParserForPath:(NSString *)path {
	BOOL isDirectory;
	[[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    
	return !isDirectory;
}

- (NSArray *)linesFromString:(NSString *)string atPath:(NSString *)path lineType:(NSString *)lineType {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *lines = [string lines];
    NSInteger i = 0;
	for (id line in lines) {
		if (lineType)
			newObject = [QSObject objectWithType:lineType value:line name:line];
		else
			newObject = [QSObject objectWithString:line];

		[newObject setDetails:nil];

		if (path) {
			[newObject setObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithUnsignedInteger:i+1] , @"line", nil]
						 forType:@"QSLineReferenceType"];
		}
		if (newObject) {
			[array addObject:newObject];
        }
        i = i+1;
	}
				return array;
}
- (NSArray *)linesFromString:(NSString *)string atPath:(NSString *)path {
	return [self linesFromString:(NSString *)string atPath:(NSString *)path lineType:nil];
}
- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings {
	NSString *string = [NSString stringWithContentsOfFile: [path stringByStandardizingPath] usedEncoding:nil error:nil];
	return [self linesFromString:string atPath:path lineType:[settings objectForKey:@"lineContentType"]];
}
- (NSArray *)objectsFromURL:(NSURL *)url withSettings:(NSDictionary *)settings {
	NSString *string = [NSString stringWithContentsOfURL:url usedEncoding:nil error:nil];
	return [self linesFromString:string atPath:nil lineType:[settings objectForKey:@"lineContentType"]];
}
@end

@interface QSPlistParser : NSObject
@end

@implementation QSPlistParser
- (BOOL)validParserForPath:(NSString *)path {
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory/*, exists*/;
	/*exists = */[manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
	return !isDirectory && [[path pathExtension] isEqual:@"plist"];
}
- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings {
	//	NSData *data = [NSData dataWithContentsOfFile: [path stringByStandardizingPath]];

	return nil;
	//[NSPropertyListSerialization propertyListFromData:data mutabilityOption:kCFPropertyListImmutable format:nil errorDescription:nil];
	//return [self linesFromString:string];
}
- (NSArray *)linesFromString:(NSString *)string {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	for(NSString * line in [string componentsSeparatedByString:@"\n"]) {
		QSObject * newObject = [QSObject objectWithString:line];
		[newObject setDetails:nil];
		if (newObject)
			[array addObject: newObject];
	}
	return array;
}

@end
