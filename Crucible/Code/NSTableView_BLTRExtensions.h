//
//  NSArray_Extensions.h
//  Quicksilver
//
//  Created by Alcor on Fri Apr 04 2003.

//

#import <Foundation/Foundation.h>

@interface NSTableView (Fancification)
//-(void)set;

//- (void)centerRowInView:(int)rowIndex;
- (void)highlightSelectionInClipRect:(NSRect)rect withGradientColor:(NSColor *)color;
@end
