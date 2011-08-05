//
//  NSStatusItem_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 12/11/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* Window ordering mode. */
enum {
	NSLeftStatusItemPriority		 = 0, 		//  Status item is to left of others
	NSNormalStatusItemPriority		 = 1000, 	//  Status item ordered normally
	NSRightStatusItemPriority		 = 8001, 	//  Status item is to right of others
	NSFarRightStatusItemPriority	 = INT_MAX 	//  Status item is to right of menu extras
};

@interface NSStatusBar (Priority)
- (id)_statusItemWithLength:(float)length withPriority:(NSInteger)priority;
@end

#if 0
@interface NSStatusItem (Priority)
- (NSInteger) priority;
@end
#endif