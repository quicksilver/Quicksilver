//
//  QSMDPredicate.h
//  QSSpotlightPlugIn
//
//  Created by Alcor on 5/6/05.
//  Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSMDQueryPredicate : NSPredicate {
	NSString *query;
}
+ (id)predicateWithString:(NSString *)aQuery;
- (NSString *)query;
- (void)setQuery:(NSString *)aQuery;
@end
