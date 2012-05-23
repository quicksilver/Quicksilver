#import <Foundation/Foundation.h>


@interface QSRankCell : NSCell {
	CGFloat score;
	NSInteger order;
}
- (CGFloat) score;
- (void)setScore:(CGFloat)newScore;
- (NSInteger) order;
- (void)setOrder:(NSInteger)newOrder;
@end
