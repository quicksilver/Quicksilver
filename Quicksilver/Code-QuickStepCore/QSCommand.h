#import <Foundation/Foundation.h>
#import <QSCore/QSObject.h>
#import <QSCore/QSProxyObject.h>
@class QSAction;

@interface QSCommandObjectHandler : NSObject
@end

@interface QSCommand : QSObject <NSCoding> {
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

- (void)executeFromMenu:(id)sender;

- (NSArray *)validIndirects;

- (QSObject *)objectValue __attribute__((deprecated));

- (QSObject *)dObject;
- (QSAction *)aObject;
- (QSObject *)iObject;

// returns YES if the current QSCommand can execute threaded (in a background thread, and not on the main thread)
- (BOOL)canThread;

- (void)setDirectObject:(QSObject*)dObject;
- (void)setActionObject:(QSAction*)aObject;
- (void)setIndirectObject:(QSObject*)iObject;

- (void)writeToFile:(NSString *)path;
@end
