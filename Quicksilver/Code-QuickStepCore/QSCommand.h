#import <Foundation/Foundation.h>
#import "QSObject.h"



@interface QSCommandObjectHandler : NSObject
@end
@class QSAction;
@interface QSCommand : QSBasicObject{
    NSMutableDictionary *oDict;
}
+(id)commandWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject;
-(id)initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject;
+(id)commandWithDictionary:(NSDictionary *)newDict;
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
