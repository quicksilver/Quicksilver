//
//  NSArray_Extensions.h
//  Quicksilver
//
//  Created by Alcor on Fri Apr 04 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTableView (Fancification)
//-(void)set;

//- (void)centerRowInView:(int)rowIndex;
- (void)highlightSelectionInClipRect:(NSRect)rect withGradientColor:(NSColor *)color;
@end

@interface NSTableView (Separator)
- (void)drawSeparatorForRow:(int)rowIndex clipRect:(NSRect)clipRect;
@end