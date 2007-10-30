//
//  NSBezierPathCappedBoxes.h
//  Filie
//
//  Created by Uli Kusterer on Fri Dec 19 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//	CappedBoxes category on NSBezierPath:
// -----------------------------------------------------------------------------

@interface NSBezierPath (CappedBoxes)

+(NSBezierPath*)	bezierPathWithCappedBoxInRect: (NSRect)rect;

@end
