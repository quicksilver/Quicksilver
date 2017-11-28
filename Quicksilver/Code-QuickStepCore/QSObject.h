#import <Foundation/Foundation.h>

#import <QSCore/QSBasicObject.h>
#import <QSCore/QSObjectHandler.h>

@class QSObject, QSBasicObject;

extern NSSize QSMaxIconSize;

// meta dictionary keys
#define kQSObjectPrimaryName      @"QSObjectName"
#define kQSObjectAlternateName    @"QSObjectLabel"
#define kQSObjectPrimaryType      @"QSObjectType"
#define kQSObjectSource           @"QSObjectSource"
#define kQSObjectIconName         @"QSObjectIconName"
#define kQSObjectBundle           @"QSObjectBundle"

#define kQSObjectDefaultAction    @"QSObjectDefaultAction"

#define kQSObjectObjectID         @"QSObjectObjectID"
#define kQSObjectParentID         @"QSObjectParentID"
#define kQSObjectDetails          @"QSObjectDetails"
#define kQSObjectKind             @"QSObjectKind"
#define kQSObjectSource           @"QSObjectSource"
#define kQSObjectCreationDate     @"QSObjectCreationDate"
#define kQSStringEncoding         @"QSStringEncoding"
// #define METAKEYS [NSArray arrayWithObjects:

#define kMeta                     @"properties"
#define kData                     @"data"


// cache dictionary keys
#define kQSObjectIcon             @"QSObjectIcon"
#define kQSObjectChildren         @"QSObjectChildren"
#define kQSObjectAltChildren      @"QSObjectAltChildren"
#define kQSObjectChildrenLoadDate @"QSObjectChildrenLoadDate"
#define kQSContents               @"QSObjectContents"
#define kQSObjectComponents       @"QSObjectComponents"

@interface QSObject : QSBasicObject <NSCopying, NSCoding> {
	NSMutableDictionary *data QS_DEPRECATED; /* Temporary */
}

+ (instancetype)objectWithName:(NSString *)aName;
+ (instancetype)objectWithIdentifier:(NSString *)anIdentifier QS_DEPRECATED;
+ (instancetype)makeObjectWithIdentifier:(NSString *)anIdentifier;

@property (copy) NSString *identifier;
@property (copy) NSString *name;
@property (copy) NSString *label;
@property (copy) NSString *details;
@property (copy) NSString *primaryType;

@property (readonly) NSString *kind;
@property (readonly) NSString *displayName;
@property (readonly) NSString *toolTip;
@property (retain) id primaryObject;

/** Hierarchy */

@property (readonly) QSObject *parent;
@property (copy) NSArray *children;
@property (copy) NSArray *altChildren;

- (void)setParentID:(NSString *)parentID;

- (BOOL)hasChildren;
- (void)loadChildren;
- (BOOL)unloadChildren;

- (BOOL)childrenLoaded;
- (BOOL)childrenValid;

@property NSTimeInterval childrenLoadedDate;

@property BOOL contentsLoaded; /* FIXME: Unused */

/** Icons */

@property (retain) NSImage *icon;
@property BOOL retainsIcon;
@property (readonly) BOOL iconLoaded;

- (BOOL)loadIcon;
- (BOOL)unloadIcon;

/** Type-handling */

- (NSArray *)types;
- (NSArray *)decodedTypes;

- (id <QSObjectHandler>)handler;
- (id <QSObjectHandler>)handlerForType:(NSString *)type selector:(SEL)selector;

/** Low-level access */

- (id)objectForMeta:(id)aKey;
- (void)setObject:(id)object forMeta:(id)aKey;
- (id)objectForType:(id)aKey;
- (void)setObject:(id)object forType:(id)aKey;
- (id)objectForCache:(id)aKey;
- (void)setObject:(id)object forCache:(id)aKey;

@property (retain) NSMutableDictionary *meta;  // Name, Label, Type, Identifier, Source, embedded details
@property (retain) NSMutableDictionary *data;  // Data or typed dictionary (multiTyped Object)
@property (retain) NSMutableDictionary *cache; // Icons, children, alias data,

/** Archiving */

+ (instancetype)objectFromFile:(NSString *)path;
- (instancetype)initFromFile:(NSString *)path;
- (void)writeToFile:(NSString *)path;

- (void)extractMetadata;
@end

@interface QSObject (QSCollection)

+ (instancetype)objectByMergingObjects:(NSArray *)objects withObject:(QSObject *)object;
+ (instancetype)objectByMergingObjects:(NSArray *)objects;

@property (readonly) NSUInteger count;
@property (readonly) NSUInteger primaryCount;

- (NSArray *)splitObjects;

@end

@interface QSObject (QSProxySupport)

- (BOOL)isProxyObject;
- (QSObject *)resolvedObject;

// This private method is required for QSProxyObject.m
- (id)_safeObjectForType:(id)aKey;

@end

@interface QSObject (QSDeprecated)
- (NSMutableDictionary *)dataDictionary QS_DEPRECATED_MSG("use -data");
- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary QS_DEPRECATED_MSG("use -setData");;
@end
