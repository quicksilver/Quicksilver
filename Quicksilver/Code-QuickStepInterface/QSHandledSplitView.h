//
//  QSHandledSplitView.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSHandledSplitView : NSSplitView {
	BOOL drawsDivider;
	CGFloat dividerThickness;
}
- (BOOL)drawsDivider;
- (void)setDrawsDivider:(BOOL)flag;
- (CGFloat)dividerThickness;
- (void)setDividerThickness:(CGFloat)newDividerThickness;
@end
