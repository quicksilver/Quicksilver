#import "QSObject.h"
#import "QSLibrarian.h"
#import "QSDebug.h"
#import "QSObjectHandler.h"

static NSMutableSet *iconLoadedSet;
static NSMutableSet *childLoadedSet;
static NSTimeInterval globalLastAccess;

BOOL QSObjectInitialized = NO;

NSSize QSMaxIconSize;

@interface QSObject () {
	/* Access mush be protected by @synchronized */
	NSString *_identifier;
	NSString *_name;
	NSString *_label;
	NSString *_details;
	NSString *_primaryType;
	id _primaryObject;

	NSImage *_icon;

	NSTimeInterval _lastAccess;
	QSObjectFlags _flags;

	/* Acts as a placeholder while the ivar is still accessible externally */
	NSMutableDictionary *_data;
}

@end

@implementation QSObject

@synthesize data=data;

+ (void)initialize {
	if (!QSObjectInitialized) {
		QSMaxIconSize = QSSizeMax;
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(interfaceChanged) name:QSInterfaceChangedNotification object:nil];
		[nc addObserver:self selector:@selector(purgeOldImagesAndChildren) name:QSReleaseOldCachesNotification object:nil];
		[nc addObserver:self selector:@selector(purgeAllImagesAndChildren) name:QSReleaseAllCachesNotification object:nil];

		iconLoadedSet = [[NSMutableSet alloc] init];
		childLoadedSet = [[NSMutableSet alloc] init];
		QSObjectInitialized = YES;
	}
}

+ (void)purgeOldImagesAndChildren {[self purgeImagesAndChildrenOlderThan:1.0];}
+ (void)purgeAllImagesAndChildren {[self purgeImagesAndChildrenOlderThan:0.0];}

+ (void)purgeImagesAndChildrenOlderThan:(NSTimeInterval)interval {
	NSTimeInterval tempLastAccess = 0;
	NSSet *tempIconSet = nil;
	NSSet *tempChildSet = nil;

	// Make copies of the sets so we can purge them without bothering about threading
	// We're synchronizing on the class instance, since those are class-ivars
	@synchronized ([QSObject class]) {
		tempLastAccess = globalLastAccess;
		tempIconSet = [iconLoadedSet copy];
		tempChildSet = [childLoadedSet copy];
	}

	for (QSObject *obj in tempIconSet) {
		if (obj->_lastAccess && obj->_lastAccess < (tempLastAccess - interval)) {
			[obj unloadIcon];
		}
	}
	for (QSObject *obj in tempChildSet) {
		if (obj->_lastAccess && obj->_lastAccess < (tempLastAccess - interval)) {
			[obj unloadChildren];
		}
	}
}

+ (void)interfaceChanged {
	[self purgeAllImagesAndChildren];
}

+ (instancetype)objectWithName:(NSString *)aName {
	QSObject *newObject = [[self alloc] init];
	newObject.name = aName;
	return newObject;
}

+ (instancetype)objectWithIdentifier:(NSString *)anIdentifier {
	return [QSLib objectWithIdentifier:anIdentifier];
}

+ (instancetype)makeObjectWithIdentifier:(NSString *)anIdentifier {
	QSObject *object = [[QSObject alloc] init];
	object.identifier = anIdentifier;
	return object;
}

- (instancetype)init {
	self = [super init];
	if (!self) return nil;

	_data = data = [NSMutableDictionary dictionaryWithCapacity:0];
	_meta = [NSMutableDictionary dictionaryWithCapacity:0];
	_cache = [NSMutableDictionary dictionaryWithCapacity:0];

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if ([self iconLoaded])
		[self unloadIcon];
	[self unloadChildren];
}

- (NSUInteger)hash
{
	return _identifier.hash ^ _data.hash;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [self init];
	if (!self) return nil;

	[_meta setDictionary:[coder decodeObjectForKey:@"meta"]];
	[_data setDictionary:[coder decodeObjectForKey:@"data"]];
	[self extractMetadata];
	id dup = [QSLib objectWithIdentifier:self.identifier];
	if (dup) return dup;
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.meta forKey:@"meta"];
	[coder encodeObject:self.data forKey:@"data"];
}

