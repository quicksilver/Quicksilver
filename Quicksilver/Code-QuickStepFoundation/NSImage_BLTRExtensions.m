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
static inline int get_bit(unsigned char *arr, unsigned long bit_num) {
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

- (NSImage *)imageWithAlphaComponent:(float)alpha {
	NSImage *fadedImage = [[NSImage alloc] initWithData:[self TIFFRepresentation]];
	[fadedImage setCacheMode:NSImageCacheNever];

	NSEnumerator *repEnum = [[fadedImage representations] objectEnumerator];
	NSImageRep *rep;
	[[NSColor colorWithDeviceWhite:0.0 alpha:alpha] set];
	while(rep = [repEnum nextObject]) {
		[fadedImage lockFocusOnRepresentation:rep];
		NSRectFillUsingOperation(rectFromSize([rep size]), NSCompositeDestinationIn);
		[fadedImage unlockFocus];
	}
	return [fadedImage autorelease];
}

@end

@implementation NSImage (Scaling)

+ (NSImage *)imageWithCIFilter:(CIFilter *)filter { return [self imageWithCIImage:[filter valueForKey:@"outputImage"]];  }

+ (NSImage *)imageWithCIImage:(CIImage *)ciimage {
	NSImageRep *rep = [NSCIImageRep imageRepWithCIImage:ciimage];
	NSImage *image = [[NSImage alloc] initWithSize:[rep size]];
	[image addRepresentation:rep];
	return [image autorelease];
}

- (NSImage *)imageByAdjustingHue:(float)hue {
	return [NSImage imageWithCIFilter:[CIFilter filterWithName:@"CIHueAdjust" keysAndValues:@"inputAngle", [NSNumber numberWithFloat:fmod(hue+1, 1.0)*2*M_PI] , @"inputImage", [CIImage imageWithData:[self TIFFRepresentation]], nil]];
}

#if 0
- (NSImage *)imageByAdjustingHue:(float)hue saturation:(float)saturation {
	hue = fmod(hue+1, 1.0);
	CIFilter *hueAdjust = [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:@"inputAngle", [NSNumber numberWithFloat:hue*2*M_PI] , @"inputImage", [CIImage imageWithData:[self TIFFRepresentation]], nil];
	CIFilter *satAdjust = [CIFilter filterWithName:@"CIColorControls" keysAndValues:@"inputSaturation", [NSNumber numberWithFloat:saturation] , @"inputBrightness", [NSNumber numberWithFloat:0.0f] , @"inputContrast", [NSNumber numberWithFloat:1.0f] , @"inputImage", [hueAdjust valueForKey:@"outputImage"] , nil];
	return [NSImage imageWithCIFilter:satAdjust];
}
#endif

- (NSSize) adjustSizeToDrawAtSize:(NSSize)theSize {
	NSSize bestSize = [[self bestRepresentationForSize:theSize] size];
	[self setSize:bestSize];
	return bestSize;
}

- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize {
	NSImageRep *bestRep = [self representationOfSize:theSize];
	if (bestRep)
		return bestRep;
	NSArray *reps = [self representations];
	float repDistance = 65536.0;
	NSImageRep *thisRep;
	float thisDistance;
	int i;
	for (i = 0; i<(int) [reps count]; i++) {
		thisRep = [reps objectAtIndex:i];
		thisDistance = MIN(theSize.width-[thisRep size] .width, theSize.height-[thisRep size] .height);
		if (repDistance<0 && thisDistance>0) continue;
		if (ABS(thisDistance) <ABS(repDistance) || (thisDistance<0 && repDistance>0) ) {
			repDistance = thisDistance;
			bestRep = thisRep;
		}
	}
	return (bestRep) ? bestRep : [self bestRepresentationForDevice:nil];
}

- (NSImageRep *)representationOfSize:(NSSize)theSize {
	NSArray *reps = [self representations];
	int i;
	for (i = 0; i<(int) [reps count]; i++)
		if (NSEqualSizes([[reps objectAtIndex:i] size] , theSize) )
			return [reps objectAtIndex:i];
	return nil;
}

- (BOOL)createIconRepresentations {
	[self setFlipped:NO];
	//[self createRepresentationOfSize:NSMakeSize(128, 128)];
	[self createRepresentationOfSize:NSMakeSize(32, 32)];
	[self createRepresentationOfSize:NSMakeSize(16, 16)];
	[self setScalesWhenResized:NO];
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
			NSBitmapImageRep *cgRep = [[[NSBitmapImageRep alloc] initWithCGImage:smallImage] autorelease];
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
	[scaledImage release];
	[self addRepresentation:[iconRep autorelease]];
	return YES;
}

- (void)removeRepresentationsLargerThanSize:(NSSize)size {
	NSEnumerator *e = [[self representations] reverseObjectEnumerator];
	NSImageRep *thisRep;
	while(thisRep = [e nextObject]) {
		if ([thisRep size] .width > size.width && [thisRep size] .height > size.height)
			[self removeRepresentation:thisRep];
	}
}

- (NSImage *)duplicateOfSize:(NSSize)newSize {
	NSImage *dup = [self copy];
	[dup shrinkToSize:newSize];
	[dup setFlipped:NO];
	return [dup autorelease];
}

- (BOOL)shrinkToSize:(NSSize)newSize {
	[self createRepresentationOfSize:newSize];
	[self setSize:newSize];
	[self removeRepresentationsLargerThanSize:newSize];
	return YES;
}

@end

@implementation NSImage (Trim)

- (NSRect) usedRect {
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];

	if (![bitmap hasAlpha]) return NSMakeRect(0, 0, [bitmap size] .height, [bitmap size] .width);

	int minX = [bitmap pixelsWide];
	int minY = [bitmap pixelsHigh];
	int maxX = 0;
	int maxY = 0;

	int i, j;
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
	[bitmap autorelease];
	return NSMakeRect(minX, [bitmap pixelsHigh] -maxY-1, maxX-minX+1, maxY-minY+1);
}

