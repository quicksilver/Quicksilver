//
//  QSIntValueTransformer.m
//  Quicksilver
//
//  Created by Patrick Robertson on 05/09/2013.
//
//

#import "QSIntValueTransformer.h"

@implementation QSIntValueTransformer

- (id)initWithInteger:(NSInteger)integer {
    if (self = [super init]) {
        isEqualInt = integer;
    }
    return self;
}
+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value {
    return [NSNumber numberWithBool:([value integerValue] == isEqualInt)];
}

@end
