//
//  QSFadingView.h
//  QSPrimerInterfacePlugIn
//
//  Created by Alcor on 12/25/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSFadingView : NSView {
	float opacity;
}
- (float)opacity;
- (void)setOpacity:(float)newOpacity;
@end
