

#import <Foundation/Foundation.h>


@interface QSRankedObject : NSObject {
	@public

	NSInteger order;
	float score;
	id object;
	NSString *rankedString;
}
//+ (NSMutableArray *)rankedArrayWithObjects:(id *)objects scores:(float *)scores count:(NSInteger)count;
//+ (id)rankedObjectWithObject:(id)newObject matchString:(NSString *)matchString order:(NSInteger)order score:(float)newScore;

- (id)initWithObject:(id)newObject matchString:(NSString *)matchString order:(NSInteger)newOrder score:(float)newScore;
- (NSComparisonResult)nameCompare:(QSRankedObject *)compareObject;

- (float)score;
- (void)setScore:(float)newScore;

- (id)object;
- (void)setObject:(id)newObject;

- (NSInteger)order;
- (void)setOrder:(NSInteger)newOrder;

- (NSString *)rankedString;
- (void)setRankedString:(NSString *)newRankedString;
@end
