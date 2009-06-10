//
//  QSCollectingSearchObjectView.m
//  Quicksilver
//
//  Created by Alcor on 3/22/05.

//

#import "QSCollectingSearchObjectView.h"


@implementation QSCollectingSearchObjectView

- (void)awakeFromNib{
	[super awakeFromNib];
	collection = [[QSCollection alloc] init];
	
	collecting = NO;
	collectionEdge = NSMinYEdge;
	collectionSpace = 16.0;
}

- (NSSize)cellSize {
	int count = [collection count];
	NSSize size = [super cellSize];
	
	if (collectionSpace == 0.0)
		size.width += count * 16;
	
	return size;
}

- (void)drawRect:(NSRect)rect {
	NSRect frame=[self frame];
	int count = [collection count];
	if (![self currentEditor] && count) {
		float totalSpace = collectionSpace + 4;
		if (collectionSpace == 0.0) {
			totalSpace = count * 16 + 8;
		}
		frame.origin = NSZeroPoint;
		NSRect mainRect, collectRect;
		//	collectionSpace=16;
		NSDivideRect(frame,&collectRect,&mainRect,totalSpace,collectionEdge);
		//NSRect main=NSMakeRect(0,20,NSWidth([self frame]),NSHeight([self frame])-20);
		//NSRect bottom=NSMakeRect(0,0,NSWidth([self frame]),20);
		[[self cell]drawWithFrame:mainRect inView:self];
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.92]set];
		//		NSBezierPath *roundRect=[NSBezierPath bezierPath];
		
		//		[roundRect appendBezierPathWithRoundedRectangle:mainRect withRadius:NSHeight(rect)/16];
		//[roundRect fill];  
		if (collectionSpace==0.0)
			collectRect.origin.x+=8;
		
		int i;
		float iconSize=collectionSpace?collectionSpace:16;
		float opacity=collecting?1.0:0.5;
		id <QSObject> object;
		for (i=0;i<count;i++){
			object = [collection objectAtIndex:i];
			NSImage *icon=[object icon];
			[icon setSize:NSMakeSize(16,16)];
			[icon setFlipped:NO];
			NSRect drawRect=NSMakeRect(collectRect.origin.x+iconSize*i,collectRect.origin.y+2,iconSize,iconSize);
			
			[icon drawInRect:drawRect fromRect:rectFromSize([icon size]) operation:NSCompositeSourceOver fraction:opacity];
		}	
	}else{
		[super drawRect:rect];	
	}
}





-(IBAction) collect:(id)sender{ //Adds additional objects to a collection

	
	if (!collecting) collecting=YES;
	if ([super objectValue]){
		
		//[collection removeObject:[super objectValue]];
		[collection addObject:[super objectValue]];
		[self setNeedsDisplay:YES];
	}
	[self setShouldResetSearchString:YES];
	return;
}
-(IBAction) uncollect:(id)sender{ //Removes an object to a collection
	if ([collection count])
		[collection removeObject:[super objectValue]];
	if (![collection count])collecting=NO;
	[self setNeedsDisplay:YES];
}
-(IBAction) uncollectLast:(id)sender{ //Removes an object to a collection
	if ([collection count])
		[collection removeLastObject];
	
	if (![collection count])collecting=NO;
	[self setNeedsDisplay:YES];
	//if ([[resultController window] isVisible])
	//	[[resultController resultTable] setNeedsDisplay:YES];}
}
- (void)clearObjectValue{
	[self emptyCollection:nil];
	[super clearObjectValue];
}
-(IBAction) emptyCollection:(id)sender{ 
	collecting=NO;
	[collection removeAllObjects];
}
-(IBAction) combine:(id)sender{ //Resolve a collection as a single object
	[self setObjectValue:[self objectValue]];
	[self emptyCollection:sender];
	
	collecting=NO;
}


- (id)objectValue {
	if ([collection count]) {
        [collection addObject:[super objectValue]];
		return collection;
	} else
		return [super objectValue];
}

- (BOOL)objectIsInCollection:(QSObject *)thisObject{
	return [collection containsObject:thisObject];	
}


- (void)deleteBackward:(id)sender{
	if ([collection count] && ![partialString length])
		[self uncollectLast:sender];
	else
		[super deleteBackward:sender];
}

- (void)reset:(id)sender{
	collecting=NO;
	[super reset:sender];
}


- (void)selectObjectValue:( QSObject *)newObject {
	if (!collecting)
		[self emptyCollection:nil];
	[super selectObjectValue:newObject];
}

- (void)setObjectValue:(QSBasicObject *)newObject {
	if (!collecting) [self emptyCollection:self];
	[super setObjectValue:newObject];
}

- (NSRectEdge)collectionEdge {
    return collectionEdge;
}

- (void)setCollectionEdge:(NSRectEdge)value {
	collectionEdge = value;
}

- (float)collectionSpace {
    return collectionSpace;
}

- (void)setCollectionSpace:(float)value {
    if (collectionSpace != value) {
        collectionSpace = value;
    }
}


@end
