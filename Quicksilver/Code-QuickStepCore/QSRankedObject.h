#import <Foundation/Foundation.h>


@interface QSRankedObject : NSObject {
	@public

	NSInteger order;
	CGFloat score;
	id object;
	NSString *rankedString;
}
//+ (NSMutableArray *)rankedArrayWithObjects:(id *)objects scores:(float *)scores count:(int)count;
//+ (id)rankedObjectWithObject:(id)newObject matchString:(NSString *)matchString order:(int)order score:(float)newScore;

- (id)initWithObject:(id)newObject matchString:(NSString *)matchString order:(NSInteger)newOrder score:(CGFloat)newScore;
- (NSComparisonResult)nameCompare:(QSRankedObject *)compareObject;

- (CGFloat)score;
- (void)setScore:(CGFloat)newScore;

- (id)object;
- (void)setObject:(id)newObject;

- (NSInteger)order;
- (void)setOrder:(NSInteger)newOrder;

- (NSString *)rankedString;
- (void)setRankedString:(NSString *)newRankedString;
@end
