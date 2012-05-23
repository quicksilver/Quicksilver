//
//  NSColor_QSModifications.h
//  Quicksilver
//
//  Created by Alcor on Fri Mar 19 2004.
//  Copyright (c) 2004 Blacktree, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Contrast)
- (NSColor *)colorWithLighting:(CGFloat)light;
- (NSColor *)colorWithLighting:(CGFloat)light plasticity:(CGFloat)plastic;
- (NSColor *)readableTextColor;

//+ (NSColor *)accentColor;
//+ (void)setAccentColor:(NSColor *)color;
@end
