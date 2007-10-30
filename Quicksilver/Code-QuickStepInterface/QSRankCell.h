

#import <Foundation/Foundation.h>


@interface QSRankCell : NSCell {
	float score;
	int order;
}
- (float)score;
- (void)setScore:(float)newScore;
- (int)order;
- (void)setOrder:(int)newOrder;
@end
