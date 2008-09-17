#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSResourceManager.h"
#import "QSTypes.h"

@implementation QSObject (PropertyList)

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
			[dictObjectArray addObject:[QSObject objectWithDictionary:[dictionaryArray objectAtIndex:i]]];
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
        NSEnumerator *e = [dataDict keyEnumerator];
        NSString *key = nil;
        NSDictionary *objDict = nil;
        while(key = [e nextObject]) {
            id obj = nil;
            objDict = [dataDict objectForKey:key];
            if([objDict isKindOfClass:[NSDictionary class]]) {
                id handler = nil;
                if (handler = [self handlerForType:key selector:@selector(objectForRepresentation:)])
                    obj = [handler objectForRepresentation:objDict];
                if (!obj && DEBUG_UNPACKING)
                    NSLog(@"handler failed to provide representation, using dict %@", objDict);
            }
            [data setObject:(obj ? obj : objDict) forKey:key];
        }
        [meta setDictionary:[dictionary objectForKey:kMeta]];
        
        /*    } else {
         NSLog(@"error: no data dictionary in object %@", dictionary);
         [data setDictionary:dictionary];
         // ***warning  * these initializers might not be efficient*/
        
        [self extractMetadata];
        
        // ***warning  * should this update the name for files?
        id dup = [self findDuplicateOrRegisterID];
        if (dup) return dup;
        if ([self containsType:QSFilePathType])
            [self changeFilesToPaths];
    }
    return self;
}

- (NSMutableDictionary *)dictionaryRepresentation {
    NSMutableDictionary *archive = [super dictionaryRepresentation];
    NSMutableDictionary *repData = [[NSMutableDictionary alloc] init];
    NSEnumerator *e = [data keyEnumerator];
    NSString *key = nil;
    id obj = nil;
    while (key = [e nextObject]) {
        id handler = nil;
        if (handler = [self handlerForType:key selector:@selector(representationForObject:)]) {
            obj = [handler representationForObject:self];
        }
        if (!obj) {
            obj = [data objectForKey:key];
            if([obj respondsToSelector:@selector(dictionaryRepresentation)])
                obj = [obj dictionaryRepresentation];
        }
        if (!obj)
            obj = [data objectForKey:key];
        
        [repData setObject:obj
                    forKey:key];
    }
    [archive setObject:repData forKey:kData];
    [archive setObject:meta forKey:kMeta];
    [repData release];
    return archive;
}
@end