- (BOOL)isEqual:(QSObject *)anObject {
	if (!anObject) return NO;
	if (self != anObject && [anObject isKindOfClass:[QSRankedObject class]]) {
		anObject = [(QSRankedObject *)anObject object];
	}
	if (self == anObject) return YES;
	NSString *otherIdentifier = anObject->_identifier;
	if ((_identifier || otherIdentifier) && [_identifier isEqualToString:otherIdentifier]) {
		return YES;
	}

	/* FIXME: This must go live in QSCollection */
	if (self.count > 1) {
		if (self.count != anObject.count) {
			return NO;
		}
		NSSet *myObjects = [NSSet setWithArray:[self splitObjects]];
		NSSet *otherObjects = [NSSet setWithArray:[anObject splitObjects]];
		if (![myObjects isEqualToSet:otherObjects]) {
			return NO;
		}
	} else {
		if (![_data isEqualToDictionary:anObject->_data]) {
			return NO;
		}
	}
	return YES;
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(NSUInteger)level {
	return [_data descriptionWithLocale:locale indent:level];
}

// Used by the debugger
- (NSString *)debugDescription
{
	return [NSString stringWithFormat:@"name: %@, label: %@, identifier: %@, primaryType: %@, primaryObject: %@, meta: %@, data: %@, cache: %@, icon: %@, lastAccess: %f",
			self.name, self.label, self.identifier, self.primaryType, self.primaryObject,
			self.meta.descriptionInStringsFileFormat,
			self.data.descriptionInStringsFileFormat,
			self.cache.descriptionInStringsFileFormat,
			self.icon.debugDescription,
			_lastAccess];
}

- (id)copyWithZone:(NSZone *)zone {
	QSObject *copy = [[[self class] allocWithZone:zone] init];

	copy.name = [_name copy];
	copy.label = [_label copy];
	copy.identifier = [_identifier copy];
	copy.icon = [_icon copy];
	copy.primaryType = [_primaryType copy];
	copy.primaryObject = [_primaryObject copy];

	copy.meta = [_meta mutableCopy];
	copy.data = [_data mutableCopy];
	copy.cache = [_cache mutableCopy];

	copy->_flags = _flags;
	copy->_lastAccess = _lastAccess;

	return copy;
}

/* FIXME: What is the meaning of this ?? */
- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([_data respondsToSelector:[invocation selector]])
		[invocation invokeWithTarget:_data];
	else
		[self doesNotRecognizeSelector:[invocation selector]];
}

- (NSString *)guessPrimaryType {
	NSArray *allKeys = self.types;
	if ([allKeys containsObject:QSFilePathType]) return QSFilePathType;
	else if ([allKeys containsObject:QSURLType]) return QSURLType;
	else if ([allKeys containsObject:QSTextType]) return QSTextType;
	else if ([allKeys containsObject:NSColorPboardType]) return NSColorPboardType;

	if ([allKeys count] == 1) return [allKeys lastObject];

	return nil;
}

#pragma mark -
#pragma mark Properties

- (NSString *)identifier {
	@synchronized (self) {
		if (_flags.noIdentifier)
			return nil;

		if (!_identifier) {
			NSString *ident = nil;
			id handler = nil;
			if (handler = [self handlerForSelector:@selector(identifierForObject:)]) {
				ident = [handler identifierForObject:self];
			}
			if (!ident) {
				ident = _meta[kQSObjectObjectID];
			}
			self.identifier = ident;
		}

		return _identifier;
	}
}

- (void)setIdentifier:(NSString *)newIdentifier {
	@synchronized(self) {
		if (_identifier != nil && newIdentifier != nil) {
			if(![_identifier isEqualToString:newIdentifier]) {
				[QSLib removeObjectWithIdentifier:_identifier];
				[QSLib setIdentifier:newIdentifier forObject:self];
				_meta[newIdentifier] = kQSObjectObjectID;
				_flags.noIdentifier = NO;
				_identifier = newIdentifier;
			}
		}
		else if (newIdentifier == nil) {
			_flags.noIdentifier = YES;
			[_meta removeObjectForKey:kQSObjectObjectID];
			[QSLib removeObjectWithIdentifier:_identifier];
			_identifier = nil;
		} else if (_identifier == nil) {
			_flags.noIdentifier = NO;
			[QSLib setIdentifier:newIdentifier forObject:self];
			_meta[newIdentifier] = kQSObjectObjectID;
			_identifier = newIdentifier;
		}
	}
}

- (NSString *)name {
	if (!_name) {
		_name = _meta[kQSObjectPrimaryName];
	}
	return _name;
}

