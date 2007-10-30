


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

#import "QSInterfaceController.h"
#import "QSDebug.h"

#import "QSObjectRanker.h"


#import "QSPreferenceKeys.h"

#import "QSMnemonics.h"


#import "NSString_Purification.h"

static QSController *controller;
static NSMutableDictionary *objectDictionary;

static NSMutableSet *iconLoadedSet;
static NSMutableSet *childLoadedSet;

//static NSMutableDictionary *mainChildrenDictionary;
//static NSMutableDictionary *altChildrenDictionary;

#define typeHandlers [QSReg objectHandlers]
static NSTimeInterval globalLastAccess;


BOOL QSObjectInitialized=NO;

NSSize QSMaxIconSize;

@implementation QSObject
+ (void)initialize{
	if (!QSObjectInitialized){
    QSMaxIconSize=NSMakeSize(128,128);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceChanged) name:QSInterfaceChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purgeOldImagesAndChildren) name:QSReleaseOldCachesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanObjectDictionary) name:QSReleaseOldCachesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purgeAllImagesAndChildren) name:QSReleaseAllCachesNotification object:nil];
    
    controller=[NSApp delegate];
    
    objectDictionary=[[NSMutableDictionary alloc]initWithCapacity:100];
    iconLoadedSet=[[NSMutableSet alloc]initWithCapacity:100];
    childLoadedSet=[[NSMutableSet alloc]initWithCapacity:100];
    
    //typeHandlers=[[QSReg objectHandlers]retain];
    
    [[NSImage imageNamed:@"Question"]createIconRepresentations];
    
    [[NSImage imageNamed:@"ContactAddress"]createRepresentationOfSize:NSMakeSize(16,16)];
    [[NSImage imageNamed:@"ContactPhone"]createRepresentationOfSize:NSMakeSize(16,16)];
    [[NSImage imageNamed:@"ContactEmail"]createRepresentationOfSize:NSMakeSize(16,16)];
    
    [[NSImage imageNamed:@"defaultAction"]createIconRepresentations];
    QSObjectInitialized=YES;
	}   
}


+ (void)cleanObjectDictionary{
  unsigned count=0;
  QSObject *thisObject;
  for (NSString *thisKey in [objectDictionary allKeys]){
    thisObject=[objectDictionary objectForKey:thisKey];
    if ([thisObject retainCount]<2){
      count++;
      [objectDictionary removeObjectForKey:thisKey];
    }
		//QSLog(@"%d %@",[thisObject retainCount],[thisObject name]);
  }
  if (DEBUG_MEMORY && count) 
		QSLog(@"Released %i objects",count);
}

+ (void)purgeOldImagesAndChildren{[self purgeImagesAndChildrenOlderThan:1.0];}
+ (void)purgeAllImagesAndChildren{[self purgeImagesAndChildrenOlderThan:0.0];}
+ (void)purgeImagesAndChildrenOlderThan:(NSTimeInterval)interval{
  
  unsigned imagecount=0;
  unsigned childcount=0;
  
  for (QSObject *thisObject in [[iconLoadedSet mutableCopy] autorelease]){
		//	QSLog(@"i%@ %f",thisObject,thisObject->lastAccess);
    if (thisObject->lastAccess && thisObject->lastAccess<(globalLastAccess-interval)){
      if ([thisObject unloadIcon])
        imagecount++;
    }
  }
  
  for (QSObject *thisObject in [[childLoadedSet mutableCopy] autorelease]){
    if (thisObject->lastAccess && thisObject->lastAccess<(globalLastAccess-interval)){
      if ([thisObject unloadChildren]) childcount++;
    }
  }

  
  
  if (DEBUG_MEMORY && (imagecount || childcount)) 
		QSLog(@"Released %i images and %i children  (items before %d)",imagecount,childcount,(int)interval);
  
}
+ (void)interfaceChanged{
  QSMaxIconSize=[(QSInterfaceController *)[[NSApp delegate]interfaceController]maxIconSize];
	[self purgeAllImagesAndChildren];
}
+ (void)purgeIdentifiers{[objectDictionary removeAllObjects];}





