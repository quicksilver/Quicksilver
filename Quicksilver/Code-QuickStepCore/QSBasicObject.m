//
//  QSBasicObject.m
//  Quicksilver
//
//  Created by Etienne on 13/09/08.
//  Copyright 2008 Etienne Samson. All rights reserved.
//

#import "QSBasicObject.h"

@implementation QSBasicObject
#pragma mark Lifecycle
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

#pragma mark QSObject Protocol
- (NSString *)identifier {return nil;}
- (NSString *)label {return nil;}
- (NSString *)name {return @"Object";}
- (BOOL)enabled {return ![QSLib itemIsOmitted:self];}
- (void)setEnabled:(BOOL)flag {[QSLib setItem:self isOmitted:!flag];}
- (id)primaryObject {return nil;}
- (BOOL)loadIcon {return YES;}
- (BOOL)iconLoaded {return YES;}
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

#pragma mark QSObjectHierarchy Protocol
- (QSBasicObject *)parent { return nil; }
- (BOOL)hasChildren { return NO; }
- (NSArray *)children { return nil; }
- (NSArray *)altChildren { return nil; }
- (NSArray *)siblings { return [[self parent] children]; }
- (NSArray *)altSiblings {return [[self parent] altChildren];}

#pragma mark QSObjectTyping
- (NSString *)primaryType {return nil;}
- (NSArray *)types {return nil;}
- (id)objectForType:(id)aKey {return nil;}
- (NSArray *)arrayForType:(id)aKey {return nil;}
- (NSEnumerator *)enumeratorForType:(NSString *)aKey {return [[self arrayForType:aKey] objectEnumerator];}

- (NSString *)kind {
	return @"Object";
}

- (BOOL)containsType:(NSString *)aType {
	return [[self types] containsObject:aType];
}

- (int) primaryCount {return 0;}

- (NSImage *)icon {
	return [NSImage imageNamed:@"Object"];
}
- (NSComparisonResult)compare:(id)other {
	return [[self name] compare:[other name]];
}

- (NSImage *)loadedIcon {
	if (![self iconLoaded]) [self loadIcon];
	return [self icon];
}
- (void)becameSelected { return; }

- (NSString *)displayName {return [self name];}
- (NSString *)details {return nil;}
- (NSString *)toolTip {return nil;}
- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped {return NO;}

- (NSString *)description {return [NSString stringWithFormat:@"%@ <%p>, %@", NSStringFromClass([self class]), self, [self identifier]];}

- (QSBasicObject *)resolvedObject {return self;}
@end

@implementation QSBasicObject (QSPasteboard)
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard {
	return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:nil];
}
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes {
	return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:includeTypes];
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes {
	return NO;
}
@end

@implementation QSBasicObject (QSRanking)
- (Class)getRanker { return [QSDefaultObjectRanker class]; }

- (NSObject <QSObjectRanker> *)ranker {
    if (!ranker)
        ranker = [[[self getRanker] alloc] initWithObject:self];
	return ranker;
}

- (void)updateMnemonics {
	[ranker release];
    ranker = nil;
	[self ranker];
}

- (float)score { return 0.0f; }

- (int)order { return NSNotFound; }

- (NSComparisonResult)nameCompare:(QSBasicObject*)object {
	return [[self name] caseInsensitiveCompare:[object name]];
}

- (NSComparisonResult)scoreCompare:(QSBasicObject*)compareObject {
	return NSOrderedSame;
}
@end