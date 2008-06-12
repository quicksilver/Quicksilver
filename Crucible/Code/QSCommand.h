#import <Foundation/Foundation.h>

#import "QSObject.h"
@class QSAction, QSObject;

@interface QSCommandObjectHandler : NSObject
@end

@interface QSCommand : QSBasicObject{
    NSMutableDictionary *oDict;
}
+(id)commandWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject;
+(id)commandWithDictionary:(NSDictionary *)newDict;
+ (id)commandWithFile:(NSString *)path;
-(id)initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject;
-(id)initWithDictionary:(NSDictionary *)newDict;

+ (QSCommand *)commandWithInfo:(id)command;
- (QSObject *)execute;
- (NSString *)description;

- (NSDictionary *)dictionaryRepresentation;
- (void)writeToFile:(NSString *)path;
- (QSAction *)aObject;
- (QSObject *)dObject;
- (QSObject *)iObject;
- (NSArray *)validIndirects;
- (void)setDObject:(id)dObject;
- (QSObject *)executeIgnoringModifiers;
@end
