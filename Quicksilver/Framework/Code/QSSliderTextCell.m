//
//  QSSliderTextCell.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 5/7/06.

//

#import "QSSliderTextCell.h"


@implementation QSSliderTextCell
- (NSRect)trackRect{
	NSRect trackRect,rest;
	NSDivideRect([super trackRect],&rest,&trackRect,32,NSMaxXEdge);
	//logRect(trackRect);
	//logRect(_trackRect);
	return trackRect;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp{
//	QSLog(@"edit!");	
	
	NSRect trackRect,rest;
	NSDivideRect(cellFrame,&rest,&trackRect,32,NSMaxXEdge);
//	logRect(trackRect);
	[super trackMouse:theEvent inRect:trackRect ofView:controlView untilMouseUp:untilMouseUp];
	return YES;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
//	- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView{
	NSRect textRect;
	NSDivideRect(cellFrame,&textRect,&cellFrame,32,NSMaxXEdge);
	[super drawWithFrame:cellFrame inView:(NSView *)controlView];
	logRect(cellFrame);
	logRect(_trackRect);
	//NSPoint p=NSMakePoint(NSMaxX(cellFrame),NSMaxY(cellFrame));
	NSCell *titleCell=[self titleCell];
	[titleCell setFont:[NSFont systemFontOfSize:11]];
	QSLog(@"val %f",_value);
	[titleCell setFormatter:[[[NSNumberFormatter alloc]init]autorelease]];
	[titleCell setDoubleValue:_value];
	[titleCell drawWithFrame:textRect inView:controlView];
	//	[[self stringValue]drawInRect:textRect withAttributes:nil];
}
- (id)titleCell{
	return [[[NSTextFieldCell alloc]init]autorelease];
}
@end
