

#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSResourceManager.h"
#import "QSTypes.h"


@implementation QSObject (PropertyList)

+ (id)objectWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType {
    return [[[QSObject alloc] initWithString:string name:aName type:aType] autorelease];
}

- (id)initWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType {
    if ((self = [self init])) {         
        [self setName:aName];
        [self setPrimaryType:aType];
        [data setObject:string forKey:aType];
        [data setObject:string forKey:NSStringPboardType];       
    }
    return self;    
}

+ (id)objectWithType:(NSString *)type value:(id)value name:(NSString *)newName{
    return[[(QSObject *)[QSObject alloc]initWithType:(NSString *)type value:(id)value name:(NSString *)newName]autorelease];
}

- (id)initWithType:(NSString *)type value:(id)value name:(NSString *)newName{
    if ((self = [self init])){
        [data setObject:value forKey:type];
        [self setName:newName];
        [self setPrimaryType:type];
    }
    return self;
} 
+ (id)objectsWithDictionaryArray:(NSArray *)dictionaryArray{
    NSMutableArray *dictObjectArray=[NSMutableArray arrayWithCapacity:[dictionaryArray count]];
    for (id loopItem in dictionaryArray){
        NS_DURING
            [dictObjectArray addObject:[QSObject objectWithDictionary:loopItem]];
        NS_HANDLER
            //QSLog(@"Bad Object Encountered:\r%@",[dictionaryArray objectAtIndex:i]);
        NS_ENDHANDLER
    }
    return dictObjectArray;
}

- (void)changeFilesToPaths{
	id object=[data objectForKey:QSFilePathType];//[self arrayForType:];
	if (object)
		[data setObject:[object valueForKey:@"stringByStandardizingPath"] forKey:QSFilePathType];
}

@end