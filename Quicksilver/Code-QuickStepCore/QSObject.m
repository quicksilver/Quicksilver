#import "QSObject.h"
#import "QSLibrarian.h"
#import "QSDebug.h"
#import "QSObjectHandler.h"

// Currently unused import, intentionally left here to ensure swift continues to compile
// while pending more work.
#import <QSCore/QSCore-Swift.h>

static NSMutableSet *iconLoadedSet;
static NSMutableSet *childLoadedSet;

BOOL QSObjectInitialized = NO;

NSSize QSMaxIconSize;

@implementation QSObject
+ (void)initialize {
	if (!QSObjectInitialized) {
		QSMaxIconSize = QSSizeMax;
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(interfaceChanged) name:QSInterfaceChangedNotification object:nil];
		[nc addObserver:self selector:@selector(purgeAllImagesAndChildren) name:QSReleaseAllCachesNotification object:nil];

	//	controller = [NSApp delegate];

		iconLoadedSet = [[NSMutableSet alloc] init];
		childLoadedSet = [[NSMutableSet alloc] init];
		QSObjectInitialized = YES;
	}
}
+ (void)purgeAllImagesAndChildren {
    NSSet *tempIconSet = nil;
    NSSet *tempChildSet = nil;

    // Make copies of the sets so we can purge them without bothering about threading
    // We're synchronizing on the class instance, since those are class-ivars
    @synchronized ([QSObject class]) {
        tempIconSet = [iconLoadedSet copy];
        tempChildSet = [childLoadedSet copy];
    }

	for (QSObject *obj in tempIconSet) {
			[obj unloadIcon];
	}
	for (QSObject *obj in tempChildSet) {
			[obj unloadChildren];
	}
}

+ (void)interfaceChanged {
	//QSMaxIconSize = [(QSInterfaceController *)[[NSApp delegate] interfaceController] maxIconSize];
	[self purgeAllImagesAndChildren];
	// if (VERBOSE) NSLog(@"newsize %f", QSMaxIconSize.width);
}

- (id)init {
	if (self = [super init]) {

		data = [QSThreadSafeMutableDictionary dictionaryWithCapacity:0];
		meta = [QSThreadSafeMutableDictionary dictionaryWithCapacity:0];
		cache = [QSThreadSafeMutableDictionary dictionaryWithCapacity:0];
		name = nil;
		label = nil;
		icon = nil;
		identifier = nil;
		primaryType = nil;
	}
	return self;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	self = [self init];

	[meta setDictionary:[coder decodeObjectForKey:@"meta"]];
	[data setDictionary:[coder decodeObjectForKey:@"data"]];
	[self extractMetadata];
	id dup = [QSLib objectWithIdentifier:[self identifier]];
	if (dup) return dup;
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    for (NSMutableDictionary *dict in @[data, meta]) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![key respondsToSelector:@selector(encodeWithCoder:)] || ![obj respondsToSelector:@selector(encodeWithCoder:)]) {
                [dict removeObjectForKey:key];
            }
        }];
    }
    [coder encodeObject:data forKey:kData];
    [coder encodeObject:identifier forKey:kItemID];
}

#pragma mark Instance methods

- (NSUInteger)hash
{
	return identifier.hash ^ data.hash;
}

- (BOOL)isEqual:(QSObject *)anObject {
	if (!anObject) return NO;
	if (self != anObject && [anObject isKindOfClass:[QSRankedObject class]]) {
		anObject = [(QSRankedObject *)anObject object];
	}
	if (self == anObject) return YES;
	if ([self class] != [anObject class]) {
		return NO;
	}
	NSString *otherIdentifier = anObject->identifier;
	if ((identifier || otherIdentifier) && [identifier isEqualToString:otherIdentifier]) {
		return YES;
	}
	if ((identifier && otherIdentifier) && ![identifier isEqualToString:otherIdentifier]) {
		return NO;
	}

	if ([self count] > 1) {
		if ([self count] != [anObject count]) {
			return NO;
		}
		
		NSSet *myObjects = [NSSet setWithArray:[self objectForCache:kQSObjectComponents]];
		NSSet *otherObjects = [NSSet setWithArray:
							   [anObject objectForCache:kQSObjectComponents]];
		if (![myObjects isEqualToSet:otherObjects]) {
			return NO;
		}
	} else {
		if (![data isEqualToDictionary:anObject->data]) {
			return NO;
		}
	}
	// test the meta dictionary for QSObjectName, QSObjectLabel - if they're not equal then return no
	if ([[meta objectForKey:kQSObjectAlternateName] isNotEqualTo:[anObject->meta objectForKey:kQSObjectAlternateName]] ||
		 [[meta objectForKey:kQSObjectPrimaryName] isNotEqualTo:[anObject->meta objectForKey:kQSObjectPrimaryName]] ) {
		return NO;
	}
	return YES;
}

