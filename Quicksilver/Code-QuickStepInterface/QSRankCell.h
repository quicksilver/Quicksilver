

#import <Foundation/Foundation.h>


@interface QSRankCell : NSCell {
	float score;
	NSInteger order;
}
- (float) score;
- (void)setScore:(float)newScore;
- (NSInteger) order;
- (void)setOrder:(NSInteger)newOrder;
@end