- (void)setName:(NSString *)newName {
	if (![_name isEqualToString:newName]) {
		if ([newName length] > 255) newName = [newName substringToIndex:255];
		// ***warning  ** this should take first line only?
		_name = newName;
		if (newName) {
			if ([newName isEqualToString:[self label]]) {
				// label is only necessary if it differs
				self.label = nil;
			}
			_meta[newName] = kQSObjectPrimaryName;
		} else {
			[_meta removeObjectForKey:kQSObjectPrimaryName];
		}
	}
}

- (NSString *)label {
	if (!_label) {
		self.label = _meta[kQSObjectAlternateName];
	}
	return _label;
}

- (void)setLabel:(NSString *)newLabel {
	if (![newLabel isEqualToString:_label]) {
		if (![newLabel length] || [newLabel isEqualToString:[self name]]) {
			newLabel = nil;
		}
		_label = newLabel;
	}
	[self setObject:_label forMeta:kQSObjectAlternateName];
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
		details = _meta[kQSObjectDetails];
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
	} else if ([[self objectForType:self.primaryType] isKindOfClass:[NSString class]]) {
		details = [self objectForType:self.primaryType];
	}

	return details;
}

- (void)setDetails:(NSString *)newDetails {
	[self setObject:newDetails forMeta:kQSObjectDetails];
}

- (NSString *)primaryType {
	if (_primaryType) {
		return _primaryType;
	}
	if (!_primaryType)
		_primaryType = _meta[kQSObjectPrimaryType];
	if (!_primaryType)
		_primaryType = [self guessPrimaryType];
	if (_primaryType)
		self.primaryType = _primaryType;
	return _primaryType;
}

- (void)setPrimaryType:(NSString *)newPrimaryType {
	if (_primaryType != newPrimaryType) {
		_primaryType = newPrimaryType;
	}

	/* FIXME: This can cause primaryType to have a different value between ivar
	 * and _meta. At first, it's doesn't seems so bad, but a deserialized object
	 * after a restart would get the UTI instead of the original primaryType
	 */
	newPrimaryType = QSUTIForAnyTypeString(newPrimaryType);
	[self setObject:newPrimaryType forMeta:kQSObjectPrimaryType];
}

- (NSString *)kind {
	NSString *kind = _meta[kQSObjectKind];
	if (kind) return kind;

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(kindOfObject:)]) {
		kind = [handler kindOfObject:self];
		if (kind) {
			_meta[kind] = kQSObjectKind;
			return kind;
		}
	}

	return self.primaryType;
}

- (void)setPrimaryObject:(id)obj {
	_primaryObject = obj;
}

- (NSString *)displayName {
	return self.label ? self.label : self.name;
}

- (NSString *)toolTip {
#ifdef DEBUG
	return [NSString stringWithFormat:@"%@ (%p) \r%@\rTypes:\r\t%@", self.name , self, self.details , [self.decodedTypes componentsJoinedByString:@"\r\t"]];
#endif
	return nil; //[self displayName];
}

- (id)primaryObject {return _data[self.primaryType]; }

#pragma mark -
#pragma mark Hierarchy

- (QSObject *)parent {
	QSObject * parent = nil;

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(parentOfObject:)])
		parent = [handler parentOfObject:self];

	if (!parent)
		parent = [QSLib objectWithIdentifier:_meta[kQSObjectParentID]];
	return parent;
}

- (NSArray *)children {
	if (!_flags.childrenLoaded || !self.childrenValid)
		[self loadChildren];

	return _cache[kQSObjectChildren];
}

- (void)setChildren:(NSArray *)newChildren {
	if (newChildren) {
		if (self.cache[kQSObjectChildren] != newChildren) {
			self.cache[kQSObjectChildren] = newChildren;
			NSString *parentID = self.identifier;
			for (QSObject *child in newChildren) {
				child.parentID = parentID;
			}
		}
	} else {
		[self.cache removeObjectForKey:kQSObjectChildren];
	}
}

- (NSArray *)altChildren {
	if (!_flags.childrenLoaded || !self.childrenValid)
		[self loadChildren];
	return self.cache[kQSObjectAltChildren];
}

- (void)setAltChildren:(NSArray *)newAltChildren {
	if (newAltChildren) {
		/* FIXME: Looks like a bug */
		if (self.cache[kQSObjectChildren] != newAltChildren) {
			self.cache[kQSObjectAltChildren] = newAltChildren;
			NSString *parentID = self.identifier;
			for (QSObject *child in newAltChildren) {
				child.parentID = parentID;
			}
		}
	} else {
		[self.cache removeObjectForKey:kQSObjectAltChildren];
	}
}

- (void)setParentID:(NSString *)parentID {
	[self setObject:parentID forMeta:kQSObjectParentID];
}