+ (id)objectWithName:(NSString *)aName {
	QSObject *newObject = [[self alloc] init];
	[newObject setName:aName];
	return newObject;
}

+ (id)makeObjectWithIdentifier:(NSString *)anIdentifier {
    QSObject *object = [[QSObject alloc] init];
    [object setIdentifier:anIdentifier];
    return object;
}

+ (id)objectWithIdentifier:(NSString *)anIdentifier {
	return [QSLib objectWithIdentifier:anIdentifier];
}

+ (id)objectByMergingObjects:(NSArray *)objects withObject:(QSObject *)object {
	if ([objects containsObject:object] || !object)
		return [self objectByMergingObjects:objects];

	NSMutableArray *array = [objects mutableCopy];
	[array addObject:object];
	return [self objectByMergingObjects:array];
}

- (NSArray *)splitObjects {
    QSObject *object = [self resolvedObject];
	if ([object count] == 1) {
		return [NSArray arrayWithObject:object];
	}
	
	NSArray *splitObjects = [object objectForCache:kQSObjectComponents];
    
    if (!splitObjects) {
        splitObjects = [object children];
    }
    return splitObjects;
}

// Method to merge objects into a single 'combined' object
+ (id)objectByMergingObjects:(NSArray *)objects {
	// if there's only 1 object, just return it
	if ([objects count] == 1) {
		return [objects objectAtIndex:0];
	}
	NSMutableSet *typesSet = nil;
	
	// Dict to store each object's data
	NSMutableDictionary *combinedData = [NSMutableDictionary dictionary];
	NSString *type;
	NSMutableArray *array;
	// Set used to keep track of the objects already added
	NSMutableSet *setOfObjects = [[NSMutableSet alloc] init];

	// Make sure objects is immutable
	objects = [objects copy];

	// add each object from the list of objects to the combinedData dict
	for (id thisObject in objects) {
		if (!typesSet) {
			typesSet = [NSMutableSet setWithArray:[thisObject types]];
		}
		else {
			[typesSet intersectSet:[NSSet setWithArray:[thisObject types]]];
		}
		for(type in typesSet) {
			array = [combinedData objectForKey:type];
			if (!array) {
                [combinedData setObject:(array = [NSMutableArray array]) forKey:type];
            }
			
			[array addObjectsFromArray:[thisObject arrayForType:type]];
			// add the object to the setOfObjects to keep track of which objects we've added to combinedData
			[setOfObjects addObject:thisObject];
		}
	}
	
	// If there's still only 1 object (case: if the comma trick is used on the same object multiple times)
	if ([setOfObjects count] == 1) {
		return [objects objectAtIndex:0];
	}
	
    NSMutableArray *typesToRemove = [NSMutableArray array];
	for(type in combinedData) {
		if (![typesSet containsObject:type])
            [typesToRemove addObject:type];
	}
	
    [combinedData removeObjectsForKeys:typesToRemove];
	
	// Create the 'combined' object
	QSObject *object = [[QSObject alloc] init];
	[object setDataDictionary:combinedData];
    [object setObject:objects forCache:kQSObjectComponents];
	if ([combinedData objectForKey:QSFilePathType])
		// try to guess a name based on the file types
		[object guessName];
	else
		// fall back on setting a simple name
		[object setName:NSLocalizedString(@"Combined Objects", nil)];
	[object primaryType];
	return object;
}

