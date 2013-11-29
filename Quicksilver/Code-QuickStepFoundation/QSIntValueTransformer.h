//
//  QSIntValueTransformer.h
//  Quicksilver
//
//  Created by Patrick Robertson on 05/09/2013.
//
//

#import <Foundation/Foundation.h>

@interface QSIntValueTransformer : NSValueTransformer {
    NSInteger isEqualInt;
}


- (id)initWithInteger:(NSInteger)integer;

@end
