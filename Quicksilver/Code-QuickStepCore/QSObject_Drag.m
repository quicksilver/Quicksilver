

#import "QSObject_Drag.h"
#import "QSDebug.h"


@implementation QSObject (Drag)

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object{
    NSDragOperation sourceDragMask=[sender draggingSourceOperationMask];
    id handler=[self handler];
    if ([handler respondsToSelector:@selector(operationForDrag:ontoObject:withObject:)])
        return [handler operationForDrag:sender ontoObject:self withObject:object];
    
    //if (VERBOSE) NSLog(@"Unhandled drag");
    return sourceDragMask&NSDragOperationGeneric;
}


- (NSString *)actionForDragOperation:(NSDragOperation)operation withObject:(QSBasicObject *)object{
    id handler=[self handler];
    if ([handler respondsToSelector:@selector(actionForDragMask:ontoObject:withObject:)])
        return [handler actionForDragMask:operation ontoObject:self withObject:object];
    return nil;
}




- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object{
    return YES;
}

@end
