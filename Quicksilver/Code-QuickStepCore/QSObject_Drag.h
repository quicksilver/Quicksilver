

#import <Foundation/Foundation.h>
#import "QSObject.h"
@interface QSObject (Drag)
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object;
- (NSString *)actionForDragOperation:(NSDragOperation)operation withObject:(QSBasicObject *)object;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object;
@end
