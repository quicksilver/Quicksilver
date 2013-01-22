//
// QSCollectingSearchObjectView.m
// Quicksilver
//
// Created by Alcor on 3/22/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSCollection.h"
#import "QSCollectingSearchObjectView.h"

@implementation QSCollectingSearchObjectView
- (void)awakeFromNib {
	[super awakeFromNib];
	collection = (NSMutableArray *)[[QSCollection alloc] init];
	collecting = NO;
	collectionEdge = NSMinYEdge;
	collectionSpace = 16.0;
}
- (NSSize) cellSize {
	NSSize size = [super cellSize];
	if (collectionSpace < 0.0001)
		size.width += [collection count]*16;
	return size;
}
- (void)drawRect:(NSRect)rect {
	NSRect frame = [self frame];
	NSInteger count = [collection count];
	if (![self currentEditor] && count) {
		CGFloat totalSpace = collectionSpace+4;
		if (collectionSpace < 0.0001) {
			totalSpace = count*16+8;
		}
		frame.origin = NSZeroPoint;
		NSRect mainRect, collectRect;
		NSDivideRect(frame, &collectRect, &mainRect, totalSpace, collectionEdge);
		[[self cell] drawWithFrame:mainRect inView:self];
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.92] set];
		if (collectionSpace < 0.0001)
			collectRect.origin.x += 8;
		NSInteger i;
		CGFloat iconSize = collectionSpace?collectionSpace:16;
		CGFloat opacity = collecting?1.0:0.5;
		QSObject *object;
		for (i = 0; i<count; i++) {
			object = [collection objectAtIndex:i];
			NSImage *icon = [object icon];
			[icon setSize:NSMakeSize(16, 16)];
			[icon drawInRect:NSMakeRect(collectRect.origin.x+iconSize*i, collectRect.origin.y+2, iconSize, iconSize) fromRect:rectFromSize([icon size]) operation:NSCompositeSourceOver fraction:opacity];
		}
	} else {
		[super drawRect:rect];
	}
}
- (IBAction)collect:(id)sender { //Adds additional objects to a collection
	if (!collecting) collecting = YES;
	if ([super objectValue] && ![collection containsObject:[super objectValue]]) {
		[collection addObject:[super objectValue]];
        [[[super controller] dSelector] saveMnemonic];
		[self setNeedsDisplay:YES];
	}
	[self setShouldResetSearchString:YES];
}
- (IBAction)uncollect:(id)sender { //Removes an object to a collection
	if ([collection count])
		[collection removeObject:[super objectValue]];
	if (![collection count]) collecting = NO;
	[self setNeedsDisplay:YES];
}
- (IBAction)uncollectLast:(id)sender { //Removes an object to a collection
	if ([collection count])
		[collection removeLastObject];
	if (![collection count])
		collecting = NO;
	[self setNeedsDisplay:YES];
	//if ([[resultController window] isVisible])
	//	[resultController->resultTable setNeedsDisplay:YES];}
}
- (void)clearObjectValue {
	[self emptyCollection:nil];
	[super clearObjectValue];
}
- (IBAction)emptyCollection:(id)sender {
	collecting = NO;
	[collection removeAllObjects];
}
- (IBAction)combine:(id)sender { //Resolve a collection as a single object
	[self setObjectValue:[self objectValue]];
	[self emptyCollection:sender];
	collecting = NO;
}
- (id)objectValue {
	if ([collection count])
		return [QSObject objectByMergingObjects:(NSArray *)collection withObject:[super objectValue]];
	else
		return [super objectValue];
}
- (BOOL)objectIsInCollection:(QSObject *)thisObject {
	return [collection containsObject:thisObject];
}
- (void)deleteBackward:(id)sender {
	if ([collection count] && ![partialString length]) {
		[self uncollectLast:sender];
	} else {
		[super deleteBackward:sender];
    }
}
- (void)reset:(id)sender {
	collecting = NO;
	[super reset:sender];
}
- (void)selectObjectValue:( QSObject *)newObject {
	if (!collecting)
		[self emptyCollection:nil];
	[super selectObjectValue:newObject];
}
- (void)setObjectValue:(QSBasicObject *)newObject {
    if (newObject == [self objectValue]) {
        return;
    }
	if (!collecting) {
        [self emptyCollection:self];
    }
    // If the new object is 'nil' (i.e. the pane has been cleared) then also clear the underlying text editor (for the 1st pane only)
    if (!newObject && self == [[super controller] dSelector]) {
        NSTextView *editor = (NSTextView *)[[self window] fieldEditor:NO forObject: self];
        if (editor) {
            [editor setString:@""];
        }
    }
    
	[super setObjectValue:newObject];
}
- (NSRectEdge)collectionEdge {
	return collectionEdge;
}
- (void)setCollectionEdge:(NSRectEdge)value {
	collectionEdge = value;
}
- (CGFloat)collectionSpace {
	return collectionSpace;
}
- (void)setCollectionSpace:(CGFloat)value {
	collectionSpace = value;
}
- (void)dealloc {
	[collection release];
	[super dealloc];
}
@end
