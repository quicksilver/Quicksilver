#import "QSObject.h"
#import "QSObject_Pasteboard.h"
#import "QSObject_FileHandling.h"

#import "QSObject_PropertyList.h"
#import "QSLibrarian.h"
#import "QSController.h"

#import "QSStringRanker.h"
#import "QSNotifications.h"
//#import "QSFaviconManager.h"
#import "QSResourceManager.h"
#import "QSTypes.h"
#import "QSRegistry.h"
#import "QSInterfaceController.h"
#import "QSDebug.h"

#import "QSPreferenceKeys.h"

#import "QSMnemonics.h"

#import "NSString_Purification.h"

//static QSController *controller;
static NSMutableDictionary *objectDictionary;

static NSMutableSet *iconLoadedSet;
static NSMutableSet *childLoadedSet;

//static NSMutableDictionary *mainChildrenDictionary;
//static NSMutableDictionary *altChildrenDictionary;

static NSTimeInterval globalLastAccess;

BOOL QSObjectInitialized = NO;

NSSize QSMaxIconSize;

@implementation QSObject
+ (void)initialize {
	if (!QSObjectInitialized) {
		QSMaxIconSize = NSMakeSize(128, 128);
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(interfaceChanged) name:QSInterfaceChangedNotification object:nil];
		[nc addObserver:self selector:@selector(purgeOldImagesAndChildren) name:QSReleaseOldCachesNotification object:nil];
		[nc addObserver:self selector:@selector(cleanObjectDictionary) name:QSReleaseOldCachesNotification object:nil];
		[nc addObserver:self selector:@selector(purgeAllImagesAndChildren) name:QSReleaseAllCachesNotification object:nil];

	//	controller = [NSApp delegate];

		objectDictionary = [[NSMutableDictionary alloc] init]; // initWithCapacity:100]; formerly for these three
		iconLoadedSet = [[NSMutableSet alloc] init];
		childLoadedSet = [[NSMutableSet alloc] init];

		[[NSImage imageNamed:@"Question"] createIconRepresentations];

		[[NSImage imageNamed:@"ContactAddress"] createRepresentationOfSize:NSMakeSize(16, 16)];
		[[NSImage imageNamed:@"ContactPhone"] createRepresentationOfSize:NSMakeSize(16, 16)];
		[[NSImage imageNamed:@"ContactEmail"] createRepresentationOfSize:NSMakeSize(16, 16)];

		[[NSImage imageNamed:@"defaultAction"] createIconRepresentations];

		QSObjectInitialized = YES;
	}
}

+ (void)cleanObjectDictionary {
	QSObject *thisObject;
    NSMutableArray *keysToDeleteFromObjectDict = [[NSMutableArray alloc] init];
    @synchronized(objectDictionary) {
        for (NSString *thisKey in [objectDictionary allKeys]) {
            thisObject = [objectDictionary objectForKey:thisKey];
            if ([thisObject retainCount] < 2) {
                [keysToDeleteFromObjectDict addObject:thisKey];
            }
            //NSLog(@"%d %@", [thisObject retainCount] , [thisObject name]);
        }
        [objectDictionary removeObjectsForKeys:keysToDeleteFromObjectDict];
    }
	
#ifdef DEBUG
	NSUInteger count = 0;
    count = [keysToDeleteFromObjectDict count];
	if (DEBUG_MEMORY && count)
		NSLog(@"Released %lu objects", (unsigned long)count);
#endif
    [keysToDeleteFromObjectDict release];
}

+ (void)purgeOldImagesAndChildren {[self purgeImagesAndChildrenOlderThan:1.0];}
+ (void)purgeAllImagesAndChildren {[self purgeImagesAndChildrenOlderThan:0.0];}

+ (void)purgeImagesAndChildrenOlderThan:(NSTimeInterval)interval {

#ifdef DEBUG
	NSUInteger imagecount = 0;
	NSUInteger childcount = 0;
#endif
 // NSString *thisKey = nil;

    @synchronized(iconLoadedSet) {
        NSSet *s = [iconLoadedSet objectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *obj, BOOL *stop) {
            return obj->lastAccess && obj->lastAccess < (globalLastAccess - interval) && ![obj isKindOfClass:[QSAction class]];
        }];
        for(QSObject *thisObject in s) {
            if ([thisObject unloadIcon]) {
                
#ifdef DEBUG
                imagecount++;
#endif
            }
        }
    }
    
    @synchronized(childLoadedSet) {
    NSSet *t = [childLoadedSet objectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *obj, BOOL *stop) {
        return obj->lastAccess && obj->lastAccess < (globalLastAccess - interval);
    }];
        
        for (QSObject *thisObject in t) {
            if ([thisObject unloadChildren]) {
#ifdef DEBUG
                childcount++;
#endif
            }
        }
    }


