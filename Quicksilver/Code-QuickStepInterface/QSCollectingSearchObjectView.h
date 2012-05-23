//
//  QSCollectingSearchObjectView.h
//  Quicksilver
//
//  Created by Alcor on 3/22/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSSearchObjectView.h"

@class QSCollection;

@interface QSCollectingSearchObjectView : QSSearchObjectView {
	NSMutableArray *collection;
	BOOL 			collecting;
	NSRectEdge		collectionEdge;
	CGFloat			collectionSpace;
}

- (IBAction)emptyCollection:(id)sender;
- (BOOL)objectIsInCollection:(QSObject *)thisObject;

- (NSRectEdge) collectionEdge;
- (void)setCollectionEdge:(NSRectEdge)value;

- (CGFloat) collectionSpace;
- (void)setCollectionSpace:(CGFloat)value;


@end
