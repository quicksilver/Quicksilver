//
//  QSFadingView.h
//  QSPrimerInterfacePlugIn
//
//  Created by Alcor on 12/25/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSFadingView : NSView {
	CGFloat opacity;
}
- (CGFloat)opacity;
- (void)setOpacity:(CGFloat)newOpacity;
@end