#ifdef DEBUG
	if (DEBUG_MEMORY && (imagecount || childcount) )
		NSLog(@"Released %lu images and %lu children (items before %f) ", (unsigned long)imagecount, (unsigned long)childcount, interval);
#endif

}

+ (void)purgeIdentifiers {
    @synchronized(objectDictionary) {
        [objectDictionary removeAllObjects];
    }
}

+ (void)interfaceChanged {
	QSMaxIconSize = [(QSInterfaceController *)[[NSApp delegate] interfaceController] maxIconSize];
	[self purgeAllImagesAndChildren];
	// if (VERBOSE) NSLog(@"newsize %f", QSMaxIconSize.width);
}

+ (void)registerObject:(QSBasicObject *)object withIdentifier:(NSString *)anIdentifier {
    if (object && anIdentifier) {
        @synchronized(objectDictionary) {
            [objectDictionary setObject:object forKey:anIdentifier];
        }
    }
    //		NSLog(@"setobj:%@", [objectDictionary objectForKey:anIdentifier]);
}


- (id)init {
	if (self = [super init]) {

		data = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
		meta = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
		name = nil;
		label = nil;
		icon = nil;
		identifier = nil;
		primaryType = nil;
		lastAccess = 0;
	}
	return self;
}

- (BOOL)isEqual:(id)anObject {
  if (self != anObject && [anObject isKindOfClass:[QSRankedObject class]]) {
    anObject = [anObject object];
  }
	if (self == anObject) return YES;
	if (![[self identifier] isEqualToString:[anObject identifier]]) return NO;
	if ([self primaryObject])
		return [[self primaryObject] isEqual:[anObject primaryObject]];
	for(NSString *key in data) {
		if (![[data objectForKey:key] isEqual:[anObject objectForType:key]]) return NO;
	}
	return YES;
}

+ (id)objectWithName:(NSString *)aName {
	QSObject *newObject = [[[self alloc] init] autorelease];
	[newObject setName:aName];
	return newObject;
}

+ (id)makeObjectWithIdentifier:(NSString *)anIdentifier {
	id object = [self objectWithIdentifier:anIdentifier];

	if (!object) {
		object = [[[self alloc] init] autorelease];
		[object setIdentifier:anIdentifier];
	}
	return object;
}

+ (id)objectWithIdentifier:(NSString *)anIdentifier {
//	NSLog(@"gotobj:%@ %@ %d", [objectDictionary objectForKey:anIdentifier] , anIdentifier, [objectDictionary count]);
	return [objectDictionary objectForKey:anIdentifier];
}

+ (id)objectByMergingObjects:(NSArray *)objects withObject:(QSObject *)object {
	if ([objects containsObject:object] || !object)
		return [self objectByMergingObjects:objects];

	NSMutableArray *array = [[objects mutableCopy] autorelease];
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
	// get the number of objects added to combinedData, then release setOfObjects
	NSInteger objectCount = [setOfObjects count];
	[setOfObjects release];
	
	// If there's still only 1 object (case: if the comma trick is used on the same object multiple times)
	if (objectCount == 1) {
		return [objects objectAtIndex:0];
	}
	
    NSMutableArray *typesToRemove = [NSMutableArray array];
	for(type in combinedData) {
		if (![typesSet containsObject:type])
            [typesToRemove addObject:type];
	}
	
    [combinedData removeObjectsForKeys:typesToRemove];
	
	// Create the 'combined' object
	QSObject *object = [[[QSObject alloc] init] autorelease];
	[object setDataDictionary:combinedData];
    [object setObject:objects forCache:kQSObjectComponents];
	if ([combinedData objectForKey:QSFilePathType])
		// try to guess a name based on the file types
		[object guessName];
	else
		// fall back on setting a simple name
		[object setName:NSLocalizedString(@"Combined Objects", nil)];
	return object;
}

- (void)dealloc {
	//NSLog(@"dealloc %x %@", self, [self name]);
	[self unloadIcon];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self unloadChildren];
	[data release];
	[meta release];
	[cache release];

	[name release];
	[label release];
	[identifier release];
	[icon release];
	[primaryType release];
	[primaryObject release];

	[super dealloc];
}

// !!! Andre Berg 20091008: adding a gdbDataFormatter method which can be easily used 
// as GDB data formatter, e.g. "<QSObject> {[$VAR gdbDataFormatter]}:s" will call it 
// and display the result. The advantage is that this formatter will go less out of scope

