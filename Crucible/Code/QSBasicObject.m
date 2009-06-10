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
        bundle = nil;
    }
    return self;
}

- (void)dealloc {
	[ranker release];
    [super dealloc];
}

- (NSString *)description {return [NSString stringWithFormat:@"%@ <%p>, %@", NSStringFromClass([self class]), self, [self identifier]];}

#pragma mark QSCoding protocol
+ (id)objectWithDictionary:(NSDictionary *)dict {
    NSString *className = [dict objectForKey:kQSObjectClass];
    if (!className)
        [NSException raise:NSInternalInconsistencyException format:@"Missing kQSObjectClass key"];
    
    Class class = NSClassFromString(className);
    if (!class)
        [NSException raise:NSInternalInconsistencyException format:@"Unknown class %@ in runtime", className];
    
    return [[[class alloc] initWithDictionary:dict] autorelease];
}


- (id)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
    if (self) {
        
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:NSStringFromClass([self class]) forKey:kQSObjectClass];
    return dict;
}

#pragma mark QSObject protocol
- (NSString *)identifier { return nil; }
- (NSString *)name { return @"Object"; }
- (NSString *)label { return nil; }

- (NSString *)displayName {
    if (![self label])
        return [self name];
    return [self label];
}

- (NSString *)details { return nil; }
- (NSString *)kind { return @"Object"; }

- (NSUInteger)count { return 0; }

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

- (id)handler { return nil; }

#pragma mark QSRanking protocol
/* FIXME: The ranker won't notice its object changed */

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

- (float)score { return 0.0; }

- (int)order { return NSNotFound; }

- (float)rankModification { return 0; }

#pragma mark QSIcon protocol
- (NSImage *)icon {
    return [NSImage imageNamed:@"Object"];
}

- (void)setIcon:(NSImage *)icon { return; }

- (void)loadIcon { return; }
- (BOOL)unloadIcon { return NO; }

- (BOOL)iconLoaded { return YES; }

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped { return NO; }

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

#pragma mark Comparison
- (NSComparisonResult)compare:(id)other {
	return [[self name] compare:[other name]];
}
- (NSComparisonResult)scoreCompare:(QSBasicObject *)object { return NSOrderedSame; }
- (NSComparisonResult)nameCompare:(QSBasicObject *)object {
    return [[self name] caseInsensitiveCompare:[object name]];  
}

#pragma mark QSTyping protocol
- (NSString *)primaryType { return nil; }
- (id)primaryObject { return nil; }

- (NSArray *)types { return nil; }
- (id)objectForType:(id)aKey { return nil; }
- (NSArray *)arrayForType:(id)aKey { return nil; }

- (BOOL)containsType:(NSString *)aType {
	return [[self types] containsObject:aType];
}

- (NSEnumerator *)enumeratorForType:(NSString *)aKey { return [[self arrayForType:aKey] objectEnumerator]; }

#pragma mark QSObjectHierarchy protocol
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

@end