//
//  QSObjectHandler.h
//  Quicksilver
//
//  Created by Etienne on 22/07/2016.
//
//

@class QSObject, QSBasicObject;

@protocol QSObjectHandler <NSObject>
@optional
- (BOOL)objectHasChildren:(QSObject *)object;
- (BOOL)objectHasValidChildren:(QSObject *)object;

- (BOOL)loadChildrenForObject:(QSObject *)object;
- (NSArray *)childrenForObject:(QSObject *)object;
- (QSObject *)parentOfObject:(QSObject *)object;
- (NSString *)detailsOfObject:(QSObject *)object;
- (NSString *)identifierForObject:(QSObject *)object;
- (NSString *)kindOfObject:(QSObject *)object;
- (void)setQuickIconForCombinedObject:(QSObject *)combinedObject;
- (void)setQuickIconForObject:(QSObject *)object;
- (BOOL)loadIconForObject:(QSObject *)object;
- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped;

- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type;
- (NSDragOperation)operationForDrag:(id <NSDraggingInfo>)sender ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject;
- (NSString *)actionForDragMask:(NSDragOperation)operation ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject;

- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;

- (NSAppleEventDescriptor *)AEDescriptorForObject:(QSObject *)object;

- (QSObject *)initFileObject:(QSObject *)object ofType:(NSString *)type QS_DEPRECATED NS_RETURNS_NOT_RETAINED;
@end