- (void)dealloc {
	//NSLog(@"dealloc %x %@", self, [self name]);
    if ([self iconLoaded])
        [self unloadIcon];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self unloadChildren];
	 data = nil;
	 meta = nil;
	 cache = nil;

	 name = nil;
	 label = nil;
	 identifier = nil;
	 icon = nil;
	 primaryType = nil;
	 primaryObject = nil;

}

// !!! Andre Berg 20091008: adding a gdbDataFormatter method which can be easily used 
// as GDB data formatter, e.g. "<QSObject> {[$VAR gdbDataFormatter]}:s" will call it 
// and display the result. The advantage is that this formatter will go less out of scope

- (const char *) gdbDataFormatter {
	return [[NSString stringWithFormat:@"name: %@, label: %@, identifier: %@, primaryType: %@, primaryObject: %@, meta: %@, data: %@, cache: %@, icon: %@",
             (name ? name : @"nil"),
             (label ? label : @"nil"),
             (identifier ? identifier : @"nil"),
			 (primaryType ? primaryType : @"nil"),
			 (primaryObject ? primaryObject : @"nil"),
             (meta ? [meta descriptionInStringsFileFormat] : @"nil"),
             (data ? [data descriptionInStringsFileFormat] : @"nil"),
             (cache ? [cache descriptionInStringsFileFormat] : @"nil"),
             (icon ? [icon description] : @"nil")] UTF8String];
}

- (id)copyWithZone:(NSZone *)zone {
    QSObject *copy = [[[self class] allocWithZone:zone] init];
    
    copy.name = [name copy];
    copy.label = [label copy];
    copy.identifier = [identifier copy];
    copy.icon = [icon copy];
    copy.primaryType = [primaryType copy];
    copy.primaryObject = [primaryObject copy];
    
    copy.meta = [meta mutableCopy];
    copy.data = [data mutableCopy];
    copy.cache = [cache mutableCopy];
    
    copy.flags = flags;
    
    return copy;
}

- (void)setPrimaryObject:(id)obj {
    primaryObject = obj;
}

- (void)setMeta:(NSMutableDictionary *)obj {
    meta = obj;
}

- (void)setData:(NSMutableDictionary *)obj {
    data = obj;
}

- (void)setFlags:(QSObjectFlags)fl {
    flags = fl;
}

- (NSString *)displayName {
	return [self label] ? [self label] : [self name];
}

- (NSString *)toolTip {
#ifdef DEBUG
	return [NSString stringWithFormat:@"%@ (%p) \r%@\rTypes:\r\t%@", [self name] , self, [self details] , [[self decodedTypes] componentsJoinedByString:@"\r\t"]];
#endif
	return nil; //[self displayName];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(NSUInteger)level {
	return [data descriptionWithLocale:locale indent:level];
}

- (id <QSObjectHandler>)handlerForType:(NSString *)type selector:(SEL)selector {
	id __block handler = [[QSReg objectHandlers] objectForKey:type];
    if (!handler) {
        [[QSReg objectHandlers] enumerateKeysAndObjectsUsingBlock:^(NSString *handlerType, id anyHandler, BOOL *stop) {
            if ([handlerType isEqualToString:QSFilePathType] && ![self objectForType:QSFilePathType]) {
                // if we don't have a file path, don't use the file handler
                return;
            }
            if (UTTypeConformsTo((__bridge CFStringRef)type, (__bridge CFStringRef)handlerType) ||
                (UTTypeConformsTo((__bridge CFStringRef)handlerType, kUTTypeText) && UTTypeConformsTo((__bridge CFStringRef)type, kUTTypeText))) {
                handler = anyHandler;
                *stop = YES;
            }
        }];
    }
//    if(DEBUG && VERBOSE && handler == nil)
//        NSLog(@"No handler for type %@", type);
    
    return (selector == NULL ? handler : ([handler respondsToSelector:selector] ? handler : nil ));
}

- (id <QSObjectHandler>)handlerForSelector:(SEL)selector {
    return [self handlerForType:[self primaryType] selector:selector];
}