- (id)init {
  if (self = [super init]) {
		
		data = nil;
    [self setDataDictionary:[NSMutableDictionary dictionaryWithCapacity:0]];
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


- (BOOL)isEqual:(id)anObject{
	if (self==anObject)return YES;
  if (![[self identifier]isEqualToString:[anObject identifier]])return NO;
  if ([self primaryObject])
    return [[self primaryObject]isEqual:[anObject primaryObject]];
  NSEnumerator *typesEnumerator=[data keyEnumerator];
  NSString *key;
  while(key=[typesEnumerator nextObject]){
    if (![[data objectForKey:key]isEqual:[anObject objectForType:key]])return NO;
  }
  return YES;
}


+ (id) objectWithName:(NSString *)aName{
  QSObject *newObject=[[[QSObject alloc]init]autorelease];
  [newObject setName:aName];
  return newObject;
}

+ (void) registerObject:(QSBasicObject *)object withIdentifier:(NSString *)anIdentifier{
  if (object && anIdentifier)
    [objectDictionary setObject:object forKey:anIdentifier];
}

+ (id) makeObjectWithIdentifier:(NSString *)anIdentifier{
	id object=[self objectWithIdentifier:anIdentifier];
	
	if (!object){
		object=[[[self alloc]init]autorelease];
		[object setIdentifier:anIdentifier];
	}
  return object;
}

+ (id) objectWithIdentifier:(NSString *)anIdentifier{
  return [objectDictionary objectForKey:anIdentifier];
}

+ (id) objectByMergingObjects:(NSArray *)objects withObject:(QSObject *)object{
	if ([objects containsObject:object] || !object)
		return [self objectByMergingObjects:objects];
	
	NSMutableArray *array=[objects mutableCopy];
	[array addObject:object];
	return	[self objectByMergingObjects:array];
}

- (NSArray *)splitObjects{
	NSDictionary *dataDict=[self dataDictionary];
	
	
	NSEnumerator *ke=[dataDict keyEnumerator];
	NSString *key;
	NSArray *value;
	//NSEnumerator *te;
	
	//int resultCount=0;
	int i;
	
	NSMutableArray *splitObjects=[NSMutableArray array];
	
	while(key=[ke nextObject]){
		value=[dataDict objectForKey:key];
		if ([value isKindOfClass:[NSArray class]]){
			while([splitObjects count]<[value count])
				[splitObjects addObject:[QSObject objectWithName:[self name]]];
			for (i=0;i<[value count];i++){
				[[splitObjects objectAtIndex:i]setObject:[value objectAtIndex:i] forType:key];
			}
		}else{
		}
	}
	return splitObjects;
}


+ (id) objectByMergingObjects:(NSArray *)objects{
  id thisObject;
	
	NSMutableSet *typesSet=nil;
	
	NSMutableDictionary *combinedData=[NSMutableDictionary dictionary];
	NSEnumerator *e;
	NSString *type;
	NSMutableArray *array;
  for (thisObject in objects){
		if (!typesSet)typesSet=[NSMutableSet setWithArray:[thisObject types]];
		else
			[typesSet intersectSet:[NSSet setWithArray:[thisObject types]]];
		
		for(type in typesSet){
			array=[combinedData objectForKey:type];
			if (!array) [combinedData setObject:(array=[NSMutableArray array]) forKey:type];
			[array addObjectsFromArray:[thisObject arrayForType:type]];
		}
	}
	
	e=[combinedData keyEnumerator];
	while(type=[e nextObject]){
		if (![typesSet containsObject:type])
			[combinedData removeObjectForKey:type];
	}
	
	
	QSObject *object=[[[QSObject alloc]init]autorelease];
	[object setDataDictionary:combinedData];
	[object setObject:objects forCache:kQSObjectComponents];
	if ([combinedData objectForKey:QSFilePathType])
		[object guessName];
	else
		[object setName:@"combined objects"];
  return object;
}



- (void) dealloc{
	//QSLog(@"dealloc %x %@",self,[self name]);
	[self unloadIcon];
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



- (NSString *)displayName {
  if (![self label]) return [self name];
  return [self label];
}
- (NSString *)toolTip{
  if (DEBUG)
    return [NSString stringWithFormat:@"%@ (%d)\r%@\rTypes:\r\t%@",[self name],self,[self details],[[self decodedTypes]componentsJoinedByString:@"\r\t"]];
  return nil; //[self displayName];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level{
  return [data descriptionWithLocale:locale indent:level];
}
/*
 - (NSString *)status{
 if ([)
 int pid=[[[dObject objectForType:QSProcessType]objectForKey:@"NSApplicationProcessIdentifier"]intValue];
 kill(pid, signal);   
 return nil;
 }
 */

- (id ) handler{
  return [typeHandlers objectForKey:[self primaryType]];
}

- (id)handlerForType:(NSString *)type selector:(SEL)selector{
	id handler=[typeHandlers objectForKey:type];
  if (!selector || [handler respondsToSelector:selector]) return handler;
	return nil;
}

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped{
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(drawIconForObject:inRect:flipped:)]){
		return [handler drawIconForObject:self inRect:rect flipped:flipped];
  }
	return NO;
}


- (void)setDetails:(NSString *)newDetails{
	[self setObject:newDetails forMeta:kQSObjectDetails];
}


- (NSString *)details{
	NSString *details=[meta objectForKey:kQSObjectDetails];
  if (details) return details;
  
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(detailsOfObject:)]){
		details=[handler detailsOfObject:self];
		if (details)[meta setObject:details forKey:kQSObjectDetails];
		return details;
  }
	/*
	 if ([[self primaryType] isEqualToString:NSFilenamesPboardType]){
	 }
	 */
  //if ([[self primaryType] isEqualToString:NSURLPboardType])
	//  return itemForKey(NSURLPboardType);
  
  
  if ([itemForKey([self primaryType]) isKindOfClass:[NSString class]])
    return itemForKey([self primaryType]); 
  
  
  //if ([[self types] containsObject:@"BookmarkDictionaryListPboardType"])
	//  return @"Safari Bookmarks";
  
  return nil; //[[data allKeys] componentsJoinedByString:@", "];
  
}
- (id)primaryObject{return itemForKey([self primaryType]);}
//- (id)objectForKey:(id)aKey{return [data objectForKey:aKey];}
//- (void)setObject:(id)object forKey:(id)aKey{[data setObject:object forKey:aKey];}

