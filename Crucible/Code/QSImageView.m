//
//  QSImageView.m
//  Quicksilver
//
//  Created by Alcor on 2/13/05.

//

#import "QSImageView.h"
#import "NSImage_BLTRExtensions.h"



@implementation QSImageCell
- (id) initImageCell:(NSImage *)image{
	self = [super initImageCell:image];
	if (self != nil) {
		adjustResolution=YES;
	}
	return self;
}
- (void)awakeFromNib{
	adjustResolution=YES;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	NSImage *image=[self image];
	[image setFlipped:NO];
//	[image setSize:cellFrame.size];
	//[image adjustSizeToDrawAtSize:cellFrame.size];
	//QSLog(@"%f %f",cellFrame.size.width,cellFrame.size.width);
	if (adjustResolution){
		NSImageRep *bestRep=[image bestRepresentationForSize:cellFrame.size];
		[image setSize:[bestRep size]];
	}
	[super drawWithFrame:cellFrame inView:controlView];
//	QSLog(@"%f %f",NSWidth(cellFrame),NSHeight(cellFrame));
}
@end


@implementation QSImageView
//+ (Class)cellClass{
//	return [QSImageCell class];	
//}
- (void)setUpGState {
	[super setUpGState];
	
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	if (1){
		NSImageRep *bestRep=[[self image] bestRepresentationForSize:[self frame].size];
		[[self image] setSize:[bestRep size]];
	}
}
@end