- (id <QSObjectHandler>)handler {
	return [self handlerForType:[self primaryType] selector:nil];
}

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped {
	id handler = nil;
	 if (handler = [self handlerForSelector:@selector(drawIconForObject:inRect:flipped:)]) {
		return [handler drawIconForObject:self inRect:rect flipped:flipped];
	}
	return NO;
}

- (void)setDetails:(NSString *)newDetails {
    [self setObject:newDetails forMeta:kQSObjectDetails];
}

- (NSString *)details {
	NSString *details = nil;

	// check the object handler for this type
    id handler = nil;
	if (handler = [self handlerForSelector:@selector(detailsOfObject:)]) {
		details = [handler detailsOfObject:self];
	}
    
    // check the cache
    if (!details) {
        details = [meta objectForKey:kQSObjectDetails];
    }
    
	if (details) return details;
    
    // no details from the handler or cache, so find them some other way and cache the result

	NSBundle *mybundle = [self bundle];
	// this is almost always (null) so test it first
	if (mybundle) {
		if (details) {
			details = [mybundle safeLocalizedStringForKey:details value:details table:@"QSObject.details"];
		} else {
			details = [mybundle safeLocalizedStringForKey:[self identifier] value:details table:@"QSObject.details"];
		}
	}
    if (details != nil) {
        [self setObject:details forMeta:kQSObjectDetails];
    } else if ([self stringValue]) {
        details = [self stringValue];
    } else if ([[data objectForKey:[self primaryType]] isKindOfClass:[NSString class]]) {
        details = [data objectForKey:[self primaryType]];
    }
    
	return details;
}

- (id)primaryObject {return [data objectForKey:[self primaryType]];}
	//- (id)objectForKey:(id)aKey {return [data objectForKey:aKey];}
	//- (void)setObject:(id)object forKey:(id)aKey {[data setObject:object forKey:aKey];}

- (id)_safeObjectForType:(id)aKey {
    return [data objectForKey:aKey];
#if 0
	if (flags.multiTyped)
		return[data objectForKey:aKey];
	else if ([[self primaryType] isEqualToString:aKey])
		return data;
	return nil;
#endif
}

- (id)objectForType:(id)aKey {
    aKey = QSUTIForAnyTypeString(aKey);
	id object = [self _safeObjectForType:aKey];
	if ([object isKindOfClass:[NSArray class]]) {
		if ([(NSArray *) object count] == 1) return [object lastObject];
	} else {
        if ([aKey isEqualToString:QSTextType] && [object isKindOfClass:[NSData class]]) {
            object = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        }
        return object;
    }
    // if the object for type: aKey is an array, we return 'nil' (not the actual array)
    // For those cases we use arrayForType
    return nil;
}
- (NSArray *)arrayForType:(id)aKey {
  aKey = QSUTIForAnyTypeString(aKey);
	id object = [self _safeObjectForType:aKey];
	if (!object) return nil;
	if ([object isKindOfClass:[NSArray class]]) return object;
	else return [NSArray arrayWithObject:object];
}

- (void)setObject:(id)object forType:(id)aKey {
    if (!aKey) {
        return;
    }
    aKey = QSUTIForAnyTypeString(aKey);
    @synchronized(data) {
        if (object) {
            if (object != [data objectForKey:aKey]) {
                [data setObject:object forKey:aKey];
            }
        } else {
            [data removeObjectForKey:aKey];
        }
    }
}

- (id)objectForCache:(id)aKey {
    return [cache objectForKey:aKey];
}

- (void)setObject:(id)object forCache:(id)aKey {
    if (!aKey) {
        return;
    }
	if (object) {
		if (object != [[self cache] objectForKey:aKey]) {
			[[self cache] setObject:object forKey:aKey];
		}
	} else {
		[[self cache] removeObjectForKey:aKey];
	}
}

- (id)objectForMeta:(id)aKey {
    return [meta objectForKey:aKey];
}

- (void)setObject:(id)object forMeta:(id)aKey {
    if (!aKey) {
        return;
    }
    if (object) {
        if (object != [meta objectForKey:aKey]) {
            [meta setObject:object forKey:aKey];
        }
    } else {
        [meta removeObjectForKey:aKey];
    }
}

