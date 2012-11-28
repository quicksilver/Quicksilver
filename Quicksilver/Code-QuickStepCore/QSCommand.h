#import <Foundation/Foundation.h>
#import <QSCore/QSObject.h>

@class QSAction;

@interface QSCommandObjectHandler : NSObject
@end

@interface QSCommand : QSObject {
    QSObject *dObject;
    QSAction *aObject;
    QSObject *iObject;
}
+ (QSCommand *)commandWithDirectObject:(QSObject *)dObject actionObject:(QSAction *)aObject indirectObject:(QSObject *)iObject;
+ (QSCommand *)commandWithInfo:(id)info;
+ (QSCommand *)commandWithDictionary:(NSDictionary *)newDict;
+ (QSCommand *)commandWithIdentifier:(NSString *)identifier;
+ (QSCommand *)commandWithFile:(NSString *)path;

- (QSCommand *)initWithDirectObject:(QSObject *)dObject actionObject:(QSAction *)aObject indirectObject:(QSObject *)iObject;

- (QSObject *)execute;
- (QSObject *)executeIgnoringModifiers;

- (NSArray *)validIndirects;

- (QSObject *)objectValue __attribute__((deprecated));

- (QSObject *)dObject;
- (QSAction *)aObject;
- (QSObject *)iObject;
- (void)setDirectObject:(QSObject*)dObject;
- (void)setActionObject:(QSAction*)aObject;
- (void)setIndirectObject:(QSObject*)iObject;

- (void)writeToFile:(NSString *)path;
@end
