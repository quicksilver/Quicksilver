//
// NSImage_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Thu Apr 24 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSImage_BLTRExtensions.h"
#import "NSGeometry_BLTRExtensions.h"
#import <QuartzCore/QuartzCore.h>

#if 0
#warning 64BIT: Inspect use of unsigned long
static inline NSInteger get_bit(unsigned char *arr, unsigned long bit_num) {
	return ( arr[(bit_num/8)] & (1 << (bit_num%8)) );
}
#endif

#if 0
@implementation NSBitmapImageRep (Stego)
/*
 - (void)embedMessage:(NSString *)message inChannel:(int)channel {
	 unsigned char *pixels = [self bitmapData];

	 // In the following loop, i is the horizontal coordinate of the pixel, and
	 // j is the vertical component.
	 // i loops over columns, j loops over rows
	 int i;
	 int j;
	 for(j = 0; j < imageHeightInPixels; j++)
	 {
		 for (i = 0; i < imageWidthInPixels; i++)
		 {

			 pixels[(j*imageWidthInPixels+i) *bitsPerPixel+channel]



			 *pixels++ = fractColor.red;
			 *pixels++ = fractColor.blue;
			 *pixels++ = fractColor.green;
			 *pixels++ = fractColor.alpha;

		 }
	 }

 }
 */
@end
#endif

@implementation NSImage (Dragging)

- (NSImage *)imageWithAlphaComponent:(CGFloat)alpha {
	NSImage *fadedImage = [[NSImage alloc] initWithData:[self TIFFRepresentation]];
	[fadedImage setCacheMode:NSImageCacheNever];

	[[NSColor colorWithDeviceWhite:0.0 alpha:alpha] set];
	for(NSImageRep *rep in [fadedImage representations]) {
        [fadedImage lockFocus];
        [rep drawInRect:NSMakeRect(0,0,[fadedImage size].width, [fadedImage size].height)];
        [fadedImage unlockFocus];
		NSRectFillUsingOperation(rectFromSize([rep size]), NSCompositingOperationDestinationIn);
	}
	return fadedImage;
}

@end

@implementation NSImage (Scaling)

+ (NSImage *)imageWithCIFilter:(CIFilter *)filter { return [self imageWithCIImage:[filter valueForKey:@"outputImage"]];  }

+ (NSImage *)imageWithCIImage:(CIImage *)ciimage {
	NSImageRep *rep = [NSCIImageRep imageRepWithCIImage:ciimage];
	NSImage *image = [[NSImage alloc] initWithSize:[rep size]];
	[image addRepresentation:rep];
	return image;
}

- (NSImage *)imageByAdjustingHue:(CGFloat)hue {
	return [NSImage imageWithCIFilter:[CIFilter filterWithName:@"CIHueAdjust" keysAndValues:@"inputAngle", [NSNumber numberWithDouble:fmod(hue+1, 1.0)*2*M_PI] , @"inputImage", [CIImage imageWithData:[self TIFFRepresentation]], nil]];
}

#if 0
- (NSImage *)imageByAdjustingHue:(CGFloat)hue saturation:(CGFloat)saturation {
	hue = fmod(hue+1, 1.0);
	CIFilter *hueAdjust = [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:@"inputAngle", [NSNumber numberWithDouble:hue*2*M_PI] , @"inputImage", [CIImage imageWithData:[self TIFFRepresentation]], nil];
	CIFilter *satAdjust = [CIFilter filterWithName:@"CIColorControls" keysAndValues:@"inputSaturation", [NSNumber numberWithDouble:saturation] , @"inputBrightness", [NSNumber numberWithDouble:0.0f] , @"inputContrast", [NSNumber numberWithDouble:1.0f] , @"inputImage", [hueAdjust valueForKey:@"outputImage"] , nil];
	return [NSImage imageWithCIFilter:satAdjust];
}
#endif

- (NSSize) adjustSizeToDrawAtSize:(NSSize)theSize {
	NSSize bestSize = [[self bestRepresentationForSize:theSize] size];
	[self setSize:bestSize];
	return bestSize;
}

- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize {
    NSRect rect = NSMakeRect(0,0,theSize.width, theSize.height);
    return [self bestRepresentationForRect:rect context:nil hints:nil];
}

- (NSImageRep *)representationOfSize:(NSSize)theSize {
	NSArray *reps = [self representations];
	NSUInteger i;
	for (i = 0; i < [reps count]; i++)
		if (NSEqualSizes([[reps objectAtIndex:i] size] , theSize) )
			return [reps objectAtIndex:i];
	return nil;
}

- (BOOL)createIconRepresentations {
	[self createRepresentationOfSize:QSSize256];
	[self createRepresentationOfSize:QSSize128];
	[self createRepresentationOfSize:QSSize32];
	[self createRepresentationOfSize:QSSize16];
	return YES;
}

