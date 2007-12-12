

#import <Foundation/Foundation.h>

@interface QSCatalogEntrySource : QSObjectSource {

}
- (NSArray *)objectsFromCatalogEntries:(NSArray *)catalogObjects;

- (NSArray *)childrenForObject:(QSBasicObject *)object;
@end
