//
//  QSResultArray.h
//  Quicksilver
//
//  Created by Alcor on 3/19/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSResultArrayController : NSArrayController {
	NSDictionary *resultProperties;
}
//+ (QSResultArray *)resultArrayWithResults:(NSArray *)array;

- (NSDictionary *)resultProperties;
- (void)setResultProperties:(NSDictionary *)newResultProperties;

@end