- (BOOL)hasChildren {
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(objectHasChildren:)])
		return [handler objectHasChildren:self];
	return NO;
}

- (void)loadChildren {
	id handler = [self handlerForSelector:@selector(loadChildrenForObject:)];
	if (handler && [handler loadChildrenForObject:self]) {
		_flags.childrenLoaded = YES;
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		self.childrenLoadedDate = now;
		_lastAccess = now;

		@synchronized ([QSObject class]) {
			globalLastAccess = now;
			[childLoadedSet addObject:self];
		}
	}

	NSArray *components = [self objectForCache:kQSObjectComponents];
	if (components)
		self.children = components;
}

- (BOOL)unloadChildren {
	if (!self.childrenLoaded) return NO;

	self.children = nil;
	self.altChildren = nil;
	_flags.childrenLoaded = NO;
	self.childrenLoadedDate = 0;
	@synchronized ([QSObject class]) {
		[childLoadedSet removeObject:self];
	}
	return YES;
}

- (BOOL)childrenLoaded { return _flags.childrenLoaded;  }
- (void)setChildrenLoaded:(BOOL)flag {
	_flags.childrenLoaded = flag;
}

- (BOOL)childrenValid {
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(objectHasValidChildren:)])
		return [handler objectHasValidChildren:self];

	return NO;
}

- (NSTimeInterval)childrenLoadedDate { return [self.meta[kQSObjectChildrenLoadDate] doubleValue];  }
- (void)setChildrenLoadedDate:(NSTimeInterval)newChildrenLoadedDate {
	self.meta[kQSObjectChildrenLoadDate] = @(newChildrenLoadedDate);
}

- (BOOL)contentsLoaded { return _flags.contentsLoaded;  }
- (void)setContentsLoaded:(BOOL)flag {
	_flags.contentsLoaded = flag;
}

#pragma mark -
#pragma mark Icons

- (NSImage *)icon {
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	_lastAccess = now;
	@synchronized ([QSObject class]) {
		globalLastAccess = now;
	}

	if (_icon) return _icon;

	id handler = nil;
	if (handler = [self handlerForSelector:@selector(setQuickIconForObject:)])
		[handler setQuickIconForObject:self];

	else if ([[self primaryType] isEqualToString:QSContactPhoneType])
		self.icon = [QSResourceManager imageNamed:@"ContactPhone"];
	else if ([[self primaryType] isEqualToString:QSContactAddressType])
		self.icon = [QSResourceManager imageNamed:@"ContactAddress"];
	else if ([[self primaryType] isEqualToString:QSEmailAddressType])
		self.icon = [QSResourceManager imageNamed:@"ContactEmail"];

	else if ([[self types] containsObject:@"BookmarkDictionaryListPboardType"]) {
		self.icon = [QSResourceManager imageNamed:@"FadedDefaultBookmarkIcon"];
	}

	if (!_icon) {
		// try and get an image from the QSTypeDefinitions dict
		NSString *namedIcon = [[[QSReg tableNamed:@"QSTypeDefinitions"] objectForKey:[self primaryType]] objectForKey:@"icon"];
		if (namedIcon) {
			self.icon = [QSResourceManager imageNamed:namedIcon];
		}
	}
	if (!_icon) {
		self.icon = [QSResourceManager imageNamed:@"GenericQuestionMarkIcon"];
	}

	if (_icon) return _icon;
	return nil;
}

- (void)setIcon:(NSImage *)newIcon {
	if (newIcon != _icon) {
		BOOL iconChange = (_icon != nil && newIcon != nil);
		_icon = newIcon;
		[_icon setCacheMode:NSImageCacheNever];
		if (iconChange) {
			// icon is being replaced, not set - notify UI
			[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectIconModified object:self];
		}
	}
}

- (void)updateIcon:(NSImage *)newIcon { self.icon = newIcon; }

- (BOOL)iconLoaded { return _flags.iconLoaded;  }
- (void)setIconLoaded:(BOOL)flag {
	_flags.iconLoaded = flag;
	@synchronized([QSObject class]) {
		if (flag) {
			[iconLoadedSet addObject:self];
		} else {
			[iconLoadedSet removeObject:self];
		}
	}
}

- (BOOL)retainsIcon { return _flags.retainsIcon;  }
- (void)setRetainsIcon:(BOOL)flag {
	_flags.retainsIcon = (flag>0);
}