- (NSMutableDictionary *)cache {
	return cache;
}
- (void)setCache:(NSMutableDictionary *)aCache {
	if (cache != aCache) {
		cache = [QSThreadSafeMutableDictionary dictionaryWithDictionary:aCache];
	}
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([data respondsToSelector:[invocation selector]])
		[invocation invokeWithTarget:data];
	else
		[self doesNotRecognizeSelector:[invocation selector]];
}

- (NSString *)guessPrimaryType {
	NSArray *components = [self objectForCache:kQSObjectComponents];
	if ([components count]) {
		// for combined objects, if they all have the same primary type, return that type
		if ([NSSet setWithArray:[components arrayByEnumeratingArrayUsingBlock:^id(QSObject *obj) {
			return [obj primaryType];
		}]].count == 1) {
			return [components[0] primaryType];
		}
	}
	NSArray *allKeys = [data allKeys];
	if ([allKeys containsObject:QSFilePathType]) return QSFilePathType;
	else if ([allKeys containsObject:QSURLType]) return QSURLType;
	else if ([allKeys containsObject:QSTextType]) return QSTextType;
	else if ([allKeys containsObject:NSColorPboardType]) return NSColorPboardType;

	if ([allKeys count] == 1) return [allKeys lastObject];

	return nil;
}

- (NSArray *)types {
	NSArray *array = [data allKeys];

	return array;
}

- (NSArray *)decodedTypes {
	NSMutableArray *decodedTypes = [NSMutableArray arrayWithCapacity:[data count]];
	for(NSString *thisType in data) {
		[decodedTypes addObject:[thisType decodedPasteboardType]];
	}
	return decodedTypes;
}

- (BOOL)isCombinedObject {
	if ([[self objectForMeta:kQSIsCombinedObject] boolValue]) {
		return YES;
	}
	// check the data dicts for any multiple value fields - don't use the `maxCountForCombinedObjects` method as we want to stop as soon as we have any array > 1
	for (id value in [[self dataDictionary] allValues]) {
		if ([value isKindOfClass:[NSArray class]] && [(NSArray *)value count] > 1) {
			return YES;
		}
	}
	return NO;
}

- (NSUInteger)maxCountForCombinedObject {
	NSUInteger count = 1;
	for(id value in [[self dataDictionary] allValues]) {
		if ([value isKindOfClass:[NSArray class]]) {
			count = MAX([(NSArray *)value count] , count);
		}
	}
	return count;
}
- (NSUInteger)count {
	if ([self isCombinedObject] || ![self primaryType]) {
		return [self maxCountForCombinedObject];
	}
	id priObj = [self primaryObject];
	if ([priObj isKindOfClass:[NSArray class]])
		return [(NSArray *)priObj count];
	return 1;
}

- (NSUInteger) primaryCount {
	return [self count];
}

- (BOOL)isProxyObject
{
    return NO;
}

- (QSObject *)resolvedObject
{
    return self;
}
@end

@implementation QSObject (Hierarchy)

- (QSObject *)parent {
    QSObject * parent = nil;

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(parentOfObject:)])
		parent = [handler parentOfObject:self];

	if (!parent)
		parent = [QSLib objectWithIdentifier:[meta objectForKey:kQSObjectParentID]];
	return parent;
}

- (void)setParentID:(NSString *)parentID {
    [self setObject:parentID forMeta:kQSObjectParentID];
}

- (BOOL)childrenValid {
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(objectHasValidChildren:)])
		return [handler objectHasValidChildren:self];

	return NO;
}

- (BOOL)unloadChildren {
	//NSLog(@"unload children of %@", self);

	if (![self childrenLoaded]) return NO;
	//NSLog(@"unloaded %@ %x", self, self);
	[self setChildren:nil];
	[self setAltChildren:nil];
	flags.childrenLoaded = NO;
	[self setChildrenLoadedDate:0];
    @synchronized ([QSObject class]) {
        [childLoadedSet removeObject:self];
    }
	return YES;
}

