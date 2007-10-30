//
//  NSButton-NTExtensions.m
//  CocoaTechBase
//
//  Created by Steve Gehrman on Thu Mar 27 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import "NSButton-NTExtensions.h"

@interface NSObject (UndocumentedNSButtonCellStuff)
- (NSButtonType)_buttonType;
@end

@implementation NSButton (NTExtensions)

- (BOOL)isSwitchButton;  // I have no idea why this is not public already
{
    NSButtonCell* cell = [self cell];

    if ([cell respondsToSelector:@selector(_buttonType)])
        return ([cell _buttonType] == NSSwitchButton);

    return NO;
}

@end
