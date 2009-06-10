//
//  QSStringRanker.h
//  Quicksilver
//
//  Created by Alcor on 1/28/05.

//

#import <Cocoa/Cocoa.h>

@protocol QSStringRanker
- (id)initWithString:(NSString *)string;
- (double)scoreForAbbreviation:(NSString*)anAbbreviation;
- (NSIndexSet*)maskForAbbreviation:(NSString*)anAbbreviation;
- (NSString*)rankedString;
- (void)setRankedString:(NSString*)aString;
@end

@interface QSDefaultStringRanker : NSObject <QSStringRanker> {
	NSString *normString;
}

@end