- (void)loadChildren {
	id handler = [self handlerForSelector:@selector(loadChildrenForObject:)];
	if (handler && [handler loadChildrenForObject:self]) {
        flags.childrenLoaded = YES;
		self.childrenLoadedDate = [NSDate timeIntervalSinceReferenceDate];
        @synchronized ([QSObject class]) {
            [childLoadedSet addObject:self];
        }
    }

    NSArray *components = [self objectForCache:kQSObjectComponents];
    if (components)
        [self setChildren:components];
}

- (BOOL)hasChildren {

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(objectHasChildren:)])
		return [handler objectHasChildren:self];
	return [[self cache] objectForKey:kQSObjectChildren] && [(NSArray *)[[self cache] objectForKey:kQSObjectChildren] count] > 0;
}
@end

//Standard Accessors

@implementation QSObject (Accessors)

- (NSString *)identifier {
    @synchronized(self) {
        if (flags.noIdentifier)
            return nil;
        
        if (!identifier) {
            NSString *ident = nil;
            id handler = nil;
            if (handler = [self handlerForSelector:@selector(identifierForObject:)]) {
                ident = [handler identifierForObject:self];
            }
            if (!ident) {
                ident = [meta objectForKey:kQSObjectObjectID];
            }
            [self setIdentifier:ident];
        }
        
        return identifier;
    }
}

- (void)setIdentifier:(NSString *)newIdentifier
{
    @synchronized(self) {
        if (identifier != nil && newIdentifier != nil) {
            if(![identifier isEqualToString:newIdentifier]) {
                [QSLib removeObjectWithIdentifier:identifier];
                [QSLib setIdentifier:newIdentifier forObject:self];
                [meta setObject:newIdentifier forKey:kQSObjectObjectID];
                flags.noIdentifier = NO;
                identifier = newIdentifier;
            }
        }
        else if (newIdentifier == nil) {
            flags.noIdentifier = YES;
            [meta removeObjectForKey:kQSObjectObjectID];
            [QSLib removeObjectWithIdentifier:identifier];
            identifier = nil;
        } else if (identifier == nil) {
            flags.noIdentifier = NO;
			[QSLib setIdentifier:newIdentifier forObject:self];
            [meta setObject:newIdentifier forKey:kQSObjectObjectID];
            identifier = newIdentifier;
        }
    }
}

- (NSString *)name {
	if (!name) {
        name = [meta objectForKey:kQSObjectPrimaryName];
    }
	return name;
}

- (void)setName:(NSString *)newName {
    if (![name isEqualToString:newName]) {
        if ([newName length] > 255) newName = [newName substringToIndex:255];
        // ***warning  ** this should take first line only?
        name = newName;
        if (newName) {
            if ([newName isEqualToString:[self label]]) {
                // label is only necessary if it differs
                [self setLabel:nil];
            }
            [meta setObject:newName forKey:kQSObjectPrimaryName];
        } else {
            [meta removeObjectForKey:kQSObjectPrimaryName];
        }
    }
}

- (NSArray *)children {
	if (!flags.childrenLoaded || ![self childrenValid])
		[self loadChildren];

	return [cache objectForKey:kQSObjectChildren];
}

- (void)setChildren:(NSArray *)newChildren {
	if (newChildren) {
        if ([[self cache] objectForKey:kQSObjectChildren] != newChildren) {
            [[self cache] setObject:newChildren forKey:kQSObjectChildren];
			NSString *parentID = [self identifier];
			for (QSObject *child in newChildren) {
				[child setParentID:parentID];
			}
        }
    } else {
        [[self cache] removeObjectForKey:kQSObjectChildren];
    }
}

- (NSArray *)altChildren {
	if (!flags.childrenLoaded || ![self childrenValid])
		[self loadChildren];
	return [cache objectForKey:kQSObjectAltChildren];
}

- (void)setAltChildren:(NSArray *)newAltChildren {
	if (newAltChildren) {
        if ([[self cache] objectForKey:kQSObjectChildren] != newAltChildren) {
            [[self cache] setObject:newAltChildren forKey:kQSObjectAltChildren];
			NSString *parentID = [self identifier];
			for (QSObject *child in newAltChildren) {
				[child setParentID:parentID];
			}
        }
    } else {
        [[self cache] removeObjectForKey:kQSObjectAltChildren];
    }
}

