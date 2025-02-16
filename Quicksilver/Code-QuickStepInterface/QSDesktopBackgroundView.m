//
//  QSDesktopBackgroundView.m
//  Doomsday
//
//  Created by Alcor on Fri Nov 22 2002.

//

#import "QSDesktopBackgroundView.h"


@implementation QSDesktopBackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        backgroundColor=nil;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
   // QSLog(@"drawingBackground:%d %@",backgroundType,[self backgroundImage]);
    //if (![self needsDisplay]) return;
	[[NSColor darkGrayColor] set];
	NSRectFill(rect);
    NSRect dstRect;
    NSSize imgSize=[[self backgroundImage] size];
    NSRect srcRect=NSMakeRect(0,0,imgSize.width,imgSize.height);
    NSPoint centerOffset=NSMakePoint(NSMidX(rect)-NSMidX(srcRect),NSMidY(rect)-NSMidY(srcRect));

        CGFloat proportion=NSWidth(srcRect)/NSHeight(srcRect);
        NSRect lrgRect = NSUnionRect(NSMakeRect(0,0,rect.size.width,rect.size.width/proportion),NSMakeRect(0,0,rect.size.height*proportion,rect.size.height));
        dstRect=NSOffsetRect(lrgRect,NSMidX(rect)-NSMidX(lrgRect),NSMidY(rect)-NSMidY(lrgRect));
    
    [[self backgroundImage] drawInRect:dstRect fromRect:srcRect operation:NSCompositingOperationCopy fraction:1];
}



- (void)updateWithDictionary:(NSDictionary *)backgroundDict{
    NSArray *colorArray = [backgroundDict objectForKey:@"BackgroundColor"];
//	[SLog(@"back %@",[backgroundDict objectForKey:@"ImageFilePath"]);
	[self setBackgroundImage:[[NSImage allocWithZone:nil] initWithContentsOfURL: [backgroundDict objectForKey:@"ImageFilePath"]]];
    [self setBackgroundColor:[NSColor colorWithCalibratedRed:[[colorArray objectAtIndex:0] doubleValue] green:[[colorArray objectAtIndex:1] doubleValue] blue:[[colorArray objectAtIndex:2] doubleValue] alpha:1]];
    [self setBackgroundType:[[backgroundDict objectForKey:@"PlacementKeyTag"] integerValue]];
    [self setNeedsDisplay:YES];
}

- (void)updateDisplay{
	
	
	NSString *key= screenNumber ? [NSString stringWithFormat:@"%ld", (long)screenNumber] : @"default";
	
	NSScreen *screen = nil;
	if (screenNumber) {
		screen = [NSScreen screenWithNumber:screenNumber];
	}
	
	// get the default screen
	if (!screen) {
		screen = [NSScreen mainScreen];
	}
	
	
	NSURL *backgroundURL = [screen wallpaperURL];
	
    // create a dict of id: key, background: backgroundURL
	// BACKWARDS COMPATIBILITY - TO KEEP THIS
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
									 backgroundURL, @"ImageFilePath",
                                            key, @"screenID", nil];
	
	[self updateWithDictionary:dict];
	
}

- (NSInteger)screenNumber { return screenNumber; }

- (void)setScreenNumber:(NSInteger)newScreenNumber{
	screenNumber = newScreenNumber;
	[self updateDisplay];
}


//



- (NSImage *)backgroundImage { return backgroundImage; }

- (void)setBackgroundImage:(NSImage *)newBackgroundImage {
    backgroundImage = newBackgroundImage;
}


- (NSColor *)backgroundColor { return backgroundColor; }

- (void)setBackgroundColor:(NSColor *)newBackgroundColor {
    backgroundColor = newBackgroundColor;
}


- (QSBackgroundType)backgroundType { return backgroundType; }
- (void)setBackgroundType:(QSBackgroundType)newBackgroundType {
    backgroundType = newBackgroundType;
}

@end
