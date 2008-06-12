//
//  QSSpotlightSearchProvider.m
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSSpotlightSearchProvider.h"


@implementation QSSpotlightSearchProvider
@synthesize resultArray, searchText;
- (NSString *)nameForGroupID:(int)groupID {
  switch (groupID) {
    case 1: return @"MESSAGES";
    case 2: return @"CONTACT";
    case 3: return @"SYSTEM_PREFS";
    case 5: return @"BOOKMARKS";
    case 8: return @"APPLICATIONS";
    case 9: return @"DIRECTORIES";
    case 10: return @"MUSIC";
    case 11: return @"PDF";
    case 14: return @"DOCUMENTS";
    default: return [NSString stringWithFormat:@"Unknown Type: %d", groupID];
  }
  return nil;
}


- (void) startSearch {
  unsigned options = (NSCaseInsensitivePredicateOption|NSDiacriticInsensitivePredicateOption);
  NSPredicate *predicate = [NSComparisonPredicate
                            predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"*"]
                            rightExpression:[NSExpression expressionForConstantValue:self.searchText]
                            modifier:NSDirectPredicateModifier
                            type:NSLikePredicateOperatorType
                            options:options];
  NSPredicate *predicate2 = [NSComparisonPredicate
                             predicateWithLeftExpression:[NSExpression expressionForKeyPath:(NSString*)kMDItemTextContent]
                             rightExpression:[NSExpression expressionForConstantValue:self.searchText]
                             modifier:NSDirectPredicateModifier
                             type:NSLikePredicateOperatorType
                             options:options];
  predicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, predicate2, nil]];
  //[NSPredicate predicateWithFormat:@"* like[cd] %@ || kMDItemTextContent like[cd] %@*", self.searchText, self.searchText];
  // To watch results send by the query, add an observer to the NSNotificationCenter
  
  if (!query) {
    query = [[NSMetadataQuery alloc] init];
    NSNotificationCenter *nf = [NSNotificationCenter defaultCenter];
    [nf addObserver:self selector:@selector(queryNote:) name:nil object:query];
    
    
    [query setGroupingAttributes:[NSArray arrayWithObject:@"_kMDItemGroupId"]];
    [query setSortDescriptors:[NSArray arrayWithObjects:
                               [[[NSSortDescriptor alloc] initWithKey:NSMetadataQueryResultContentRelevanceAttribute ascending:NO] autorelease],
                               [[[NSSortDescriptor alloc] initWithKey:(NSString*)kMDItemContentModificationDate ascending:NO] autorelease],
                               nil]];
    [query setDelegate:self];
  }
  [query stopQuery];
  [query setPredicate:predicate];
  [query startQuery];
  NSLog(@"query %@", query);
  self.resultArray = [NSMutableArray array];
}

- (void)queryNote:(NSNotification *)note {
  // The NSMetadataQuery will send back a note when updates are happening. By looking at the [note name], we can tell what is happening
  if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
    // The query has just started!
    NSLog(@"Started gathering");
  } else if (([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) || ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification])){
    // At this point, the query will be done. You may recieve an update later on.
		
    //    NSLog(@"Finished gathering %d items:\r%@",[query resultCount],[[[query results]valueForKey:kMDItemPath]componentsJoinedByString:@"\r"]);
    NSMutableArray *groupedResults = [NSMutableArray array];
    
    for (NSMetadataQueryResultGroup *group in [query groupedResults]) {
      
      NSString *name = [self nameForGroupID:[[group value] intValue]];
      
      name = [[NSBundle bundleWithPath:@"/System/Library/CoreServices/Spotlight.app"] localizedStringForKey:name value:name table:@"MDSimpleGrouping"];
      [groupedResults addObject:[QSSeparatorObject separatorWithName:name]];
      
      int i;
      for (i = 0; i < [group resultCount]; i++) {
        [groupedResults addObject:[group resultAtIndex:i]];
        if (i == 1) break;
      }
      //      NSLog(@"group %@ %@", [group value], [group results]);
    }
    
    
    [self setResultArray:groupedResults]; //[query results];
    NSLog(@"array %@", resultArray);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QSSourceArrayUpdated" object:resultArray];
    //    self.resultsArray = [query results];
  } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
    // The query is still gatherint results...
    NSLog(@"Progressing...");
    
  } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
    // An update will happen when Spotlight notices that a file as added, removed, or modified that affected the search results.
    NSLog(@"An update happened.");
  }
}

- (id)metadataQuery:(NSMetadataQuery *)query replacementObjectForResultObject:(NSMetadataItem *)result{
  QSObject *object = [QSObject fileObjectWithPath:[result valueForAttribute:(NSString*)kMDItemPath]];
  [object setName:[result valueForAttribute:(NSString*)kMDItemDisplayName]];
  return object;
}



@end
