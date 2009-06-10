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

#import <Cocoa/Cocoa.h>

@class QSBasicObject;
@protocol QSObjectRanker;

// QSObject Protocols -  right now these aren't sufficient. QSBasicObject must be subclassed
@protocol QSObject
- (NSString *)label;
- (NSString *)name;

- (BOOL)loadIcon;
- (BOOL)iconLoaded;
- (NSImage *)icon;

- (NSString *)primaryType;
- (id)primaryObject;

- (NSArray *)types;
- (id)objectForType:(id)aType;
- (NSArray *)arrayForType:(id)aKey;
@end

@protocol QSObjectHierarchy
- (QSBasicObject *)parent;
- (BOOL)hasChildren;
- (NSArray *)children;
- (NSArray *)altChildren;
- (NSArray *)siblings;
- (NSArray *)altSiblings;
@end

@interface QSBasicObject : NSObject <QSObject, QSObjectHierarchy> {
@public
	NSObject <QSObjectRanker> *ranker;
}

- (NSString *)identifier;
- (NSString *)displayName;
- (NSString *)details;
- (NSString *)kind;
- (NSString *)toolTip;

- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;

- (float)score;
- (int)order;
- (float)rankModification;

- (Class)rankerClass;
- (id <QSObjectRanker>)ranker;
- (void)updateMnemonics;

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped;

- (NSComparisonResult)nameCompare:(QSBasicObject *)object;

- (int)primaryCount;
- (BOOL)containsType:(NSString *)aType;
- (NSEnumerator *)enumeratorForType:(NSString *)aKey;

/* TODO: I'm pretty sure a good amount of cleanup would make the following redundant */
- (QSBasicObject *)resolvedObject;

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes;

- (void)becameSelected;

- (void)setOmitted:(BOOL)flag;
@end