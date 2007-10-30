//
//  QSSearchProvider.h
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 7/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol QSSearchProvider

- (NSArray *)quickHitsForQuery:(NSString *)query;
- (NSArray *)resultsForQuery:(NSString *)query;

@end
