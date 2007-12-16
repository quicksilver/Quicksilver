

#import "QSRankCell.h"
#import "QSObject.h"
#import <math.h>



@implementation QSRankCell
- (id)initImageCell:(NSImage *)anImage{
    if ((self=[super initImageCell:anImage])){
        
    }
    return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	//  float score=1.0;//[[self objectValue]score]; 
	//int order=1;//[[self objectValue]order];
	//QSLog(@"score %f %d",score,order);
	
    NSBezierPath *roundRect=[NSBezierPath bezierPath];
    [roundRect appendBezierPathWithRoundedRectangle:cellFrame withRadius:NSHeight(cellFrame)/2];
    
    float size=MIN(NSHeight(cellFrame),NSWidth(cellFrame));
    NSRect drawRect= centerRectInRect(NSMakeRect(0,0,size*1/3,size*1/3),cellFrame);
	NSBezierPath *path=[NSBezierPath bezierPathWithOvalInRect:drawRect];
    [[[NSColor whiteColor]colorWithAlphaComponent:0.667]set];
    
	
    [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(drawRect,-1,-1)] fill]; 
    
    
    if (order!=NSNotFound){ // defined mnemonic
		[path setLineWidth:3];
		if (order==0){
			[[[NSColor blackColor]colorWithAlphaComponent:0.667]set];
			
			NSRect dotRect= centerRectInRect(NSMakeRect(0,0,size/6,size/6),cellFrame);
			
			[[NSBezierPath bezierPathWithOvalInRect:dotRect] fill];
		}
        [[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:pow(MIN(score/3,1)*0.75,2.0)]set];
    }else{
        [[[NSColor blackColor]colorWithAlphaComponent:pow(MIN(score/3,1),2.0)]set];
        
    }
    
    
	
    [path fill];  
	[path stroke];
	
	
	
	//   QSLog(@"val %@",[self objectValue]);
}




- (float)score { return score; }
- (void)setScore:(float)newScore
{
    score = newScore;
}


- (int)order { return order; }
- (void)setOrder:(int)newOrder
{
    order = newOrder;
}
@end
