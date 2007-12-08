//
//  NSColor+QSCGColorRef.h
//  Fester
//
//  Created by Nicholas Jitkoff on 10/20/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (createCGColorRef)
- (CGColorRef)CGColorRef;
- (CGColorRef)createCGColorRef;
@end
