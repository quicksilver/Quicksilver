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
	float dividerThickness;
}
- (BOOL)drawsDivider;
- (void)setDrawsDivider:(BOOL)flag;
- (float)dividerThickness;
- (void)setDividerThickness:(float)newDividerThickness;
@end
