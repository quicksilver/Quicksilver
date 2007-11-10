//
//  QSMDPredicate.m
//  QSSpotlightPlugIn
//
//  Created by Alcor on 5/6/05.

//

#import "QSMDPredicate.h"


@implementation QSMDQueryPredicate
- (id)generateMetadataDescription{
	return query;	
}
+ (id)predicateWithString:(NSString *)aQuery{
	QSMDQueryPredicate *predicate=[[[self alloc]init]autorelease];
	[predicate setQuery:aQuery];
	return predicate;
}
- (NSString *)predicateFormat{
	return query;
}
- (NSString *)query { return [[query retain] autorelease]; }
- (void)setQuery:(NSString *)aQuery
{
    if (query != aQuery) {
        [query release];
        query = [aQuery copy];
    }
}
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[QSMDQueryPredicate alloc]init];
	[copy setQuery:[self query]];    
    return copy;
}
@end
