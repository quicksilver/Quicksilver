//
//  QSAppearanceController.h
//  Quicksilver
//
//  Created by Alcor on 3/9/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSAppearanceController : NSObject {
	NSColor *accentColor;
}
+ (id)sharedInstance;
@end
