//
//  QSGlossyBarView.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/25/06.

//

#import <Cocoa/Cocoa.h>
#import "QSMenuButton.h"

@interface NSButtonCell (TakeAttributes)
- (void) takeAttributesOfCell:(NSButtonCell *)cell;
@end

@interface QSGlossyBarView : NSView {
	
}

@end



@interface QSGlossyBarButtonCell : NSButtonCell

@end



@interface QSGlossyBarButton : NSButton 

@end

@interface QSGlossyBarMenuButton : QSMenuButton 

@end
