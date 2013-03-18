#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSResourceManager.h"
#import "QSTypes.h"

#define kQSObjectClass @"class"

@implementation QSObject (PropertyList)
+ (id)objectWithDictionary:(NSDictionary *)dictionary {
    if(dictionary == nil)
        return nil;
	
#ifdef DEBUG
    if (DEBUG_UNPACKING && VERBOSE)
        NSLog(@"%@ %@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), dictionary);
#endif
	
    id obj = [dictionary objectForKey:kQSObjectClass];
    if(obj)
        obj = [[NSClassFromString(obj) alloc] initWithDictionary:dictionary];
    
    if(obj == nil)
        obj = [[self alloc] initWithDictionary:dictionary];

#ifdef DEBUG
    if (!obj && DEBUG_UNPACKING)
        NSLog(@"%@ %@ failed creating object with dict %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), dictionary);
#endif
    
    return [obj autorelease];
}

+ (id)objectWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType {
	return [[[QSObject alloc] initWithString:string name:aName type:aType] autorelease];
}

- (id)initWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType {
	if (self = [self init]) {
		[self setName:aName];
		[self setPrimaryType:aType];
		[data setObject:string forKey:aType];
		[data setObject:string forKey:NSStringPboardType];
	}
	return self;
}

+ (id)objectWithType:(NSString *)type value:(id)value name:(NSString *)newName {
	return[[(QSObject *)[QSObject alloc] initWithType:(NSString *)type value:(id)value name:(NSString *)newName] autorelease];
}
- (id)initWithType:(NSString *)type value:(id)value name:(NSString *)newName {
	if (self = [self init]) {
		[data setObject:value forKey:type];
		[self setName:newName];
		[self setPrimaryType:type];
	}
	return self;
}
+ (id)objectsWithDictionaryArray:(NSArray *)dictionaryArray {
	NSMutableArray *dictObjectArray = [NSMutableArray arrayWithCapacity:[dictionaryArray count]];
	for (id loopItem in dictionaryArray) {
		@try {
            [dictObjectArray addObject:[self objectWithDictionary:loopItem]];
        }
        @catch (NSException *e) {
            NSLog(@"Bad Object Encountered: \"%@\" => %@", loopItem, e);
        }
	}
	return dictObjectArray;
}

- (void)changeFilesToPaths {
	id object = [data objectForKey:QSFilePathType]; //[self arrayForType:];
	if (object)
		[data setObject:[object valueForKey:@"stringByStandardizingPath"] forKey:QSFilePathType];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	
#ifdef DEBUG
    if (DEBUG_UNPACKING && VERBOSE)
        NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    NSDictionary *dataDict = [dictionary objectForKey:kData];
    NSDictionary *metaDict = [dictionary objectForKey:kMeta];
    if (!dataDict && !metaDict)
        return nil;
    
 	if (self = [self init]) {
        [data setDictionary:dataDict];
        [meta setDictionary:metaDict];
        
        [self extractMetadata];
        
        // ***warning  * should this update the name for files?
        id dup = [self findDuplicateOrRegisterID];
        if (dup) return [dup retain];
        if ([self containsType:QSFilePathType])
            [self changeFilesToPaths];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    // copies of data and meta are made to avoid them being mutated down the line
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [[data copy] autorelease], kData,
            [[meta copy] autorelease], kMeta,
            NSStringFromClass([self class]), kQSObjectClass,
            nil];
}
@end