- (id)_safeObjectForType:(id)aKey{
	return[data objectForKey:aKey]; 
	if (flags.multiTyped) 
		return[data objectForKey:aKey]; 
	else if ([[self primaryType]isEqualToString:aKey]) 
		return data;
	return nil;
}



- (id)objectForType:(id)aKey{
	//	if ([aKey isEqualToString:NSFilenamesPboardType])return [self arrayForType:QSFilePathType];
	//	if ([aKey isEqualToString:NSStringPboardType])return [self objectForType:QSTextType];
	//	if ([aKey isEqualToString:NSURLPboardType])return [self objectForType:QSURLType];
	NSArray *object=(NSArray *)[self _safeObjectForType:aKey];
	if ([object isKindOfClass:[NSArray class]]){
		if ([object count]==1) return [object lastObject];
	}else{
		return object;
	}
	return nil;
}
- (NSArray *)arrayForType:(id)aKey{
	id object=[self _safeObjectForType:aKey];
	if (!object) return nil;
	if ([object isKindOfClass:[NSArray class]]) return object;
	else return [NSArray arrayWithObject:object];
}


- (void)setObject:(id)object forType:(id)aKey{
	if (object) [data setObject:object forKey:aKey];
	else [data removeObjectForKey:aKey];
}


- (id)objectForCache:(id)aKey{return [cache objectForKey:aKey];}
- (void)setObject:(id)object forCache:(id)aKey{if (object) [[self cache] setObject:object forKey:aKey];}
- (id)objectForMeta:(id)aKey{return [meta objectForKey:aKey];}
- (void)setObject:(id)object forMeta:(id)aKey{if (object) [meta setObject:object forKey:aKey];}
- (NSMutableDictionary *)cache{
	if (!cache)[self setCache:[NSMutableDictionary dictionaryWithCapacity:1]];
	return cache;	
}
- (void)setCache:(NSMutableDictionary *)aCache {
  if (cache != aCache) {
    [cache release];
    cache = [aCache retain];
  }
}


- (NSArray *)allKeys{return [data allKeys];}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  if ([data respondsToSelector:[invocation selector]])
    [invocation invokeWithTarget:data];
  else
    [self doesNotRecognizeSelector:[invocation selector]];
}

- (NSString *)guessPrimaryType{
	NSArray *allKeys=[data allKeys];
	if ([[data allKeys]containsObject:QSFilePathType]) return QSFilePathType;
	else if ([allKeys containsObject:QSURLType]) return QSURLType;
	else if ([allKeys containsObject:QSTextType]) return QSTextType;
	else if ([allKeys containsObject:NSColorPboardType]) return NSColorPboardType;
	
	if ([allKeys count]==1)return [allKeys lastObject];
	
	return nil;
}

