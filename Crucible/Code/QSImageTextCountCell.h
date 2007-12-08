//
//  QSImageTextCountCell.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/27/06.

//

#import <Cocoa/Cocoa.h>
#import "QSImageAndTextCell.h"


@interface QSImageTextCountCell : QSImageAndTextCell {
	NSString *count;
}
- (NSString *) count;
- (void) setCount: (NSString *) newCount;

@end
