//
//  NSColor_QSModifications.h
//  Quicksilver
//
//  Created by Alcor on Fri Mar 19 2004.
//  Copyright (c) 2004 Blacktree, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDrawerFrame : NSView
@end


@interface NSColor (Contrast)
-(NSColor *)colorWithLighting:(float)light;
-(NSColor *)colorWithLighting:(float)light plasticity:(float)plastic;
	-(NSColor *)readableTextColor;	

+ (NSColor *)accentColor;
+ (void)setAccentColor:(NSColor *)color;
@end