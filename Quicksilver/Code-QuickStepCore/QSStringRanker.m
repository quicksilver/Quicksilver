//
// QSStringRanker.m
// Quicksilver
//
// Created by Alcor on 1/28/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSStringRanker.h"
#import "QSense.h"
#import "NSString_Purification.h"

@implementation QSDefaultStringRanker
- (id)initWithString:(NSString *)string {
	if (!string) {
		[self release];
		return nil;
    }
    self = [super init];
    if (self) {
        [self setRankedString:string];
    }
	return self;
}

- (void)dealloc {
	[normString release];
	normString = nil;
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ @%", [super description], normString];
}

- (NSString*)rankedString { return normString; }
- (void)setRankedString:(NSString*)aString {
    if (aString != normString) {
        [normString release];
        normString = [[aString purifiedString] retain];
    }
}

- (double)scoreForAbbreviation:(NSString*)anAbbreviation {
	return QSScoreForAbbreviation((CFStringRef) normString, (CFStringRef)anAbbreviation, nil);
}

- (NSIndexSet*)maskForAbbreviation:(NSString*)anAbbreviation {
	NSMutableIndexSet *mask = [NSMutableIndexSet indexSet];
	QSScoreForAbbreviation((CFStringRef) normString, (CFStringRef)anAbbreviation, mask);
	return mask;
}
@end
