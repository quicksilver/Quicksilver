#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSResourceManager.h"
#import "QSTypes.h"

#define kQSObjectClass @"class"

@implementation QSObject (PropertyList)
+ (id)objectWithDictionary:(NSDictionary *)dictionary {
    if(dictionary == nil)
        return nil;
    if (DEBUG_UNPACKING && VERBOSE)
        NSLog(@"%@ %@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), dictionary);
    id obj = [dictionary objectForKey:kQSObjectClass];
    if(obj)
        obj = [[NSClassFromString(obj) alloc] initWithDictionary:dictionary];
    
    if(!obj)
        obj = [[self alloc] initWithDictionary:dictionary];
    
    if (!obj && DEBUG_UNPACKING)
        NSLog(@"%@ %@ failed creating object with dict %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), dictionary);
    
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
	int i;
	for (i = 0; i<[dictionaryArray count]; i++) {
		NS_DURING
			[dictObjectArray addObject:[self objectWithDictionary:[dictionaryArray objectAtIndex:i]]];
		NS_HANDLER
			NSLog(@"Bad Object Encountered:\r%@", [dictionaryArray objectAtIndex:i]);
		NS_ENDHANDLER
	}
	return dictObjectArray;
}

- (void)changeFilesToPaths {
	id object = [data objectForKey:QSFilePathType]; //[self arrayForType:];
	if (object)
		[data setObject:[object valueForKey:@"stringByStandardizingPath"] forKey:QSFilePathType];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (DEBUG_UNPACKING && VERBOSE)
        NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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
        if (dup) return dup;
        if ([self containsType:QSFilePathType])
            [self changeFilesToPaths];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            data, kData,
            meta, kMeta,
            NSStringFromClass([self class]), kQSObjectClass,
            nil];
}
@end
