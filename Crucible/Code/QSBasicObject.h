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

#define kQSObjectClass @"class"

// QSObject Protocols -  right now these aren't sufficient. QSBasicObject must be subclassed
@protocol QSRanking
- (Class)rankerClass;
- (id <QSObjectRanker>)ranker;
- (void)updateMnemonics;

- (float)score;
- (int)order;
- (float)rankModification;
@end

@protocol QSObjectHierarchy
- (QSBasicObject *)parent;
- (BOOL)hasChildren;
- (NSArray *)children;
- (NSArray *)altChildren;
- (NSArray *)siblings;
- (NSArray *)altSiblings;
@end

@protocol QSTyping
- (NSString *)primaryType;
- (id)primaryObject;

- (NSArray *)types;
- (id)objectForType:(id)aType;

- (NSArray *)arrayForType:(id)aKey;
- (BOOL)containsType:(NSString *)aType;
- (NSEnumerator *)enumeratorForType:(NSString *)aKey;
@end

@protocol QSCoding
+ (id)objectWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;
@end

@protocol QSIcon
- (NSImage *)icon;
- (void)setIcon:(NSImage *)newIcon;

- (void)loadIcon;
- (BOOL)unloadIcon;

- (BOOL)iconLoaded;

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped;
@end

@protocol QSObject <QSRanking, QSCoding, QSTyping, QSIcon, QSObjectHierarchy>
- (NSString *)identifier;
- (NSString *)name; /** < The object name */
- (NSString *)label; /** < An alternate name for the object */
- (NSString *)displayName; /** < The label, or the name if unavailable */
- (NSString *)details; /** < Additional information about the object */
- (NSString *)kind; /** < Human-readable type */

- (NSImage *)icon;

- (NSUInteger)count;

- (NSBundle *)bundle;
- (void)setBundle:(NSBundle *)bundle;

- (id)handler;
@end

@interface QSBasicObject : NSObject <QSObject> {
@public
	NSObject <QSObjectRanker> *ranker;
    NSBundle                  *bundle;
}


- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;

- (NSComparisonResult)nameCompare:(QSBasicObject *)object;

/* TODO: I'm pretty sure a good amount of cleanup would make the following redundant */
- (QSBasicObject *)resolvedObject;

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes;

- (void)becameSelected;

- (void)setOmitted:(BOOL)flag;
@end
