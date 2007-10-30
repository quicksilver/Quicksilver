//
//  QSMDPredicate.h
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 5/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSMDQueryPredicate : NSPredicate {
	NSString *query;
}
- (NSString *)query;
- (void)setQuery:(NSString *)aQuery;
@end
