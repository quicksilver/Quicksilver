

#import <Foundation/Foundation.h>
#import <QSCrucible/QSObject.h>

@class QSBasicObject;

@protocol QSObjectHandler_Dragging
- (NSDragOperation)operationForDrag:(id <NSDraggingInfo>) ontoObject:(QSBasicObject *)destObject withObject:(QSBasicObject *)srcObject;
- (NSString *)actionForDragMask:(NSDragOperation) ontoObject:(QSBasicObject *)destObject withObject:(QSBasicObject *)srcObject;
@end

@interface QSObject (Dragging)
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object;
- (NSString *)actionForDragOperation:(NSDragOperation)operation withObject:(QSBasicObject *)object;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object;
@end