- (BOOL)createRepresentationOfSize:(NSSize)newSize {
	// ***warning  * !? should this be done on the main thread?
	if ([self representationOfSize:newSize])
		return NO;

	NSBitmapImageRep *bestRep = (NSBitmapImageRep *)[self bestRepresentationForSize:newSize];

	if ([bestRep respondsToSelector:@selector(CGImage)]) {
		CGImageRef imageRef = [bestRep CGImage];

		CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();    
		CGContextRef smallContext = CGBitmapContextCreate(NULL, newSize.width, newSize.height, 8, newSize.width * 4, cspace, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast);
		CFRelease(cspace);

		if (!smallContext)
			return NO;

		NSRect drawRect = fitRectInRect(rectFromSize([bestRep size]), rectFromSize(newSize), NO);

		CGContextDrawImage(smallContext, *(CGRect *)&drawRect, imageRef);

		CGImageRef smallImage = CGBitmapContextCreateImage(smallContext);
		if (smallImage) {
			NSBitmapImageRep *cgRep = [[NSBitmapImageRep alloc] initWithCGImage:smallImage];
			[self addRepresentation:cgRep];      
		}
		CGImageRelease(smallImage);
		CGContextRelease(smallContext);
		return YES;
  }

	NSImage* scaledImage = [[NSImage alloc] initWithSize:newSize];
	[scaledImage lockFocus];
	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext setImageInterpolation:NSImageInterpolationHigh];
	[graphicsContext setShouldAntialias:YES];
	NSRect drawRect = fitRectInRect(rectFromSize([bestRep size]), rectFromSize(newSize), NO);
	[bestRep drawInRect:drawRect];
	NSBitmapImageRep* iconRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, newSize.width, newSize.height)];
	[scaledImage unlockFocus];
	[self addRepresentation:iconRep];
	return YES;
}

- (void)removeRepresentationsLargerThanSize:(NSSize)size {
	for(NSImageRep *thisRep in [[self representations] reverseObjectEnumerator]) {
		if ([thisRep size] .width > size.width && [thisRep size] .height > size.height)
			[self removeRepresentation:thisRep];
	}
}

- (NSImage *)duplicateOfSize:(NSSize)newSize {
	NSImage *dup = [self copy];
	[dup shrinkToSize:newSize];
	return dup;
}

- (BOOL)shrinkToSize:(NSSize)newSize {
	[self setSize:newSize];
	return YES;
}

@end

@implementation NSImage (Trim)

- (NSRect) usedRect {
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
    NSRect rect;
	if (![bitmap hasAlpha]) {
        rect = NSMakeRect(0, 0, [bitmap size] .height, [bitmap size] .width);
        return rect;
    }

	NSInteger minX = [bitmap pixelsWide];
	NSInteger minY = [bitmap pixelsHigh];
	NSInteger maxX = 0;
	NSInteger maxY = 0;

	NSInteger i, j;
	unsigned char* pixels = [bitmap bitmapData];

	for(i = 0; i<[bitmap pixelsWide]; i++) {
		for (j = 0; j<[bitmap pixelsHigh]; j++) {
			if (*(pixels + j*[bitmap pixelsWide] *[bitmap samplesPerPixel] + i*[bitmap samplesPerPixel] + 3) ) {
				//This pixel is not transparent! Readjust bounds.
				//NSLog(@"Pixel Occupied: (%d, %d) ", i, j);
				minX = MIN(minX, i);
				maxX = MAX(maxX, i);
				minY = MIN(minY, j);
				maxY = MAX(maxY, j);
			}

		}
	}
    rect = NSMakeRect(minX, [bitmap pixelsHigh] -maxY-1, maxX-minX+1, maxY-minY+1);
    return  rect;
}

- (NSImage *)scaleImageToSize:(NSSize)newSize trim:(BOOL)trim expand:(BOOL)expand scaleUp:(BOOL)scaleUp {
	NSRect sourceRect = (trim ? [self usedRect] : rectFromSize([self size]) );
	NSRect drawRect = (scaleUp || NSHeight(sourceRect) > newSize.height || NSWidth(sourceRect) > newSize.width ? sizeRectInRect(sourceRect, rectFromSize(newSize), expand) : NSMakeRect(0, 0, NSWidth(sourceRect), NSHeight(sourceRect) ));
	NSImage *tempImage = [[NSImage alloc] initWithSize:NSMakeSize(NSWidth(drawRect), NSHeight(drawRect) )];
	[tempImage lockFocus]; {
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[self drawInRect:drawRect fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
	}
	[tempImage unlockFocus];
	NSImage *newImage = [[NSImage alloc] initWithData:[tempImage TIFFRepresentation]]; //*** UGH! why do I have to do this to commit the changes?;
	return newImage;
}
@end

@implementation NSImage (Average)
- (NSColor *)averageColor {
	NSBitmapImageRep *rep = (NSBitmapImageRep *)[self bestRepresentationForRect:NSMakeRect(0,0,self.size.width, self.size.height) context:nil hints:nil];
	if (![rep isKindOfClass:[NSBitmapImageRep class]]) return nil;
	unsigned char *pixels = [rep bitmapData];

	NSInteger red = 0, blue = 0, green = 0; //, alpha = 0;
	NSInteger n = [rep size] .width * [rep size] .height;
	NSInteger i = 0;
	for (i = 0; i < n; i++) {
		//	pixels[(j*imageWidthInPixels+i) *bitsPerPixel+channel]
		//NSLog(@"%d %d %d %d", pixels[0] , pixels[1] , pixels[2] , pixels[3]);
		red += *pixels++;
		green += *pixels++;
		blue += *pixels++;
		//alpha += *pixels++;
	}

	//NSLog(@"%d %f %d", blue, (float) blue/n/256, n);
	return [NSColor colorWithDeviceRed:(CGFloat) red/n/256 green:(CGFloat) green/n/256 blue:(CGFloat)blue/n/256 alpha:1.0];
}

@end
