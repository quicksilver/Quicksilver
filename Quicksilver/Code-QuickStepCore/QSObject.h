#import <Foundation/Foundation.h>

#import <QSCore/QSBasicObject.h>
#import <QSCore/QSObjectHandler.h>
#import <QSFoundation/QSThreadSafeMutableDictionary.h>

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
#define kCatalogSource            @"catalogSource"

// cache dictionary keys
#define kQSObjectIcon             @"QSObjectIcon"
#define kQSObjectChildren         @"QSObjectChildren"
#define kQSObjectAltChildren      @"QSObjectAltChildren"
#define kQSObjectChildrenLoadDate @"QSObjectChildrenLoadDate"
#define kQSContents               @"QSObjectContents"
#define kQSObjectComponents       @"QSObjectComponents"
#define kQSIsCombinedObject		  @"QSIsCombinedObject"

typedef struct _QSObjectFlags {
	unsigned int		multiTyped:1;
	unsigned int		iconLoaded:1;
	unsigned int		childrenLoaded:1;
	unsigned int		contentsLoaded:1;
	unsigned int		noIdentifier:1;
	unsigned int		isProxy:1;
	//  NSCellType		  type:2;
} QSObjectFlags;



@interface QSObject : QSBasicObject <NSCopying, NSCoding> {
	NSString *name;
	NSString *label;
	NSString *identifier;
	NSImage *icon;
	NSString *primaryType;
	id primaryObject;

	NSMutableDictionary *	meta; 		//Name, Label, Type, Identifier, Source, embedded details
	NSMutableDictionary *	data; 		//Data or typed dictionary (multiTyped Object)
	QSThreadSafeMutableDictionary *cache; 		//Icons, children, alias data,
	QSObjectFlags			flags;

}
+ (void)initialize;
+ (void)purgeAllImagesAndChildren;
+ (void)interfaceChanged;

+ (id)objectWithName:(NSString *)aName;
+ (id)objectWithIdentifier:(NSString *)anIdentifier __attribute__((deprecated));
+ (id)makeObjectWithIdentifier:(NSString *)anIdentifier;
+ (id)objectByMergingObjects:(NSArray *)objects;
+ (id)objectByMergingObjects:(NSArray *)objects withObject:(QSObject *)object;

- (id)init;
- (void)dealloc;
- (BOOL)isEqual:(id)anObject;
- (NSString *)guessPrimaryType;
- (NSArray *)splitObjects;
- (NSString *)displayName;
- (NSString *)toolTip;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(NSUInteger)level;
- (NSString *)details;
- (id)primaryObject;

- (NSUInteger) count;
- (NSUInteger) primaryCount;
- (NSArray *)types;
- (NSArray *)decodedTypes;
- (id <QSObjectHandler>)handler;
- (id <QSObjectHandler>)handlerForType:(NSString *)type selector:(SEL)selector;
- (id)objectForType:(id)aKey;
- (void)setObject:(id)object forType:(id)aKey;
- (id)objectForCache:(id)aKey;
- (void)setObject:(id)object forCache:(id)aKey;
- (id)objectForMeta:(id)aKey;
- (void)setObject:(id)object forMeta:(id)aKey;

- (void)setDetails:(NSString *)newDetails;

- (NSMutableDictionary *)cache;
- (void)setCache:(NSMutableDictionary *)aCache;
- (BOOL)isProxyObject;
- (QSObject *)resolvedObject;

// This private method is required for QSProxyObject.m
- (id)_safeObjectForType:(id)aKey;

@end

@interface QSObject (Icon)
- (BOOL)loadIcon;
- (BOOL)unloadIcon;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)newIcon;
- (void)updateIcon:(NSImage *)newIcon __attribute__((deprecated("Use -setIcon:")));
@end

@interface QSObject (Hierarchy)
- (QSObject *) parent;
- (void)setParentID:(NSString *)parentID;
- (BOOL)childrenValid;
- (BOOL)unloadChildren;
- (void)loadChildren;
- (BOOL)hasChildren;
@end

@interface QSObject (Archiving)
+ (id)objectFromFile:(NSString *)path;
- (id)initFromFile:(NSString *)path;
- (void)writeToFile:(NSString *)path;
- (void)extractMetadata;
@end



//Standard Accessors
@interface QSObject (Accessors)
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;
- (NSString *)name;
- (void)setName:(NSString *)newName;
- (NSArray *)children;
- (void)setChildren:(NSArray *)newChildren;
- (NSArray *)altChildren;
- (void)setAltChildren:(NSArray *)newAltChildren;
- (NSString *)label;
- (void)setLabel:(NSString *)newLabel;
- (NSString *)primaryType;
- (void)setPrimaryType:(NSString *)newPrimaryType;
- (NSMutableDictionary *)dataDictionary;
- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary;

- (BOOL)iconLoaded;
- (void)setIconLoaded:(BOOL)flag;
- (BOOL)childrenLoaded;
- (void)setChildrenLoaded:(BOOL)flag;
- (BOOL)contentsLoaded;
- (void)setContentsLoaded:(BOOL)flag;
- (NSTimeInterval)childrenLoadedDate;
- (void)setChildrenLoadedDate:(NSTimeInterval)newChildrenLoadedDate;

@end


//
//AEDescriptorValue:
//AEDescriptorForFlavor:
//PasteboardDataForType:

/*
- (id)handler;
- (id)handlerForType:(NSString *)type selector:(SEL)selector;
- (id)valueForFlavor:(id)aKey;
- (void)setValue:(id)object forFlavor:(id)aKey;
- (id)objectForCache:(id)aKey;
- (void)setObject:(id)object forCache:(id)aKey;
- (id)objectForMeta:(id)aKey;
- (void)setObject:(id)object forMeta:(id)aKey;

*/


