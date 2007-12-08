//
//  QSHandledSplitView.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/20/06.

//

#import <Cocoa/Cocoa.h>


@interface QSHandledSplitView : NSSplitView {
	//    NSImage *mHandleImage;
	//    struct _NSPoint mDividerOrigin;
	BOOL drawsDivider;
	float dividerThickness;
}

//- (id)init;
//- (id)initWithCoder:(id)fp8;
//- (id)initWithFrame:(struct _NSRect)fp8;

//- (NSPoint)dividerOrigin{
//	return NSZeroPoint;
//}
- (BOOL)drawsDivider;
- (void)setDrawsDivider:(BOOL)flag;
- (float)dividerThickness;
- (void)setDividerThickness:(float)newDividerThickness;

@end