- (NSString *)label {
    if (!label) {
        [self setLabel:[meta objectForKey:kQSObjectAlternateName]];
    }
    return label;
}

- (void)setLabel:(NSString *)newLabel {
	if (![newLabel isEqualToString:label]) {
        if (![newLabel length] || [newLabel isEqualToString:[self name]]) {
            newLabel = nil;
        }
		label = newLabel;
    }
    [self setObject:label forMeta:kQSObjectAlternateName];
}

- (NSString *)kind {
	NSString *kind = [meta objectForKey:kQSObjectKind];
	if (kind) return kind;

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(kindOfObject:)]) {
		kind = [handler kindOfObject:self];
		if (kind) {
			[meta setObject:kind forKey:kQSObjectKind];
			return kind;
		}
	}

	return [self primaryType];
}

- (NSString *)primaryType {
	if (primaryType) {
		return primaryType;
	}
    if (!primaryType)
        primaryType = [meta objectForKey:kQSObjectPrimaryType];
	if (!primaryType)
		primaryType = [self guessPrimaryType];
	if (primaryType)
		[self setPrimaryType:primaryType];
	return primaryType;
}
- (void)setPrimaryType:(NSString *)newPrimaryType {
    if (primaryType != newPrimaryType) {
        primaryType = newPrimaryType;
    }
	newPrimaryType = QSUTIForAnyTypeString(newPrimaryType);
    [self setObject:newPrimaryType forMeta:kQSObjectPrimaryType];
}

- (NSMutableDictionary *)dataDictionary {
	return data;
}

- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary {
    if (newDataDictionary != data) {
        data = newDataDictionary;
    }
}

- (BOOL)iconLoaded { return flags.iconLoaded;  }
- (void)setIconLoaded:(BOOL)flag {
	flags.iconLoaded = flag;
    @synchronized([QSObject class]) {
        if (flag) {
            [iconLoadedSet addObject:self];
        } else {
            [iconLoadedSet removeObject:self];
        }
    }
}

- (BOOL)childrenLoaded { return flags.childrenLoaded;  }
- (void)setChildrenLoaded:(BOOL)flag {
	flags.childrenLoaded = flag;
}

- (BOOL)contentsLoaded { return flags.contentsLoaded;  }
- (void)setContentsLoaded:(BOOL)flag {
	flags.contentsLoaded = flag;
}
- (NSTimeInterval) childrenLoadedDate { return [[meta objectForKey:kQSObjectChildrenLoadDate] doubleValue];  }
- (void)setChildrenLoadedDate:(NSTimeInterval)newChildrenLoadedDate {
	[meta setObject:[NSNumber numberWithDouble:newChildrenLoadedDate] forKey:kQSObjectChildrenLoadDate];
}


@end

@implementation QSObject (Archiving)
+ (id)objectFromFile:(NSString *)path {
	return [[self alloc] initFromFile:path];
}
- (id)initFromFile:(NSString *)path {
	if (self = [self init]) {
		[data setDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
			[self extractMetadata];
	}
	return self;
}
- (void)writeToFile:(NSString *)path {
	[data writeToFile:path atomically:YES];
}

- (void)extractMetadata {
	if ([meta objectForKey:kQSObjectIcon]) {
		id iconRef = [meta objectForKey:kQSObjectIcon];
		if ([iconRef isKindOfClass:[NSData class]])
			[self setIcon:[[NSImage alloc] initWithData:iconRef]];
		else if ([iconRef isKindOfClass:[NSString class]])
			[self setIcon:[QSResourceManager imageNamed:iconRef]];
        if (icon != nil) {
            [self setIconLoaded:YES];
        }
	}
    if ([meta objectForKey:kQSObjectAlternateName])
		[self setLabel:[meta objectForKey:kQSObjectAlternateName]];
    if ([meta objectForKey:kQSObjectPrimaryName])
        [self setName:[meta objectForKey:kQSObjectPrimaryName]];
	if ([meta objectForKey:kQSObjectObjectID]) {
        [self setIdentifier:[meta objectForKey:kQSObjectObjectID]];
    }
	if ([meta objectForKey:kQSObjectPrimaryType])
		[self setPrimaryType:[meta objectForKey:kQSObjectPrimaryType]];


	[data removeObjectForKey:QSProcessType]; // Don't carry over process info
}

@end

@implementation QSObject (Icon)
- (BOOL)loadIcon {
  NSString *namedIcon = [self objectForMeta:kQSObjectIconName];
	if ([self iconLoaded] && !namedIcon) {
        return NO;
	}
	[self setIconLoaded:YES];

	if (namedIcon) {
        NSImage *image = [QSResourceManager imageNamed:namedIcon];
		if (image) {
			[self setIcon:image];
			return YES;
		}
	}

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(loadIconForObject:)]) {
        QSObject __weak *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // loadIconForObject returns a BOOL, but we can't return it from here
            // nothing ever checks the return from loadIcon anyway
            [handler loadIconForObject:weakSelf];
        });
        return YES;
    }

	//// if ([primaryType hasPrefix:@"QSCsontact"])
	//	 return NO;
    
	if ([IMAGETYPES intersectsSet:[NSSet setWithArray:[data allKeys]]]) {
		[self setIcon:[[NSImage alloc] initWithPasteboard:(NSPasteboard *)self]];
	}
    
	if (![self icon]) {
		[self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
		return NO;
	}
    
	return NO;
}

