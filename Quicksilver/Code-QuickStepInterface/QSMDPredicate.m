//
//  QSMDPredicate.m
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 5/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSMDPredicate.h"


@implementation QSMDQueryPredicate
- (id)generateMetadataDescription{
	return query;	
}
+ (id)predicateWithString:(NSString *)aQuery{
	NSPredicate *predicate=[[[self alloc]init]autorelease];
	[predicate setQuery:aQuery];
	return predicate;
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
