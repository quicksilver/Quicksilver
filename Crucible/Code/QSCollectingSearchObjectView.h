//
//  QSCollectingSearchObjectView.h
//  Quicksilver
//
//  Created by Alcor on 3/22/05.

//

#import <Cocoa/Cocoa.h>

#import "QSSearchObjectView.h"
#import "QSCollection.h"
@class QSCollection;

@interface QSCollectingSearchObjectView : QSSearchObjectView {
	QSCollection  * collection;
	BOOL 			collecting;
	NSRectEdge		collectionEdge;
	float			collectionSpace;
}

- (IBAction)emptyCollection:(id)sender;
- (BOOL)objectIsInCollection:(QSObject *)thisObject;

- (NSRectEdge)collectionEdge;
- (void)setCollectionEdge:(NSRectEdge)value;

- (float)collectionSpace;
- (void)setCollectionSpace:(float)value;


@end