- (BOOL)unloadIcon {
	if (![self iconLoaded]) return NO;
    
	[self setIcon:nil];
	[self setIconLoaded:NO];
	return YES;
}

- (NSImage *)icon {
    
	if (icon) return icon;
    
	id handler = nil;
	if ([self count] > 1) {
		if (handler = [self handlerForSelector:@selector(setQuickIconForCombinedObject:)]) {
			[handler setQuickIconForCombinedObject:self];
		}
	} else {
		if (handler = [self handlerForSelector:@selector(setQuickIconForObject:)])
			[handler setQuickIconForObject:self];
		
		else if ([[self primaryType] isEqualToString:QSContactPhoneType]) [self setIcon: [QSResourceManager imageNamed:@"ContactPhone"]];
		else if ([[self primaryType] isEqualToString:QSContactAddressType]) [self setIcon: [QSResourceManager imageNamed:@"ContactAddress"]];
		else if ([[self primaryType] isEqualToString:QSEmailAddressType]) [self setIcon: [QSResourceManager imageNamed:@"ContactEmail"]];
		
		else if ([[self types] containsObject:@"BookmarkDictionaryListPboardType"]) {
			[self setIcon:[QSResourceManager imageNamed:@"FadedDefaultBookmarkIcon"]];
		}
	}
    if (!icon) {
        // try and get an image from the QSTypeDefinitions dict
        NSString *namedIcon = [[[QSReg tableNamed:@"QSTypeDefinitions"] objectForKey:[self primaryType]] objectForKey:@"icon"];
        if (namedIcon) {
            [self setIcon:[QSResourceManager imageNamed:namedIcon]];
        }
    }
	if (!icon) {
		[self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
    }
    
	if (icon) return icon;
	return nil;
}

- (void)setIcon:(NSImage *)newIcon {
	if (newIcon != icon) {
        BOOL iconChange = (icon != nil && newIcon != nil);
		icon = newIcon;
		[icon setCacheMode:NSImageCacheNever];
        if (iconChange) {
            // icon is being replaced, not set - notify UI
			QSGCDMainAsync(^{
            	[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectIconModified object:self];
			});
        }
	}
}

- (void)updateIcon:(NSImage *)newIcon
{
    // deprecated - just use setIcon
    [self setIcon:newIcon];
}
@end

@implementation QSObject (Quicklook)

- (NSURL *)previewItemURL
{
    if ([[self primaryType] isEqualToString:QSURLType]) {
        NSString *urlString = [[[self dataDictionary] objectForKey:QSURLType] URLEncoding];
        if (urlString) {
        return [NSURL URLWithString:urlString];
        }
    }
    else {
        NSString *filePathString = [self singleFilePath];
        if (filePathString) {
        return [NSURL fileURLWithPath:filePathString];
        }
    }
    return nil;
}

- (NSString *)previewItemTitle
{
    return [self name];
}

@end