- (BOOL)loadIcon{
  if ([self iconLoaded]) return NO;
  [self setIconLoaded:YES];
	
	lastAccess=[NSDate timeIntervalSinceReferenceDate];
	globalLastAccess=lastAccess;
  [iconLoadedSet addObject:self];
	//     QSLog(@"Load Icon for %@",self);
	
	NSString *namedIcon=[self objectForMeta:kQSObjectIconName];
	if (namedIcon){
		NSImage *image=[QSResourceManager imageNamed:namedIcon];
		if (image){
			[self setIcon:image];
			return YES;
		}
	}
	
	
	NSString *bestType=[self primaryType];
  
	
  id handler=[typeHandlers objectForKey:bestType];
  if ([handler respondsToSelector:@selector(loadIconForObject:)])
    return [handler loadIconForObject:self];
  
	
  
  //// if ([primaryType hasPrefix:@"QSCsontact"])
  //     return NO;
  
  
	if ([IMAGETYPES intersectsSet:[NSSet setWithArray:[data allKeys]]]){
    [self setIcon:[[[NSImage alloc]initWithPasteboard:(NSPasteboard *)self]autorelease]];
		[[self icon]createIconRepresentations];
		
		[[self icon] createRepresentationOfSize:NSMakeSize(128,128)];
    
  }
  
  // file type for sound clipping: clps
  if (![self icon]){
    [self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
    return NO;
  }
  
  return NO;
}

- (BOOL)unloadIcon{
  if (![self iconLoaded]) return NO;
	if ([self retainsIcon])return NO;
	
	[self setIcon:nil];
	[self setIconLoaded:NO];
	[iconLoadedSet removeObject:self];
  return YES;
}

- (NSImage *)icon{
  lastAccess=[NSDate timeIntervalSinceReferenceDate];
  globalLastAccess=lastAccess;
	
	if (icon) return icon;
	//    if ([[self cache] objectForKey:kQSObjectIcon]) return [[self cache] objectForKey:kQSObjectIcon];
  
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(setQuickIconForObject:)])
		[handler setQuickIconForObject:self];
  
	else if ([[self primaryType] isEqualToString:QSContactPhoneType]) [self setIcon: [NSImage imageNamed:@"ContactPhone"]];
  else if ([[self primaryType] isEqualToString:QSContactAddressType]) [self setIcon: [NSImage imageNamed:@"ContactAddress"]];
  //    else if ([[self primaryType] isEqualToString:QSContactEmailType]) [self setIcon: [NSImage imageNamed:@"ContactEmail"]];
  
  else if ([[self types] containsObject:@"BookmarkDictionaryListPboardType"]){
    [self setIcon:[NSImage imageNamed:@"FadedDefaultBookmarkIcon"]];
  }
  
  else    
    [self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
  
	if(icon)return icon;
	//    return [[self cache] objectForKey:kQSObjectIcon];
	return nil;
}


- (void)setIcon:(NSImage *)newIcon {
	//	if (newIcon){
	[icon autorelease];
	icon = [newIcon retain];
	[icon setScalesWhenResized:YES];
	[icon setCacheMode:NSImageCacheNever];
	
	//[[self cache]setObject:newIcon forKey:kQSObjectIcon];
	//	}else{
	//[[self cache]removeObjectForKey:kQSObjectIcon];
	//	}
	
}

- (NSArray *)types{
	NSMutableArray  *array=[[[data allKeys]mutableCopy]autorelease];
  
  return array;
}

- (NSArray *)decodedTypes{
  NSMutableArray *decodedTypes=[NSMutableArray arrayWithCapacity:[data count]];
  NSEnumerator *typesEnumerator=[data keyEnumerator];
  NSString *thisType;
  while(thisType=[typesEnumerator nextObject]){
    [decodedTypes addObject:[thisType decodedPasteboardType]];
  }
  return decodedTypes;
}

- (int)count{
	if (![self primaryType]){
		NSEnumerator *e=[[[self dataDictionary] allValues]objectEnumerator];
		id value;
		int count=1;
		while(value=[e nextObject]){
			if ([value isKindOfClass:[NSArray class]]) count=MAX([(NSArray *)value count],count);
		}
		return count;
	}
  id priObj=[self primaryObject];
  if ([priObj isKindOfClass:[NSArray class]])
    return [(NSArray *)priObj count];
  return 1;
}

