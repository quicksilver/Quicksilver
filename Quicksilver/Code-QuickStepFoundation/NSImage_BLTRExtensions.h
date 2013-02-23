//
//  NSImage_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Thu Apr 24 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CIImage;
@class CIFilter;

#define QSSize16 NSMakeSize(16, 16)
#define QSSize32 NSMakeSize(32, 32)
#define QSSize48 NSMakeSize(48, 48)
#define QSSize128 NSMakeSize(128, 128)
#define QSSize256 NSMakeSize(256, 256)
#define QSSizeMax NSMakeSize(1024, 1024)

@interface NSImage (Dragging)

- (NSImage *)imageWithAlphaComponent:(CGFloat)alpha;

@end

@interface NSImage (Scaling)

+ (NSImage *)imageWithCIFilter:(CIFilter *)filter;
+ (NSImage *)imageWithCIImage:(CIImage *)ciimage;
- (NSImage *)imageByAdjustingHue:(CGFloat)hue;
//- (NSImage *)imageByAdjustingHue:(float)hue saturation:(float)saturation;
- (NSImageRep *)representationOfSize:(NSSize)theSize;
- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize;
- (BOOL)createRepresentationOfSize:(NSSize)newSize;
- (BOOL)shrinkToSize:(NSSize)newSize;
- (BOOL)createIconRepresentations;
- (void)removeRepresentationsLargerThanSize:(NSSize)size;
- (BOOL)shrinkToSize:(NSSize)newSize;
- (NSImage *)duplicateOfSize:(NSSize)newSize;
@end

@interface NSImage (Trim)
- (NSRect) usedRect;
- (NSImage *)scaleImageToSize:(NSSize)newSize trim:(BOOL)trim expand:(BOOL)expand scaleUp:(BOOL)scaleUp;
@end

@interface NSImage (Average)
- (NSColor *)averageColor;
@end
