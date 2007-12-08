

#import "QSTableHeaderCell.h"


@implementation QSTableHeaderCell

//editWithFrame:inView:editor:delegate:event:

//highlight:withFrame:inView:
- (void)_drawRect:(NSRect)rect withGradientFrom:(NSColor*)colorStart to:(NSColor*)colorEnd start:(NSRectEdge)edge{
    NSRect remainingRect;
    int i;
    int index = (edge==NSMinXEdge||edge==NSMaxXEdge)?rect.size.width:rect.size.height;
    remainingRect = rect;
    
    NSColor *colors[index];
    NSRect rects[index];
    
    for ( i = 0; i < index; i++ ){
        NSDivideRect ( remainingRect, &rects[i], &remainingRect, 1.0, edge);
        colors[i]=[colorStart blendedColorWithFraction:(float)i/(float)index ofColor:colorEnd];
    }
    NSRectFillListWithColors(&rects[0],&colors[0],index);
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
//	QSLog(@"draw %f",[self cellSize].height);
	
	
	[self _drawRect:cellFrame withGradientFrom:[NSColor colorWithCalibratedWhite:0.98 alpha:.99]
				 to:[NSColor colorWithCalibratedWhite:0.91 alpha:0.97] start:NSMaxYEdge];
	
	[[NSColor grayColor]set];
	NSFrameRect(cellFrame);
	[self cellSize];
	[self drawInteriorWithFrame:cellFrame inView:controlView];

	}





@end
