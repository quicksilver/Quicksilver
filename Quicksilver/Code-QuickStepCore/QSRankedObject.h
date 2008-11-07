

#import <Foundation/Foundation.h>


@interface QSRankedObject : NSObject {
	@public

	int order;
	float score;
	id object;
	NSString *rankedString;
}
//+ (NSMutableArray *)rankedArrayWithObjects:(id *)objects scores:(float *)scores count:(int)count;
//+ (id)rankedObjectWithObject:(id)newObject matchString:(NSString *)matchString order:(int)order score:(float)newScore;

- (id)initWithObject:(id)newObject matchString:(NSString *)matchString order:(int)newOrder score:(float)newScore;
- (NSComparisonResult)nameCompare:(QSRankedObject *)compareObject;

- (float)score;
- (void)setScore:(float)newScore;

- (id)object;
- (void)setObject:(id)newObject;

- (int)order;
- (void)setOrder:(int)newOrder;

- (NSString *)rankedString;
- (void)setRankedString:(NSString *)newRankedString;
@end
