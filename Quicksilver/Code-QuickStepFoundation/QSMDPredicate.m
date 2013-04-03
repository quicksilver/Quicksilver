//
//  QSMDPredicate.m
//  QSSpotlightPlugIn
//
//  Created by Alcor on 5/6/05.
//  Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import "QSMDPredicate.h"


@implementation QSMDQueryPredicate
- (id)generateMetadataDescription{
	return query;	
}
+ (id)predicateWithString:(NSString *)aQuery{
	QSMDQueryPredicate *predicate=[[self alloc]init];
	[predicate setQuery:aQuery];
	return predicate;
}
- (NSString *)predicateFormat{
	return query;
}
- (NSString *)query { return query; }
- (void)setQuery:(NSString *)aQuery
{
    if (query != aQuery) {
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