- (const char *) gdbDataFormatter {
	return [[NSString stringWithFormat:@"name: %@, label: %@, identifier: %@, primaryType: %@, primaryObject: %@, meta: %@, data: %@, cache: %@, icon: %@, lastAccess: %f",
             (name ? name : @"nil"),
             (label ? label : @"nil"),
             (identifier ? identifier : @"nil"),
			 (primaryType ? primaryType : @"nil"),
			 (primaryObject ? primaryObject : @"nil"),
             (meta ? [meta descriptionInStringsFileFormat] : @"nil"),
             (data ? [data descriptionInStringsFileFormat] : @"nil"),
             (cache ? [cache descriptionInStringsFileFormat] : @"nil"),
             (icon ? [icon description] : @"nil"),
			 (lastAccess ? lastAccess : 0.0f)] UTF8String];
}

- (id)copyWithZone:(NSZone *)zone {
#ifdef DEBUG
	NSLog(@"copied!");
#endif
	return NSCopyObject(self, 0, zone);
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

- (id)handlerForType:(NSString *)type selector:(SEL)selector {
	id handler = [[QSReg objectHandlers] objectForKey:type];
//    if(DEBUG && VERBOSE && handler == nil)
//        NSLog(@"No handler for type %@", type);
    
    return (selector == NULL ? handler : ( [handler respondsToSelector:selector] ? handler : nil ) );
}

- (id)handlerForSelector:(SEL)selector {
    return [self handlerForType:[self primaryType] selector:selector];
}

- (id)handler {
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
    } else if ([itemForKey([self primaryType]) isKindOfClass:[NSString class]]) {
        details = itemForKey([self primaryType]);
    }
    
	return details;
}

- (id)primaryObject {return itemForKey([self primaryType]);}
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
	//	if ([aKey isEqualToString:NSFilenamesPboardType]) return [self arrayForType:QSFilePathType];
	//	if ([aKey isEqualToString:NSStringPboardType]) return [self objectForType:QSTextType];
	//	if ([aKey isEqualToString:NSURLPboardType]) return [self objectForType:QSURLType];
	NSArray *object = (NSArray *)[self _safeObjectForType:aKey];
	if ([object isKindOfClass:[NSArray class]]) {
		if ([object count] == 1) return [object lastObject];
	} else {
		return object;
	}
	return nil;
}
- (NSArray *)arrayForType:(id)aKey {
	id object = [self _safeObjectForType:aKey];
	if (!object) return nil;
	if ([object isKindOfClass:[NSArray class]]) return object;
	else return [NSArray arrayWithObject:object];
}

- (void)setObject:(id)object forType:(id)aKey {
    if (!aKey) {
        return;
    }
	if (object) {
        if (object != [data objectForKey:aKey]) {
            [data setObject:object forKey:aKey];
        }
    } else {
        [data removeObjectForKey:aKey];
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
	if (!cache) [self setCache:[NSMutableDictionary dictionaryWithCapacity:1]];
	return cache;
}
- (void)setCache:(NSMutableDictionary *)aCache {
	if (cache != aCache) {
		[cache release];
		cache = [aCache retain];
	}
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([data respondsToSelector:[invocation selector]])
		[invocation invokeWithTarget:data];
	else
		[self doesNotRecognizeSelector:[invocation selector]];
}

- (NSString *)guessPrimaryType {
	NSArray *allKeys = [data allKeys];
	if ([[data allKeys] containsObject:QSFilePathType]) return QSFilePathType;
	else if ([allKeys containsObject:QSURLType]) return QSURLType;
	else if ([allKeys containsObject:QSTextType]) return QSTextType;
	else if ([allKeys containsObject:NSColorPboardType]) return NSColorPboardType;

	if ([allKeys count] == 1) return [allKeys lastObject];

	return nil;
}

- (NSArray *)types {
	NSMutableArray *array = [[[data allKeys] mutableCopy] autorelease];

	return array;
}

- (NSArray *)decodedTypes {
	NSMutableArray *decodedTypes = [NSMutableArray arrayWithCapacity:[data count]];
	for(NSString *thisType in data) {
		[decodedTypes addObject:[thisType decodedPasteboardType]];
	}
	return decodedTypes;
}

- (NSUInteger) count {
	if (![self primaryType]) {
		NSUInteger count = 1;
		for(id value in [[self dataDictionary] allValues]) {
			if ([value isKindOfClass:[NSArray class]]) count = MAX([(NSArray *)value count] , count);
		}
		return count;
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

- (QSBasicObject * ) parent {
	QSBasicObject * parent = nil;

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(parentOfObject:)])
		parent = [handler parentOfObject:self];

	if (!parent)
		parent = [objectDictionary objectForKey:[meta objectForKey:kQSObjectParentID]];
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
	[childLoadedSet removeObject:self];
	return YES;
}

- (void)loadChildren {
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(loadChildrenForObject:)]) {

	//	NSLog(@"load %x", self);

		if ([handler loadChildrenForObject:self]) {
	//		NSLog(@"xload %@", self);
			flags.childrenLoaded = YES;
			[self setChildrenLoadedDate:[NSDate timeIntervalSinceReferenceDate]];
			lastAccess = [NSDate timeIntervalSinceReferenceDate];
			globalLastAccess = lastAccess;

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
	return NO;
}
@end

//Standard Accessors

@implementation QSObject (Accessors)

- (NSString *)identifier {
    if (identifier)
        return identifier;
	if (flags.noIdentifier)
		return nil;
    
    NSString *ident = nil;
    
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(identifierForObject:)]) {
		ident = [[[handler identifierForObject:self] retain] autorelease];
	}
    [self setIdentifier:ident];

	return ident;
}