- (NSImage *)scaleImageToSize:(NSSize)newSize trim:(BOOL)trim expand:(BOOL)expand scaleUp:(BOOL)scaleUp {
	NSRect sourceRect = (trim ? [self usedRect] : rectFromSize([self size]) );
	NSRect drawRect = (scaleUp || NSHeight(sourceRect) > newSize.height || NSWidth(sourceRect) > newSize.width ? sizeRectInRect(sourceRect, rectFromSize(newSize), expand) : NSMakeRect(0, 0, NSWidth(sourceRect), NSHeight(sourceRect) ));
	NSImage *tempImage = [[NSImage alloc] initWithSize:NSMakeSize(NSWidth(drawRect), NSHeight(drawRect) )];
	[tempImage lockFocus]; {
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[self drawInRect:drawRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1];
	}
	[tempImage unlockFocus];
	NSImage *newImage = [[NSImage alloc] initWithData:[tempImage TIFFRepresentation]]; //*** UGH! why do I have to do this to commit the changes?;
	[tempImage release];
	return [newImage autorelease];
}
@end

@implementation NSImage (Average)
- (NSColor *)averageColor {
	NSBitmapImageRep *rep = (NSBitmapImageRep *)[self bestRepresentationForDevice:nil];
	if (![rep isKindOfClass:[NSBitmapImageRep class]]) return nil;
	unsigned char *pixels = [rep bitmapData];

	int red = 0, blue = 0, green = 0; //, alpha = 0;
	int n = [rep size] .width * [rep size] .height;
	int i = 0;
	for (i = 0; i < n; i++) {
		//	pixels[(j*imageWidthInPixels+i) *bitsPerPixel+channel]
		//NSLog(@"%d %d %d %d", pixels[0] , pixels[1] , pixels[2] , pixels[3]);
		red += *pixels++;
		green += *pixels++;
		blue += *pixels++;
		//alpha += *pixels++;
	}

	//NSLog(@"%d %f %d", blue, (float) blue/n/256, n);
	return [NSColor colorWithDeviceRed:(float) red/n/256 green:(float) green/n/256 blue:(float)blue/n/256 alpha:1.0];
}

@end
