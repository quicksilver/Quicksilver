//
//  QSCubeInterfaceBackgroundView.h
//  QSCubeInterfacePlugIn
//
//  Created by Nicholas Jitkoff on 6/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

@interface QSCubeInterfaceBackgroundView : QSBackgroundView {
	NSColor *startColor;
	NSColor *endColor;
	NSColor *highlightColor;
	NSColor *borderColor;
	int glassType;
	float borderWidth;
}
- (NSColor *) startColor;
- (void) setStartColor: (NSColor *) newStartColor;
- (NSColor *) endColor;
- (void) setEndColor: (NSColor *) newEndColor;
- (NSColor *) highlightColor;
- (void) setHighlightColor: (NSColor *) newHighlightColor;
- (NSColor *) borderColor;
- (void) setBorderColor: (NSColor *) newBorderColor;
- (int) glassType;
- (void) setGlassType: (int) newGlassType;

@end
