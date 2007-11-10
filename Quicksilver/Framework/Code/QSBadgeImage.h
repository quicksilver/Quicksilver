//
//  QSBadgeImage.h
//  Quicksilver
//
//  Created by Alcor on 9/11/04.

//

#import <Cocoa/Cocoa.h>


@interface QSCountBadgeImage : NSImage {
	int count;
	//NSColor *color;
}
+ (QSCountBadgeImage *)badgeForCount:(int)count;
@end