- (void)setIdentifier:(NSString *)newIdentifier {
    if (identifier != nil && newIdentifier != nil) {
        if(![identifier isEqualToString:newIdentifier]) {
            [objectDictionary setObject:self forKey:newIdentifier];
            [objectDictionary removeObjectForKey:identifier];
            [meta setObject:newIdentifier forKey:kQSObjectObjectID];
            [identifier release];
            flags.noIdentifier = NO;
            identifier = [newIdentifier retain];
        }
    }
    else if (newIdentifier == nil) {
        flags.noIdentifier = YES;
        [meta removeObjectForKey:kQSObjectObjectID];
        [identifier release];
        identifier = nil;
    } else if (identifier == nil) {
        [objectDictionary setObject:self forKey:newIdentifier];
        [meta setObject:newIdentifier forKey:kQSObjectObjectID];
        identifier = [newIdentifier retain];
    }
}

- (NSString *)name {
	if (!name) name = [[meta objectForKey:kQSObjectPrimaryName] retain];
	return name;
}

- (void)setName:(NSString *)newName {
    if (![name isEqualToString:newName]) {
        if ([newName length] > 255) newName = [newName substringToIndex:255];
        // ***warning  ** this should take first line only?
        [name release];
        name = [newName retain];
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
        }
    } else {
        [[self cache] removeObjectForKey:kQSObjectAltChildren];
    }
}

- (NSString *)label {
	// if (!label) return nil; //[self name];
    if (label)
        return label;
    
    label = [meta objectForKey:kQSObjectAlternateName];
    if (label)
        return label;
    
    return nil;
}

