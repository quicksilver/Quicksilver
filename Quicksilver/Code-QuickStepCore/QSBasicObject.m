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


#pragma mark QSObject Protocol
- (NSString *)identifier {return nil;}
- (NSString *)label {return nil;}
- (NSString *)additionalSearchContext { return @""; }
- (NSString *)name {return @"Object";}
- (BOOL)enabled {return ![[QSLibrarian sharedInstance] itemIsOmitted:self];}
- (void)setEnabled:(BOOL)flag {[[QSLibrarian sharedInstance] setItem:self isOmitted:!flag];}
- (id)primaryObject {return nil;}
- (BOOL)loadIcon {return YES;}
- (BOOL)iconLoaded {return YES;}
- (void)setBundle:(NSBundle *)aBundle {
    if(aBundle != nil && aBundle != bundle) {
        bundle = aBundle;
    }
}
- (NSBundle *)bundle {
    NSBundle *b = bundle;
    if (!b) b = [QSReg bundleForClassName:[self identifier]];
    return b;
}

#pragma mark QSObjectHierarchy Protocol
- (id <QSObjectHierarchy>)parent { return nil; }
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

- (NSUInteger)primaryCount {return 0;}

- (NSImage *)icon {
	return [QSResourceManager imageNamed:@"Object"];
}
- (NSComparisonResult)compare:(id)other {
	return [[self name] compare:[(QSObject *)other name]];
}

- (NSImage *)loadedIcon {
	if (![self iconLoaded]) [self loadIcon];
	return [self icon];
}
- (void)becameSelected { return; }

- (id)this { return self; }

- (id)thisWithIcon { return self; };

- (NSString *)displayName {return [self name];}
- (NSString *)details {return nil;}
- (NSString *)toolTip {return nil;}
- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped {return NO;}

- (NSString *)description {return [NSString stringWithFormat:@"%@ <%p>, %@", NSStringFromClass([self class]), self, [self identifier]];}
@end

@implementation QSBasicObject (QSPasteboard)
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard {
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
    ranker = nil;
	[self ranker];
}

- (CGFloat)score { return 0.0f; }

- (NSInteger)order { return NSNotFound; }

- (NSComparisonResult)nameCompare:(QSBasicObject*)object {
	return [[self name] caseInsensitiveCompare:[object name]];
}

- (NSComparisonResult)scoreCompare:(QSBasicObject*)compareObject {
	return NSOrderedSame;
}
@end
