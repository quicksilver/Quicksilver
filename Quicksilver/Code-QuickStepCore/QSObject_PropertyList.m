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
    
    return obj;
}

+ (id)objectWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType {
	return [[QSObject alloc] initWithString:string name:aName type:aType];
}

- (id)initWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType {
	if (self = [self init]) {
		[self setName:aName];
		[self setPrimaryType:aType];
		[data setObject:string forKey:aType];
		[data setObject:string forKey:QSTextType];
	}
	return self;
}

+ (id)objectWithType:(NSString *)type value:(id)value name:(NSString *)newName {
	return[(QSObject *)[QSObject alloc] initWithType:(NSString *)type value:(id)value name:(NSString *)newName];
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

    self = [self init];
    if (!self) return nil;

    [data setDictionary:dataDict];
    [meta setDictionary:metaDict];

    [self extractMetadata];

    // Check immediately if we already have loaded that object
    // ***warning  * should this update the name for files?
    id dup = [QSLib objectWithIdentifier:identifier];
    if (dup) return dup;

    // Backwards compatibility: make sure all dict keys are UTIs (where applicable)
    for (NSMutableDictionary *dict in @[data, meta]) {
        // Create a temp dict to add any new UTI key/value pairs to. We can't add them directly to data/meta in the enumerate block (cannot mutate whilst enumerating)
        NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            NSString *UTIString = QSUTIForAnyTypeString(key);
            if (UTIString && ![key isEqualToString:UTIString]) {
                [tempDict setObject:obj forKey:UTIString];
            }
        }];
        [dict addEntriesFromDictionary:tempDict];
    }

    if ([self containsType:QSFilePathType] || [self containsType:NSFilenamesPboardType]) {
        [self changeFilesToPaths];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    // copies of data and meta are made to avoid them being mutated down the line
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [data copy], kData,
            [meta copy], kMeta,
            NSStringFromClass([self class]), kQSObjectClass,
            nil];
}
@end