- (void)setLabel:(NSString *)newLabel {
	if (![newLabel isEqualToString:label]) {
        if (![newLabel length] || [newLabel isEqualToString:[self name]]) {
            newLabel = nil;
        }
		[label release];
		label = [newLabel retain];
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
    if (!primaryType)
        primaryType = [meta objectForKey:kQSObjectPrimaryType];
	if (!primaryType)
		primaryType = [[self guessPrimaryType] retain];
	return primaryType;
}
- (void)setPrimaryType:(NSString *)newPrimaryType {
    if (primaryType != newPrimaryType) {
        [primaryType release];
        primaryType = [newPrimaryType retain];
    }
    [self setObject:newPrimaryType forMeta:kQSObjectPrimaryType];
}

- (NSMutableDictionary *)dataDictionary {
	return data;
}

- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary {
    if (newDataDictionary != data) {
        [data release];
        data = [newDataDictionary retain];
    }
}

- (BOOL)iconLoaded { return flags.iconLoaded;  }
- (void)setIconLoaded:(BOOL)flag {
	flags.iconLoaded = flag;
}

- (BOOL)retainsIcon { return flags.retainsIcon;  } ;
- (void)setRetainsIcon:(BOOL)flag {
	flags.retainsIcon = (flag>0);
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

- (NSTimeInterval) lastAccess { return lastAccess;  }
- (void)setlastAccess:(NSTimeInterval)newlastAccess {
	lastAccess = newlastAccess;
}

@end

@implementation QSObject (Archiving)
+ (id)objectFromFile:(NSString *)path {
	return [[[self alloc] initFromFile:path] autorelease];
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
- (id)initWithCoder:(NSCoder *)coder {
	self = [self init];

	[meta setDictionary:[coder decodeObjectForKey:@"meta"]];
	[data setDictionary:[coder decodeObjectForKey:@"data"]];
	[self extractMetadata];
	id dup = [self findDuplicateOrRegisterID];
	if (dup) return [dup retain];
	return self;
}

- (void)extractMetadata {
	if ([meta objectForKey:kQSObjectIcon]) {
		id iconRef = [meta objectForKey:kQSObjectIcon];
		if ([iconRef isKindOfClass:[NSData class]])
			[self setIcon:[[[NSImage alloc] initWithData:iconRef] autorelease]];
		else if ([iconRef isKindOfClass:[NSString class]])
			[self setIcon:[QSResourceManager imageNamed:iconRef]];
        if (icon != nil) {
            [self setIconLoaded:YES];
        }
	}
    if ([meta objectForKey:kQSObjectPrimaryName])
        [self setName:[meta objectForKey:kQSObjectPrimaryName]];
	if ([meta objectForKey:kQSObjectObjectID])
		identifier = [[meta objectForKey:kQSObjectObjectID] retain];
	if ([meta objectForKey:kQSObjectPrimaryType])
		primaryType = [[meta objectForKey:kQSObjectPrimaryType] retain];
	if ([meta objectForKey:kQSObjectAlternateName])
		label = [[meta objectForKey:kQSObjectAlternateName] retain];

	[data removeObjectForKey:QSProcessType]; // Don't carry over process info
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:meta forKey:@"meta"];
	[coder encodeObject:data forKey:@"data"];
}

- (id)findDuplicateOrRegisterID {
	id dup = [QSObject objectWithIdentifier:[self identifier]];
	if (dup) {
		[self release];
		return dup;
	}
	if ([self identifier])
		[QSObject registerObject:self withIdentifier:[self identifier]];
	return nil;
}

@end

@implementation QSObject (Icon)
- (BOOL)loadIcon {
  NSString *namedIcon = [self objectForMeta:kQSObjectIconName];
	if ([self iconLoaded] && !namedIcon) {
        return NO;
	}
	[self setIconLoaded:YES];
    
	lastAccess = [NSDate timeIntervalSinceReferenceDate];
	globalLastAccess = lastAccess;
	[iconLoadedSet addObject:self];

	if (namedIcon) {
        NSImage *image = [QSResourceManager imageNamed:namedIcon];
		if (image) {
			[self setIcon:image];
			return YES;
		}
	}

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(loadIconForObject:)])
		return [handler loadIconForObject:self];

	//// if ([primaryType hasPrefix:@"QSCsontact"])
	//	 return NO;
    
	if ([IMAGETYPES intersectsSet:[NSSet setWithArray:[data allKeys]]]) {
		[self setIcon:[[[NSImage alloc] initWithPasteboard:(NSPasteboard *)self] autorelease]];
		[[self icon] createIconRepresentations];
        
		[[self icon] createRepresentationOfSize:NSMakeSize(128, 128)];
        
	}
    
	// file type for sound clipping: clps
	if (![self icon]) {
		[self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
		return NO;
	}
    
	return NO;
}

- (BOOL)unloadIcon {
	if (![self iconLoaded]) return NO;
	if ([self retainsIcon]) return NO;
    
	[self setIcon:nil];
	[self setIconLoaded:NO];
	[iconLoadedSet removeObject:self];
	return YES;
}

- (NSImage *)icon {
	lastAccess = [NSDate timeIntervalSinceReferenceDate];
	globalLastAccess = lastAccess;
    
	if (icon) return icon;
    
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(setQuickIconForObject:)])
		[handler setQuickIconForObject:self];
    
	else if ([[self primaryType] isEqualToString:QSContactPhoneType]) [self setIcon: [NSImage imageNamed:@"ContactPhone"]];
	else if ([[self primaryType] isEqualToString:QSContactAddressType]) [self setIcon: [NSImage imageNamed:@"ContactAddress"]];
    else if ([[self primaryType] isEqualToString:QSEmailAddressType]) [self setIcon: [NSImage imageNamed:@"ContactEmail"]];
    
	else if ([[self types] containsObject:@"BookmarkDictionaryListPboardType"]) {
		[self setIcon:[NSImage imageNamed:@"FadedDefaultBookmarkIcon"]];
	}
    
	else
		[self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
    
	if (icon) return icon;
	return nil;
}

- (void)setIcon:(NSImage *)newIcon {
	if (newIcon != icon) {
		[icon release];
		icon = [newIcon retain];
		[icon setCacheMode:NSImageCacheNever];
	}
}

- (void)updateIcon:(NSImage *)newIcon
{
    [self setIcon:newIcon];
    [[NSNotificationCenter defaultCenter] postNotificationName:QSObjectIconModified object:self];
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