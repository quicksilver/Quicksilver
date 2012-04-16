//
//  NSMetadataQuery+Synchronous.h
//
//  Created by Rob McBroom on 2012/03/22.
//
/*
 These additional methods for NSMetadataQuery allow you to "fake" a
 synchronous search. Use this in situations where you just want to
 run the search and get the results back.
 
 In other words, act like `mdfind` instead of `mdfind -live`.
 
 These are instance methods, so you'll still need to create an
 NSMetadataQuery first. This allows you to fine tune the search with
 groupings, value lists, etc. before kicking it off.
*/

#import <Foundation/Foundation.h>

@interface NSMetadataQuery (Synchronous)

// search everywhere, returns an array of NSMetadataItem objects
- (NSArray *)resultsForSearchString:(NSString *)searchString;
// limit the search to specific folders, returns an array of NSMetadataItem objects
- (NSArray *)resultsForSearchString:(NSString *)searchString inFolders:(NSSet *)paths;

@end
