//
//  QSCatalogSearchProvider.h
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 6/25/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSCatalogSearchProvider : NSObject {
  NSString *searchString;
  NSString *matchedString;
  NSMutableArray *sourceArray; // The original source array for searches
  NSMutableArray *searchArray; // Interim array for searching smaller and smaller pieces
  NSMutableArray *resultArray; // Final filtered array for current search string
}

@property (retain) NSMutableArray *searchArray;
@property (retain) NSMutableArray *resultArray;
@property (retain) NSMutableArray *sourceArray;
@property (copy) NSString *matchedString;
@property (copy) NSString *searchString;

- (void)performSearchFor:(NSString *)string from:(id)sender;
@end
