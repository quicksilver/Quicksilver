//
//  QSImageTextDetailCell.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/27/06.

//

#import <Cocoa/Cocoa.h>
#import "QSImageAndTextCell.h"


@interface QSImageTextDetailCell : QSImageAndTextCell {
	NSString *details;
}
@property(retain) NSString *details;
@end
