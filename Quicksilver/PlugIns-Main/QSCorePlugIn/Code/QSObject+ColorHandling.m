//
// QSObject (ColorHandling) .m
// Quicksilver
//
// Created by Alcor on 8/30/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSObject+ColorHandling.h"

@implementation QSObject (ColorHandling)
- (NSColor *)colorValue {
	NSData *colorData = [self objectForType:NSColorPboardType];
	return colorData ? [NSKeyedUnarchiver unarchiveObjectWithData:colorData] : nil;
}
@end

@implementation QSColorObjectHandler : NSObject
- (BOOL)objectHasChildren:(QSObject *)object {return NO;}
- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:@"'clpt'"]];  }
- (BOOL)loadIconForObject:(QSObject *)object {

	NSImage *image = [[NSImage alloc] initWithSize:QSSize256];
	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:NSMakeRect(0, 0, 256, 256) withRadius:16];
	[image lockFocus];
	[[object colorValue] set];
	[roundRect fill];
	[image unlockFocus];
	[object setIcon:image];
	return YES;
}
- (NSString *)identifierForObject:(QSObject *)object {return nil;}
- (NSString *)detailsOfObject:(QSObject *)object {return nil;}
- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type { return [object colorValue];  }
@end
