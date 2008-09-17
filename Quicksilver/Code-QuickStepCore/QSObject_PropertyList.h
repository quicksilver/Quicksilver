

#import <Foundation/Foundation.h>

#import "QSObject.h"

@interface QSObject (PropertyList)
+ (id)objectWithDictionary:(NSDictionary *)dictionary;
+ (id)objectsWithDictionaryArray:(NSArray *)dictionaryArray;

+ (id)objectWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType;
+ (id)objectWithType:(NSString *)type value:(id)value name:(NSString *)newName;

- (id)initWithString:(NSString *)string name:(NSString *)aName type:(NSString *)aType;
- (id)initWithType:(NSString *)type value:(id)value name:(NSString *)newName;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
@end
