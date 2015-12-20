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

/**
 Add the current object to the collection.
 @param sender the calling object (unused)
 **/
- (IBAction)collect:(id)sender;
/**
 Remove the most recently selected object from the collection
 and select the next most recent object.
 @param sender the calling object (unused)
 **/
- (IBAction)uncollect:(id)sender;
/**
 Remove the most recently selected object from the collection,
 but leave the current selection in place.
 @param sender the calling object (unused)
 **/
- (IBAction)uncollectLast:(id)sender;

/**
 Combined objects are split and the components are added to the
 collection, then the last object is selected. This improves the
 appearance of combined objects when they're selected and allows
 users to run uncollect: and uncollectLast: on the selection.
 For a single object, acts just like selectObjectValue:
 @param newObject the object to select
 **/
- (void)redisplayObjectValue:(QSObject *)newObject;

/**
 Select the next object in a collection
 @param sender the calling object (unused)
 **/
- (IBAction)goForwardInCollection:(id)sender;

/**
 Select the previous object in a collection
 @param sender the calling object (unused)
 **/
- (IBAction)goBackwardInCollection:(id)sender;

@end
