
#import <Foundation/Foundation.h>
#import <QSCrucible/QSBasicObject.h>

@protocol QSObject, QSObjectRanker;
@class QSObject, QSBasicObject;

extern NSSize QSMaxIconSize;

@protocol QSObjectHandler <NSObject>
- (BOOL)loadIconForObject:(QSObject *)object;
- (void)setQuickIconForObject:(QSObject *)object;
- (BOOL)objectHasChildren:(QSObject *)object;
- (BOOL)objectHasValidChildren:(QSObject *)object;
- (NSArray *)childrenForObject:(QSObject *)object;
- (QSObject *)parentOfObject:(QSObject *)object;
- (NSString *)detailsOfObject:(QSObject *)object;
- (NSString *)identifierForObject:(QSObject *)object;
- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped;
- (BOOL)loadChildrenForObject:(QSObject *)object;
- (NSString *)kindOfObject:(id <QSObject>)object;
- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type;
@end

// meta dictionary keys
#define kQSObjectPrimaryName ((NSString *)kMDItemTitle)

#define kQSObjectAlternateName ((NSString *)kMDItemHeadline)
#define kQSObjectPrimaryType @"QSObjectType"
#define kQSObjectIconName @"QSObjectIconName"

#define kQSObjectDefaultAction @"QSObjectDefaultAction"

#define kQSObjectObjectID ((NSString *)kMDItemIdentifier)
#define kQSObjectParentID @"QSObjectParentID"
#define kQSObjectDetails @"QSObjectDetails"
#define kQSObjectKind @"QSObjectKind"
#define kQSObjectSource @"QSObjectSource"
#define kQSObjectCreationDate ((NSString *)kMDItemContentCreationDate)
#define kQSStringEncoding @"QSStringEncoding"

#define kMeta @"metadata"
#define kData @"data"

// cache dictionary keys
#define kQSObjectIcon @"QSObjectIcon"
#define kQSObjectChildren @"QSObjectChildren"
#define kQSObjectAltChildren @"QSObjectAltChildren"
#define kQSObjectChildrenLoadDate @"QSObjectChildrenLoadDate"
#define kQSContents @"QSObjectContents"
#define kQSObjectComponents @"QSObjectComponents"

typedef struct _QSObjectFlags {
    unsigned int        multiTyped:1;
    unsigned int        iconLoaded:1;
    unsigned int        childrenLoaded:1;
    unsigned int        contentsLoaded:1;
    unsigned int        noIdentifier:1;
    unsigned int        isProxy:1;
    unsigned int        retainsIcon:1;
	//  NSCellType          type:2;
} QSObjectFlags;

@interface QSObject : QSBasicObject <NSCopying> {
	NSString *name;
	NSString *label;
	NSString *identifier;
	NSImage *icon;
	NSString *primaryType;
	id primaryObject;
	
	NSMutableDictionary *	meta;		//Name, Label, Type, Identifier, Source, embedded details
	NSMutableDictionary *	data;		//Data or typed dictionary (multiTyped Object)
	NSMutableDictionary *	cache;		//Icons, children, alias data, 
	QSObjectFlags			flags;
    NSTimeInterval			lastAccess;
}
+ (void)cleanObjectDictionary;
+ (void)purgeOldImagesAndChildren;
+ (void)purgeAllImagesAndChildren;
+ (void)purgeImagesAndChildrenOlderThan:(NSTimeInterval)interval;
+ (void)purgeIdentifiers;

+ (void)registerObject:(QSBasicObject *)object withIdentifier:(NSString *)anIdentifier;

+ (id)objectWithName:(NSString *)aName;
+ (id)objectWithIdentifier:(NSString *)anIdentifier;
+ (id)makeObjectWithIdentifier:(NSString *)anIdentifier;

- (id)init;

- (BOOL)isEqual:(id)anObject;

- (NSString *)guessPrimaryType;
- (NSArray *)splitObjects;

- (NSArray *)allKeys;

- (NSArray *)decodedTypes;

- (id)handlerForType:(NSString *)type selector:(SEL)selector;
- (id)handlerForSelector:(SEL)selector;

- (id)objectForType:(id)aKey;
- (void)setObject:(id)object forType:(id)aKey;

- (id)objectForCache:(id)aKey;
- (void)setObject:(id)object forCache:(id)aKey;

- (id)objectForMeta:(id)aKey;
- (void)setObject:(id)object forMeta:(id)aKey;

- (NSMutableDictionary *)cache;
- (void)setCache:(NSMutableDictionary *)aCache;


@end

@interface QSObject (Hierarchy)
- (void)setParentID:(NSString *)parentID;
- (void)setChildren:(NSArray *)newChildren;
- (void)setAltChildren:(NSArray *)newAltChildren;

- (void)loadChildren;
- (BOOL)unloadChildren;

- (BOOL)childrenValid;

- (BOOL)childrenLoaded;
- (void)setChildrenLoaded:(BOOL)flag;
@end

//Standard Accessors
@interface QSObject (Accessors)
- (void)setIdentifier:(NSString *)newIdentifier;
- (void)setName:(NSString *)newName;
- (void)setLabel:(NSString *)newLabel;
- (void)setDetails:(NSString *)newDetails;

- (void)setPrimaryType:(NSString *)newPrimaryType;

- (NSMutableDictionary *)dataDictionary;
- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary;

- (void)setIconLoaded:(BOOL)flag;
- (BOOL)retainsIcon;
- (void)setRetainsIcon:(BOOL)flag;
- (BOOL)contentsLoaded;
- (void)setContentsLoaded:(BOOL)flag;
- (NSTimeInterval)childrenLoadedDate;
- (void)setChildrenLoadedDate:(NSTimeInterval)newChildrenLoadedDate;
///- (id)contents;
///- (void)setContents:(id)newContents;
//- (NSTimeInterval)lastUseDate;
//- (void)setLastUseDate:(NSTimeInterval)newLastUseDate;
@end