- (int)primaryCount{
	return [self count];
}

- (QSBasicObject * )parent{
  QSBasicObject * parent=nil;
  
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(parentOfObject:)])
    parent=[handler parentOfObject:self];
  
  
  if (!parent)
    parent=[objectDictionary objectForKey:[meta objectForKey:kQSObjectParentID]];
  return parent;
}


- (void) setParentID:(NSString *)parentID{
  if (parentID) [data setObject:parentID forKey:kQSObjectParentID];     
    }




- (BOOL)childrenValid{
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(objectHasValidChildren:)])
    return [handler objectHasValidChildren:self];
  
  return NO;
}

- (BOOL)unloadChildren{
	//QSLog(@"unload children of %@",self);
	
  if (![self childrenLoaded])return NO;
	//QSLog(@"unloaded %@ %x",self,self);
  [self setChildren:nil];
  [self setAltChildren:nil];
  flags.childrenLoaded=NO;
  [self setChildrenLoadedDate:0];
	[childLoadedSet removeObject:self];
  return YES;
}

- (void)loadChildren{
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(loadChildrenForObject:)]){
		
    //	QSLog(@"load %x",self);
    
    if ([handler loadChildrenForObject:self]){
      //		QSLog(@"xload %@",self);
      flags.childrenLoaded=YES;
			[self setChildrenLoadedDate:[NSDate timeIntervalSinceReferenceDate]];
			lastAccess=[NSDate timeIntervalSinceReferenceDate];
			globalLastAccess=lastAccess;
			
			[childLoadedSet addObject:self];
		}
  }
  
  NSArray *components=[self objectForCache:kQSObjectComponents];
  if (components)
    [self setChildren:components];
	
}



-(BOOL)hasChildren{
	
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(objectHasChildren:)])
    return [handler objectHasChildren:self];
  return NO;
}



- (id)copyWithZone:(NSZone *)zone{
	//QSLog(@"copied!");
	return [self retain];
  return NSCopyObject(self, 0, zone);
}
@end













//Standard Accessors

@implementation QSObject (Accessors)

- (NSString *)identifier{    if (identifier)
	return identifier;
	if (flags.noIdentifier)
		return nil;
	
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(identifierForObject:)]){
    [self setIdentifier:[handler identifierForObject:self]];
  }
  if (!identifier)
		//    if (![self objectForMeta:kQSObjectObjectID]){
  flags.noIdentifier=YES;
	
	
	// if (VERBOSE) QSLog(@"missing id for object:%@",self);
	//  }
  return identifier;
	//    return [self objectForMeta:kQSObjectObjectID];
}

- (void)setIdentifier:(NSString *)newIdentifier {
  [identifier release];
	if (identifier){
		[objectDictionary removeObjectForKey:identifier];
		[objectDictionary setObject:self forKey:newIdentifier];
	}
	identifier = [newIdentifier retain];
  if (newIdentifier)
    [meta setObject:newIdentifier forKey:kQSObjectObjectID];
	
}

- (NSString *)name {
	if (!name) name=[[meta objectForKey:kQSObjectPrimaryName] retain];
	return name;
	//	return 	[meta objectForKey:kQSObjectPrimaryName];
}

- (void)setName:(NSString *)newName {
  [name release];
  if ([newName length]>255) newName=[newName substringToIndex:255]; 
	// ***warning   ** this should take first line only?
	
	[rankData setName:[newName purifiedString]];
	
	name = [newName retain];
	if (newName)[meta setObject:newName forKey:kQSObjectPrimaryName];
}


- (NSArray *)children {
  if (!flags.childrenLoaded || ![self childrenValid])
    [self loadChildren];
	
	return [cache objectForKey:kQSObjectChildren];
	//   return [[children retain] autorelease];
	
}

- (void)setChildren:(NSArray *)newChildren {
	if (newChildren) [[self cache]setObject:newChildren forKey:kQSObjectChildren];
	//    [children release];
	//   children = [newChildren retain];
}

- (NSArray *)altChildren {
	if (!flags.childrenLoaded || ![self childrenValid])
    [self loadChildren];
	return [cache objectForKey:kQSObjectAltChildren];
	//   if (!childrenLoaded)
	//       [self loadChildren];
	//    return [[altChildren retain] autorelease];
}

- (void)setAltChildren:(NSArray *)newAltChildren {
	if (newAltChildren)
		[[self cache]setObject:newAltChildren forKey:kQSObjectAltChildren];
	//    [altChildren release];
	// altChildren = [newAltChildren retain];
}


