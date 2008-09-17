//
//  QSBasicObject.m
//  Quicksilver
//
//  Created by Etienne on 13/09/08.
//  Copyright 2008 Etienne Samson. All rights reserved.
//

#import "QSBasicObject.h"

@implementation QSBasicObject
- (id)init {
	if (self = [super init]) {
		ranker = nil;
	}
	return self;
}

- (void)dealloc {
	[ranker release];
	[super dealloc];
}

- (id <QSObjectRanker>) getRanker {
	id oldRanker;
	oldRanker = ranker;
	ranker = [[QSDefaultObjectRanker alloc] initWithObject:self];
	[oldRanker release];
	return ranker;
}
- (id <QSObjectRanker>) ranker {
	if (!ranker) return [self getRanker];
	return ranker;
}

- (void)updateMnemonics {
	[self getRanker];
    //	[rankData setMnemonics:[[QSMnemonics sharedInstance] objectMnemonicsForID:[self identifier]]];
}
- (id)this {return [[self retain] autorelease];}
- (id)thisWithIcon {
	[self loadIcon];
	return [[self retain] autorelease];
}

- (void)setEnabled:(BOOL)flag {
	[QSLib setItem:self isOmitted:!flag];
}
- (BOOL)enabled {
	return (BOOL)![QSLib itemIsOmitted:self];
}

- (void)setOmitted:(BOOL)flag {
	[[self ranker] setOmitted:flag];
}

- (NSString *)kind {
	return @"Object";
}

- (NSString *)label {return nil;}
- (NSString *)name {return @"Object";}
- (NSString *)primaryType {return nil;}
- (id)primaryObject {return nil;}
- (BOOL)containsType:(NSString *)aType {
	return [[self types] containsObject:aType];
}
- (NSArray *)types {return nil;}
- (int) primaryCount {return 0;}
- (BOOL)loadIcon {return YES;}
- (NSImage *)icon {
	//[NSBundle bundleForClass:[self class]]
	return [NSImage imageNamed:@"Object"];
}
- (NSComparisonResult) compare:(id)other {
	return [[self name] 	compare:[other name]];
}

- (NSImage *)loadedIcon {
	if (![self iconLoaded]) [self loadIcon];
	return [self icon];
}
- (void)becameSelected { return;}

- (BOOL)iconLoaded { return YES;  }
- (QSBasicObject *)parent {return nil;}
- (NSString *)displayName {return [self name];}
- (NSString *)details {return nil;}
- (NSString *)toolTip {return nil;}
- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped {return NO;}
- (id)objectForType:(id)aKey {return nil;}
- (NSArray *)arrayForType:(id)aKey {return nil;}
- (NSEnumerator *)enumeratorForType:(NSString *)aKey {return [[self arrayForType:aKey] objectEnumerator];}
- (float) score {return 0.0;}
- (int) order {return NSNotFound;}
- (BOOL) hasChildren {return NO;}
- (NSArray *)children {return nil;}
- (NSArray *)altChildren {return nil;}
- (NSString *)description {return [NSString stringWithFormat:@"%@ <%p>", NSStringFromClass([self class]), self];}
//- (float) rankModification {return 0;}
- (NSString *)identifier {return nil;}
- (NSComparisonResult) scoreCompare:(QSBasicObject *)object {
	return NSOrderedSame;
}

- (NSArray *)siblings {
    
	return [[self parent] children];
}
- (NSArray *)altSiblings {return [[self parent] altChildren];}

- (NSComparisonResult) nameCompare:(QSBasicObject *)object {
	return [[self name] caseInsensitiveCompare:[object name]];
}
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard {
	return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:nil];
}
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes {
	return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:includeTypes];
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes {
	return NO;
}
- (QSBasicObject *)resolvedObject {return self;}

- (void)setBundle:(NSBundle *)aBundle {
    if(aBundle != nil && aBundle != bundle) {
        [bundle release];
        bundle = [aBundle retain];
    }
}

- (NSBundle *)bundle {
    NSBundle *b = bundle;
    if (!b) b = [QSReg bundleForClassName:[self identifier]];
    return b;
}

@end