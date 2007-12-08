//
//  QSFadingView.h
//  QSPrimerInterfacePlugIn
//
//  Created by Alcor on 12/25/04.

//

#import <Cocoa/Cocoa.h>


@interface QSFadingView : NSView {
	float opacity;
}
- (float)opacity;
- (void)setOpacity:(float)newOpacity;
@end
