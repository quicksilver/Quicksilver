
#import <Foundation/Foundation.h>

@interface QSFilteringArrayController : NSArrayController{
	NSMutableArray *filters;
}
- (NSMutableArray *)filters;
- (void)setFilters:(NSMutableArray *)newFilters;
@end