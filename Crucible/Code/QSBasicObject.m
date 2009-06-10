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
		ranker = nil;
    }
    return self;
}

- (void)dealloc {
	[ranker release];
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
/* TODO: Check differences between this and the branch
 * Issues: the ranker won't notice its object changed
 */
- (Class)rankerClass {
	return [QSDefaultObjectRanker class];
}

- (id <QSObjectRanker>)ranker {
	if (!ranker)
        ranker = [[[self rankerClass] rankerForObject:self] retain];
	return ranker;
}

- (void)updateMnemonics {
    id oldRanker = ranker;
    ranker = nil;
    [oldRanker release];
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

- (BOOL)containsType:(NSString *)aType {
	return [[self types] containsObject:aType];
}

- (NSEnumerator *)enumeratorForType:(NSString *)aKey { return [[self arrayForType:aKey] objectEnumerator]; }

- (NSUInteger)count { return 0; }

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
