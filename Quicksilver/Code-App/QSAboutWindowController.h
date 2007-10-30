//
//  QSAboutWindowController.h
//  Quicksilver
//
//  Created by Alcor on 4/16/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSAboutWindowController : NSWindowController {
	IBOutlet id creditsView;
	BOOL showCredits;
	IBOutlet NSImageView *imageView;
}

- (BOOL)showCredits;
- (void)setShowCredits:(BOOL)flag;
@end

