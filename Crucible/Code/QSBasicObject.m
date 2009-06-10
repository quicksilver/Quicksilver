/*
 Copyright 2007 Blacktree, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "QSBasicObject.h"

@implementation QSBasicObject

- (id)init {
    if ((self = [super init]) ) {
		rankData = nil;
		ranker = nil;
    }
    return self;
}

- (void)dealloc {
	[ranker release];
    [rankData release];
    [super dealloc];
}

- (NSString *)label { return nil; }
- (NSString *)name { return @"Object"; }
- (NSString *)identifier { return nil; }
- (NSString *)displayName { return [self name]; }
- (NSString *)details { return nil; }
- (NSString *)kind { return @"Object"; }
- (NSString *)toolTip { return nil; }

#pragma mark Catalog managment
- (void)setEnabled:(BOOL)flag {
	[QSLib setItem:self isOmitted:!flag]; 	
}

- (BOOL)enabled {
	return ![QSLib itemIsOmitted:self]; 	
}

- (void)setOmitted:(BOOL)flag {
	[[self ranker] setOmitted:flag];
}

#pragma mark Ranking primitives
- (float)score { return 0.0; }

- (int)order { return NSNotFound; }

- (float)rankModification { return 0; }

#pragma mark Ranking system
- (QSRankInfo *)getRankData {
	QSRankInfo *oldRankData;
	oldRankData = rankData;
	rankData = [[QSRankInfo rankDataWithObject:self] retain];
	[oldRankData release];
	return rankData;
}

- (id <QSObjectRanker>)getRanker {
	id oldRanker;
	oldRanker = ranker;
	ranker = [[QSDefaultObjectRanker alloc] initWithObject:self];
	[oldRanker release];
	return ranker;
}

- (id <QSObjectRanker>)ranker {
	if (!ranker) return [self getRanker];
	return ranker;
}

- (void)updateMnemonics {
	[self getRanker];
}

#pragma mark Icon
- (BOOL)loadIcon { return YES; }
- (BOOL)iconLoaded { return YES; }
- (NSImage *)icon {
    return [NSImage imageNamed:@"Object"];

}
- (NSImage *)loadedIcon {
	if (![self iconLoaded]) [self loadIcon];
	return [self icon];
}

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped { return NO; }

#pragma mark Comparison
- (NSComparisonResult)compare:(id)other {
	return [[self name] compare:[other name]];
}
- (NSComparisonResult)scoreCompare:(QSBasicObject *)object { return NSOrderedSame; }
- (NSComparisonResult)nameCompare:(QSBasicObject *)object {
    return [[self name] caseInsensitiveCompare:[object name]];  
}

#pragma mark Type handling
- (NSString *)primaryType { return nil; }
- (id)primaryObject { return nil; }

- (NSArray *)types { return nil; }
- (id)objectForType:(id)aKey { return nil; }
- (NSArray *)arrayForType:(id)aKey { return nil; }

- (int)primaryCount { return 0; }

- (BOOL)containsType:(NSString *)aType {
	return [[self types] containsObject:aType];
}

- (NSEnumerator *)enumeratorForType:(NSString *)aKey { return [[self arrayForType:aKey] objectEnumerator]; }

#pragma mark Hierarchy
- (QSBasicObject *)parent { return nil; }

- (BOOL)hasChildren { return NO; }
- (NSArray *)children { return nil; }
- (NSArray *)altChildren { return nil; }
- (NSArray *)siblings { return [[self parent] children]; }
- (NSArray *)altSiblings {return [[self parent] altChildren];}

#pragma mark Proxying
- (QSBasicObject *)resolvedObject {return self;}
- (QSBasicObject *)object {return self;}

- (void)becameSelected { return; }

#pragma mark Pasteboard handling
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard {
    return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:nil];
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes {
    return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:includeTypes];
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes {
    return NO;
}

#pragma mark Debugging
- (NSString *)description { return [super description]; }

@end

@implementation QSRankInfo
+ (id)rankDataWithObject:(QSBasicObject *)object {
	return [[[self alloc] initWithObject:object] autorelease];
}

- (id)initWithObject:(QSBasicObject *)object {
	if ((self = [super init])) {
		NSString *theIdentifier = [object identifier];
		name = [[QSDefaultStringRanker alloc] initWithString:[object name]];
		label = [[QSDefaultStringRanker alloc] initWithString:[object label]];
		[self setIdentifier:theIdentifier];
		[self setMnemonics:[[QSMnemonics sharedInstance] objectMnemonicsForID:identifier]];
		[self setOmitted:[QSLib itemIsOmitted:object]];
    }
    return self;
}

- (void)dealloc {
    [name release];
    [label release];
    [mnemonics release];
    [identifier release];
    [super dealloc];
}

- (NSString *)identifier { return [[identifier retain] autorelease]; }

- (void)setIdentifier:(NSString *)anIdentifier {
    if (identifier != anIdentifier) {
        [identifier release];
        identifier = [anIdentifier retain];
    }
}

- (NSString *)name { return [[name retain] autorelease]; }

- (void)setName:(NSString *)aName {
    if (name != aName) {
        [name release];
		
		name = [[QSDefaultStringRanker alloc] initWithString:aName];
    }
}

- (NSString *)label { return [[label retain] autorelease];  }

- (void)setLabel:(NSString *)aLabel {
    if (label != aLabel) {
        [label release];
		label = [[QSDefaultStringRanker alloc] initWithString:aLabel];
    }
}


- (NSDictionary *)mnemonics { return [[mnemonics retain] autorelease];  }

- (void)setMnemonics:(NSDictionary *)aMnemonics {
    if (mnemonics != aMnemonics) {
        [mnemonics release];
        mnemonics = [aMnemonics retain];
    }
}

- (BOOL)omitted { return omitted; }
- (void)setOmitted:(BOOL)flag {
	omitted = flag;
}

@end
