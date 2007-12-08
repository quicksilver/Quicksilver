//
//  NSColor+QSCGColorRef
//  Fester
//
//  Created by Nicholas Jitkoff on 10/20/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import "NSColor+QSCGColorRef.h"


@implementation NSColor (createCGColorRef)
- (CGColorRef) createCGColorRef {
  NSColor *rgbColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	float components[4];
  
	[rgbColor getRed: &components[0]
             green: &components[1]
              blue: &components[2]
             alpha: &components[3]];
  
	return CGColorCreate(CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), components); // TODO: release color space
}

- (CGColorRef)CGColorRef {
  return (CGColorRef)[(id)[self createCGColorRef] autorelease];
}
@end