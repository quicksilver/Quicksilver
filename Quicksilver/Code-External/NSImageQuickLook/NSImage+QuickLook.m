//
//  NSImage+QuickLook.m
//  QuickLookTest
//
//  Created by Matt Gemmell on 29/10/2007.
//

#import "NSImage+QuickLook.h"
#import <QuickLook/QuickLook.h> // Remember to import the QuickLook framework into your project!

@implementation NSImage (QuickLook)
static CFDictionaryRef thumbnailOptions = nil;


//TODO: when 10.14 support is dropped, switch to latest method for generating previews: https://developer.apple.com/documentation/quicklookthumbnailing
+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (!path || !fileURL) {
        return nil;
    }
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		thumbnailOptions = CFRetain((CFDictionaryRef) [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:icon]
																				  forKey:(NSString *)kQLThumbnailOptionIconModeKey]);
		
	});

	CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault,
                                            (CFURLRef)fileURL, 
                                            CGSizeMake(size.width, size.height),
                                            thumbnailOptions);
    
    if (ref != NULL) {
        // Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
        // which is a lot more efficient than copying pixel data into a brand new NSImage.
        // Thanks to Troy Stephens @ Apple for pointing this new method out to me.
        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
        CFRelease(ref);
        NSImage *newImage = nil;
        if (bitmapImageRep) {
            newImage = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
            [newImage addRepresentation:bitmapImageRep];
            [bitmapImageRep release];
            
            if (newImage) {
                return [newImage autorelease];
            }
        }
    } else {
        // If we couldn't get a Quick Look preview, fall back on the file's Finder icon.
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        if (icon) {
            [icon setSize:size];
        }
        return icon;
    }
    
    return nil;
}


@end