- (BOOL)loadIcon {
	NSString *namedIcon = [self objectForMeta:kQSObjectIconName];
	if (self.iconLoaded && !namedIcon) {
		return NO;
	}

	/* FIXME: Why isn't this done in -setIcon: ? */
	self.iconLoaded = YES;
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	_lastAccess = now;
	@synchronized ([QSObject class]) {
		globalLastAccess = now;
	}

	if (namedIcon) {
		NSImage *image = [QSResourceManager imageNamed:namedIcon];
		if (image) {
			self.icon = image;
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

	if ([IMAGETYPES intersectsSet:[NSSet setWithArray:self.types]]) {
		self.icon = [[NSImage alloc] initWithPasteboard:(NSPasteboard *)self];
	}

	if (!self.icon) {
		self.icon = [QSResourceManager imageNamed:@"GenericQuestionMarkIcon"];
		return NO;
	}

	return NO;
}

- (BOOL)unloadIcon {
	if (!self.iconLoaded) return NO;
	if (self.retainsIcon) return NO;

	self.icon = nil;
	self.iconLoaded = NO;
	return YES;
}

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped {
	id handler = nil;
	if (handler = [self handlerForSelector:@selector(drawIconForObject:inRect:flipped:)]) {
		return [handler drawIconForObject:self inRect:rect flipped:flipped];
	}
	return NO;
}

#pragma mark -
#pragma mark Type-handling

- (NSArray *)types {
	/* FIXME: make not mutable */
	NSMutableArray *array = [[self.data allKeys] mutableCopy];
	return array;
}

- (NSArray *)decodedTypes {
	NSMutableArray *decodedTypes = [NSMutableArray array];
	for (NSString *thisType in self.data) {
		[decodedTypes addObject:[thisType decodedPasteboardType]];
	}
	return decodedTypes;
}

- (id <QSObjectHandler>)handlerForType:(NSString *)type selector:(SEL)selector {
	id __block handler = [[QSReg objectHandlers] objectForKey:type];
	if (!handler) {
		[[QSReg objectHandlers] enumerateKeysAndObjectsUsingBlock:^(NSString *handlerType, id anyHandler, BOOL *stop) {
			if (UTTypeConformsTo((__bridge CFStringRef)type, (__bridge CFStringRef)handlerType) ||
				(UTTypeConformsTo((__bridge CFStringRef)handlerType, kUTTypeText) && UTTypeConformsTo((__bridge CFStringRef)type, kUTTypeText))) {
				handler = anyHandler;
				*stop = YES;
			}
		}];
	}
	return (selector == NULL ? handler : ([handler respondsToSelector:selector] ? handler : nil ));
}

- (id <QSObjectHandler>)handlerForSelector:(SEL)selector {
	return [self handlerForType:[self primaryType] selector:selector];
}

- (id <QSObjectHandler>)handler {
	return [self handlerForType:[self primaryType] selector:nil];
}

#pragma mark -
#pragma mark Low-level access

- (id)objectForMeta:(id)aKey {
	return self.meta[aKey];
}

- (void)setObject:(id)object forMeta:(id)aKey {
	if (!aKey) return;

	if (object) {
		if (object != self.meta[aKey]) {
			self.meta[aKey] = object;
		}
	} else {
		[self.meta removeObjectForKey:aKey];
	}
}

- (id)objectForType:(id)aKey {
	id object = [self _safeObjectForType:aKey];
	if ([object isKindOfClass:[NSArray class]]) {
		if ([(NSArray *) object count] == 1) return [object lastObject];
	} else {
		aKey = QSUTIForAnyTypeString(aKey);
		if ([aKey isEqualToString:QSTextType] && [object isKindOfClass:[NSData class]]) {
			object = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
		}
		return object;
	}
	// if the object for type: aKey is an array, we return 'nil' (not the actual array)
	// For those cases we use arrayForType
	return nil;
}

- (void)setObject:(id)object forType:(id)aKey {
	if (!aKey) return;

	aKey = QSUTIForAnyTypeString(aKey);
	@synchronized (_data) {
		if (object) {
			if (object != _data[aKey]) {
				_data[aKey] = object;
			}
		} else {
			[_data removeObjectForKey:aKey];
		}
	}
}

- (id)objectForCache:(id)aKey {
	return self.cache[aKey];
}

- (void)setObject:(id)object forCache:(id)aKey {
	if (!aKey) return;

	@synchronized(_cache) {
		if (object) {
			if (object != self.cache[aKey]) {
				self.cache[aKey] = object;
			}
		} else {
			[self.cache removeObjectForKey:aKey];
		}
	}
}

- (NSArray *)arrayForType:(id)aKey {
	id object = [self _safeObjectForType:aKey];
	if (!object) return nil;
	if ([object isKindOfClass:[NSArray class]]) return object;
	else return [NSArray arrayWithObject:object];
}

#pragma mark -
#pragma mark Archiving

+ (instancetype)objectFromFile:(NSString *)path {
	return [[self alloc] initFromFile:path];
}

- (instancetype)initFromFile:(NSString *)path {
	self = [self init];
	if (!self) return nil;

	[_data setDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[self extractMetadata];

	return self;
}

- (void)writeToFile:(NSString *)path {
	[self.data writeToFile:path atomically:YES];
}

- (void)extractMetadata {
	if (_meta[kQSObjectIcon]) {
		id iconRef = _meta[kQSObjectIcon];
		if ([iconRef isKindOfClass:[NSData class]])
			self.icon = [[NSImage alloc] initWithData:iconRef];
		else if ([iconRef isKindOfClass:[NSString class]])
			self.icon = [QSResourceManager imageNamed:iconRef];
		/* FIXME: Again with the iconLoaded stuff */
		if (self.icon != nil) {
			self.IconLoaded = YES;
		}
	}
	if (_meta[kQSObjectAlternateName])
		self.label = _meta[kQSObjectAlternateName];
	if (_meta[kQSObjectPrimaryName])
		self.name = _meta[kQSObjectPrimaryName];
	if (_meta[kQSObjectObjectID])
		self.identifier = _meta[kQSObjectObjectID];
	if (_meta[kQSObjectPrimaryType])
		self.primaryType = _meta[kQSObjectPrimaryType];

	[_data removeObjectForKey:QSProcessType]; // Don't carry over process info
}

@end

@implementation QSObject (QSCollection)

+ (id)objectByMergingObjects:(NSArray *)objects withObject:(QSObject *)object {
	if ([objects containsObject:object] || !object)
		return [self objectByMergingObjects:objects];

	NSMutableArray *array = [objects mutableCopy];
	[array addObject:object];
	return [self objectByMergingObjects:array];
}

// Method to merge objects into a single 'combined' object
+ (id)objectByMergingObjects:(NSArray *)objects {
	// if there's only 1 object, just return it
	if (objects.count == 1) {
		return objects[0];
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
			array = combinedData[type];
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
	object.data = combinedData;
	[object setObject:objects forCache:kQSObjectComponents];
	if (combinedData[QSFilePathType])
		// try to guess a name based on the file types
		[object guessName];
	else
		// fall back on setting a simple name
		object.name = NSLocalizedString(@"Combined Objects", nil);
	return object;
}

- (NSArray *)splitObjects {
	QSObject *object = [self resolvedObject];
	if (object.count == 1) {
		return @[object];
	}

	NSArray *splitObjects = [object objectForCache:kQSObjectComponents];

	if (!splitObjects) {
		splitObjects = [object children];
	}
	return splitObjects;
}

- (NSUInteger)count {
	if (!self.primaryType) {
		NSUInteger count = 1;
		for (id value in [self.data allValues]) {
			if ([value isKindOfClass:[NSArray class]])
				count = MAX([(NSArray *)value count], count);
		}
		return count;
	}

	id priObj = self.primaryObject;
	if ([priObj isKindOfClass:[NSArray class]])
		return [(NSArray *)priObj count];

	return 1;
}

- (NSUInteger) primaryCount {
	return self.count;
}

@end

@implementation QSObject (QSProxySupport)

- (BOOL)isProxyObject { return NO; }

- (QSObject *)resolvedObject { return self; }

- (id)_safeObjectForType:(id)aKey {
	aKey = QSUTIForAnyTypeString(aKey);
	return self.data[aKey];
}

@end

@implementation QSObject (Quicklook)

- (NSURL *)previewItemURL
{
	if ([self.primaryType isEqualToString:QSURLType]) {
		NSString *urlString = [self.data[QSURLType] URLEncoding];
		if (urlString) {
			return [NSURL URLWithString:urlString];
		}
	}
	else {
		NSString *filePathString = self.singleFilePath;
		if (filePathString) {
			return [NSURL fileURLWithPath:filePathString];
		}
	}
	return nil;
}

- (NSString *)previewItemTitle
{
	return self.name;
}

@end

@implementation QSObject (QSDeprecated)

- (NSMutableDictionary *)dataDictionary { return self.data; }
- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary {
	self.data = newDataDictionary;
}

@end
