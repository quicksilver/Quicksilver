//
//  QSSpotlightSearchProvider.h
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSSpotlightSearchProvider : NSObject {
  NSString *searchText;
  NSMetadataQuery *query;
  NSArray *resultArray;
}
@property(copy) NSString *searchText;
@property(retain) NSArray *resultArray;
- (void) startSearch;
@end