- (NSString *)label {
	// if (!label) return nil; //[self name];
	return label;
	return 	[meta objectForKey:kQSObjectAlternateName];
	
}
- (void)setLabel:(NSString *)newLabel {
	if (![newLabel isEqualToString:[self name]]){
		[label release];
		label = [newLabel retain];
		[rankData setLabel:[newLabel purifiedString]];
		if (newLabel)[meta setObject:newLabel forKey:kQSObjectAlternateName];
		else 	[meta removeObjectForKey:kQSObjectAlternateName];
	}		    
}


- (NSString *)kind{
	
	NSString *kind=[meta objectForKey:kQSObjectKind];
  if (kind) return kind;
  
  id handler=[typeHandlers objectForKey:[self primaryType]];
  if ([handler respondsToSelector:@selector(kindOfObject:)]){
		kind=[handler kindOfObject:self];
		if (kind){
			[meta setObject:kind forKey:kQSObjectKind];
			return kind;
		}
  }
	
	return [self primaryType];
	
	
	
}

- (NSString *)primaryType {
	// return [meta objectForKey:QSObjectPrimaryType];
  if (!primaryType)
		primaryType=[[self guessPrimaryType]retain];
	return primaryType;
}
- (void)setPrimaryType:(NSString *)newPrimaryType {
	//	[meta setObject:newPrimaryType forKey:kQSObjectPrimaryType];
  [primaryType release];
  primaryType = [newPrimaryType retain];
	[meta setObject:newPrimaryType forKey:kQSObjectPrimaryType];
}

- (NSMutableDictionary *)dataDictionary {
return data; }

- (NSMutableDictionary *)archiveDictionary {
	NSMutableDictionary *archive=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                data, kData,
                                meta, kMeta,
                                nil];
  return archive;
}


- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary {
  [data autorelease];
  data = [newDataDictionary retain];
} 

/*
 - (id)contents { return [[contents retain] autorelease]; }
 
 - (void)setContents:(id)newContents {
 [contents release];
 contents = [newContents retain];
 }
 */

- (BOOL)iconLoaded { return flags.iconLoaded; }
- (void)setIconLoaded:(BOOL)flag {
  flags.iconLoaded = flag;
}


- (BOOL)retainsIcon  { return flags.retainsIcon; };
- (void)setRetainsIcon:(BOOL)flag{	
  flags.retainsIcon = (flag>0);
}

- (BOOL)childrenLoaded { return flags.childrenLoaded; }
- (void)setChildrenLoaded:(BOOL)flag {
  flags.childrenLoaded = flag;
}


- (BOOL)contentsLoaded { return flags.contentsLoaded; }
- (void)setContentsLoaded:(BOOL)flag {
  flags.contentsLoaded = flag;
}
- (NSTimeInterval)childrenLoadedDate { return [[meta objectForKey:kQSObjectChildrenLoadDate]doubleValue]; }
- (void)setChildrenLoadedDate:(NSTimeInterval)newChildrenLoadedDate {
	[meta setObject:[NSNumber numberWithDouble:newChildrenLoadedDate] forKey:kQSObjectChildrenLoadDate];
}


- (NSTimeInterval)lastAccess { return lastAccess; }
- (void)setlastAccess:(NSTimeInterval)newlastAccess {
  lastAccess = newlastAccess;
}
@end



@implementation QSObject (Archiving)
+ (id)objectFromFile:(NSString *)path{
  return [[[self alloc]initFromFile:path]autorelease];
}
- (id)initFromFile:(NSString *)path{
  if (self = [self init]){
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSDictionary *newData = [dictionary objectForKey:kData];
    NSDictionary *newMeta = [dictionary objectForKey:kMeta];
    if (!newData) newData = dictionary;
    
    [data setDictionary:newData];
    [meta setDictionary:newMeta];
    [self extractMetadata];
  }
  return self;
}
- (void)writeToFile:(NSString *)path{
  
  
  NSString *uti = [UTTypeCreatePreferredIdentifierForTag(kUTTagClassNSPboardType,
                                                         [self primaryType],
                                                         NULL) autorelease];
  
  if (uti) [meta setObject:uti forKey:(NSString *)kMDItemContentType];
  if (uti) [meta setObject:uti forKey:(NSString *)kMDItemCopyright];
  
  
  NSDictionary *dictionary = [NSMutableDictionary dictionary];
  [dictionary setObject:data forKey:kData];
  [dictionary setObject:meta forKey:kMeta];
  
  NSData *fileData = [NSPropertyListSerialization dataFromPropertyList:dictionary
                                             format:NSPropertyListBinaryFormat_v1_0
                                   errorDescription:nil];
  
  
  

  
  [fileData writeToFile:path atomically:YES];
}
- (id)initWithCoder:(NSCoder *)coder {
  self=[self init];
  // [self initWithDictionary:[coder decodeObject]];
	
	[meta setDictionary:[coder decodeObjectForKey:@"meta"]];
  [data setDictionary:[coder decodeObjectForKey:@"data"]];
	[self extractMetadata];
	id dup=[self findDuplicateOrRegisterID];
	if (dup) return dup;
  return self;
}

