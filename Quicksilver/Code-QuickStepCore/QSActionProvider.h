

#import <Foundation/Foundation.h>

#import "QSAction.h"
#import "QSObject.h"

@protocol QSActionProvider
//- (NSString *)identifier;
//- (NSString *)label;
- (NSArray *)types;
- (NSArray *)fileTypes;
- (NSArray *)actions;
- (NSString *)titleForAction:(NSString *)action;
- (int)argumentCountForAction:(NSString *)action;
- (NSImage *)iconForAction:(NSString *)action;
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject;
- (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject;

- (QSAction *)initializeAction:(QSAction *)action;

@end

@interface QSActionProvider : NSObject <QSActionProvider> {
//	NSArray *actions;
}
+ (id)provider;
//- (NSArray *)actions;
//- (void)setActions:(NSArray *)newActions;
@end
