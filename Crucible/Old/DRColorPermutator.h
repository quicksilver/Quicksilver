//
//  DRColorPermutator.h
//  iConMerge
//
//  Created by chmod007 on Sat Nov 10 2001.
//  Copyright (c) 2002 Infinity-to-the-Power-of-Infinity. All rights reserved.
//
//  Changed by Travis Mcleskey Sun Jan 13 2002.

//#import "Constants.h"

@interface DRColorPermutator : NSObject {

float	matrix[4][4]; //permutation matrix

}

- (id) init;

// setting the "fromScratch" parameter sets the matrix to identity before applying transformation
- (void) rotateHueByDegrees:(float)degrees preservingLuminance:(BOOL)preserve fromScratch:(BOOL)scratch;
- (void) changeSaturationBy:(float)amount fromScratch:(BOOL)scratch; // 0.0 desaturates, 1.0 leaves unchanged
- (void) changeBrightnessBy:(float)amount fromScratch:(BOOL)scratch;
- (void) offsetColorsRed:(float)ramount green:(float)gamount blue:(float)bamount fromScratch:(BOOL)scratch;

- (void) applyToBitmapImageRep:(NSBitmapImageRep*)rep;

- (void) applyToRepsOfImage:(NSImage*)image;
// src and dest attributes should be the same
- (void) applyToBitmapImageRep:(NSBitmapImageRep*)src andPutResultIn:(NSBitmapImageRep*)dest;

@end
