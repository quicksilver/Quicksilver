#import <Foundation/Foundation.h>
#import "QSObject.h"



@interface QSCommandObjectHandler : NSObject
@end
@class QSAction;
@interface QSCommand : QSBasicObject {
	NSMutableDictionary *oDict;
}
+ (QSCommand *)commandWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject;
+ (QSCommand *)commandWithDictionary:(NSDictionary *)newDict;
+ (QSCommand *)commandWithInfo:(id)command;
+ (QSCommand *)commandWithFile:(NSString *)path;

- (QSCommand *)initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject;
- (QSCommand *)initWithDictionary:(NSDictionary *)newDict;

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
