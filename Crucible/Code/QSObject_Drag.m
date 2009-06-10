

#import "QSObject_Drag.h"
#import "QSDebug.h"

@implementation QSObject (Drag)

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object {
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
    id handler = [self handlerForSelector:@selector(operationForDrag:ontoObject:withObject:)];
    
    if (handler)
        return [handler operationForDrag:sender ontoObject:self withObject:object];
    
    return sourceDragMask & NSDragOperationGeneric;
}

- (NSString *)actionForDragOperation:(NSDragOperation)operation withObject:(QSBasicObject *)object {
    id handler = [self handlerForSelector:@selector(actionForDragMask:ontoObject:withObject:)];
    
    if (handler)
        return [handler actionForDragMask:operation ontoObject:self withObject:object];
    
    return nil;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object {
    return YES;
}

@end