- (void)extractMetadata{
	if ([data objectForKey:kQSObjectPrimaryName])
		[self setName:[data objectForKey:kQSObjectPrimaryName]];
	if ([data objectForKey:kQSObjectAlternateName])
		[self setLabel:[data objectForKey:kQSObjectAlternateName]];
	if ([data objectForKey:kQSObjectPrimaryType])
		[self setPrimaryType:[data objectForKey:kQSObjectPrimaryType]];
	if ([data objectForKey:kQSObjectIcon]){
		id iconRef=[data objectForKey:kQSObjectIcon];
		if ([iconRef isKindOfClass:[NSData class]])
			[self setIcon:[[[NSImage alloc]initWithData:iconRef]autorelease]];
		else if ([iconRef isKindOfClass:[NSString class]])
			[self setIcon:[QSResourceManager imageNamed:iconRef]];
		[self setIconLoaded:YES];
	}
	
	if ([meta objectForKey:kQSObjectObjectID])
		identifier=[[meta objectForKey:kQSObjectObjectID]retain];
	if ([meta objectForKey:kQSObjectPrimaryType])
		primaryType=[[meta objectForKey:kQSObjectPrimaryType]retain];
	if ([meta objectForKey:kQSObjectPrimaryName])
		name=[[meta objectForKey:kQSObjectPrimaryName]retain];
	if ([meta objectForKey:kQSObjectAlternateName])
		label=[[meta objectForKey:kQSObjectAlternateName]retain];

	[data removeObjectForKey:QSProcessType]; // Don't carry over process info
}


- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:meta forKey:@"meta"];
  [coder encodeObject:data forKey:@"data"];
}


- (id)findDuplicateOrRegisterID{
	id dup=[QSObject objectWithIdentifier:[self identifier]];
	if (dup){
		[self release];
		return [dup retain];
	}
	if ([self identifier])
		[QSObject registerObject:self withIdentifier:[self identifier]];
	return nil;
}

@end

@implementation QSRankInfo
+(id)rankDataWithObject:(QSBasicObject *)object{
	return [[[self alloc]initWithObject:object]autorelease];
}
-(id)initWithObject:(QSBasicObject *)object{
	if (self=[super init]){
		NSString *theIdentifier=[object identifier];
		name=[[QSDefaultStringRanker alloc]initWithString:[object name]];
		label=[[QSDefaultStringRanker alloc]initWithString:[object label]];
		[self setIdentifier:theIdentifier];
		[self setMnemonics:[[QSMnemonics sharedInstance] objectMnemonicsForID:identifier]];
		[self setOmitted:[QSLib itemIsOmitted:object]];
  }
  return self;
}
- (void) dealloc{
  [name release];
  [label release];
  [mnemonics release];
  [identifier release];
  [super dealloc];
}

- (NSString *)identifier { return [[identifier retain] autorelease]; }

- (void)setIdentifier:(NSString *)anIdentifier {
  if (identifier != anIdentifier) {
    [identifier release];
    identifier = [anIdentifier retain];
  }
}

- (NSString *)name { return [[name retain] autorelease]; }

- (void)setName:(NSString *)aName {
  if (name != aName) {
    [name release];
		
		name=[[QSDefaultStringRanker alloc]initWithString:aName];
  }
}


- (NSString *)label { return [[label retain] autorelease]; }

- (void)setLabel:(NSString *)aLabel {
  if (label != aLabel) {
    [label release];
    //   label = [aLabel retain];
		
		label=[[QSDefaultStringRanker alloc]initWithString:aLabel];
  }
}


- (NSDictionary *)mnemonics { return [[mnemonics retain] autorelease]; }

