//
//  QSMDPredicate.h
//  QSSpotlightPlugIn
//
//  Created by Alcor on 5/6/05.

//

#import <Cocoa/Cocoa.h>


@interface QSMDQueryPredicate : NSPredicate {
	NSString *query;
}
+ (id)predicateWithString:(NSString *)aQuery;
- (NSString *)query;
- (void)setQuery:(NSString *)aQuery;
@end