- (void)setMnemonics:(NSDictionary *)aMnemonics {
  if (mnemonics != aMnemonics) {
    [mnemonics release];
    mnemonics = [aMnemonics retain];
  }
}

- (BOOL)omitted { return omitted; }
- (void)setOmitted:(BOOL)flag {
	omitted = flag;
}

@end

@implementation QSBasicObject

- (id) init{
  if (self=[super init]){
		rankData=nil;
		ranker=nil;
  }
  return self;
}

- (void) dealloc{
	[ranker release];
  [rankData release];
  [super dealloc];
}
//- (BOOL)respondsToSelector:(SEL)aSelector{
//	if ( [super respondsToSelector:aSelector]) return YES;
//	if (VERBOSE)QSLog(@"select %@",NSStringFromSelector(aSelector));
//	return NO;
//}
- (QSRankInfo *)getRankData{
	QSRankInfo *oldRankData;
	oldRankData=rankData;
	rankData=[[QSRankInfo rankDataWithObject:self]retain];
	[oldRankData release];
	return rankData;
}

- (id <QSObjectRanker>)getRanker{
	id oldRanker;
	oldRanker=ranker;
	ranker=[[QSDefaultObjectRanker alloc]initWithObject:self];
	[oldRanker release];
	return ranker;
}
- (id <QSObjectRanker>)ranker{
	if (!ranker)return [self getRanker];
	return ranker;
}

- (void)updateMnemonics{
	[self getRanker];
  //	[rankData setMnemonics:[[QSMnemonics sharedInstance] objectMnemonicsForID:[self identifier]]];	
}
- (id)this{return [[self retain]autorelease];}
- (id)thisWithIcon{
	[self loadIcon];
	return [[self retain]autorelease];
}

- (void)setEnabled:(BOOL)flag{
	[QSLib setItem:self isOmitted:!flag];	
}
- (BOOL)enabled{
	return (BOOL)![QSLib itemIsOmitted:self];	
}

- (void)setOmitted:(BOOL)flag {
	[[self ranker] setOmitted:flag];
}

- (NSString *)kind{
	return @"Object";
}

- (NSString *)label{return nil;}
- (NSString *)name{return @"Object";}
- (NSString *)primaryType{return nil;}
- (id)primaryObject{return nil;}
- (BOOL) containsType:(NSString *)aType{
	return [[self types]containsObject:aType];
}
- (NSArray *)types{return nil;}
- (int)primaryCount{return 0;}
- (BOOL)loadIcon{return YES;}
- (NSImage *)icon{
	//[NSBundle bundleForClass:[self class]]
	return [NSImage imageNamed:@"Object"];	
}
- (NSComparisonResult)compare:(id)other{
	return [[self name]	compare:[other name]];
}


- (NSImage *)loadedIcon{
	if (![self iconLoaded])[self loadIcon];
	return [self icon];
}
- (void)becameSelected{ return;}

- (BOOL)iconLoaded { return YES; }
- (QSBasicObject *)parent{return nil;}
- (NSString *)displayName{return [self name];}
- (NSString *)details{return nil;}
- (NSString *)toolTip{return nil;}
- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped{return NO;}
- (id)objectForType:(id)aKey{return nil;}
- (NSArray *)arrayForType:(id)aKey{return nil;}
- (NSEnumerator *)enumeratorForType:(NSString *)aKey{return [[self arrayForType:aKey]objectEnumerator];}
- (float)score{return 0.0;}
- (int)order{return NSNotFound;}
- (bool)hasChildren{return NO;}
- (NSArray *)children {return nil;}
- (NSArray *)altChildren {return nil;}
- (NSString *)description{return [self name];}
- (float)rankModification{return 0;}
- (NSString *)identifier{return nil;}
- (NSComparisonResult)scoreCompare:(QSBasicObject *)object{
  return NSOrderedSame;   
}

- (NSArray *)siblings{
  
  return [[self parent]children];
}
- (NSArray *)altSiblings{return [[self parent]altChildren];}


- (NSComparisonResult)nameCompare:(QSBasicObject *)object{
  return [[self name] caseInsensitiveCompare:[object name]];   
}
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard{
  return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:nil];
}
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes{
  return [self putOnPasteboard:pboard declareTypes:nil includeDataForTypes:includeTypes];
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes{
  return NO;
}
- (QSBasicObject *)resolvedObject{return self;}
@end

