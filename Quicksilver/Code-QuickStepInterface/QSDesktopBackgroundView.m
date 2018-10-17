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
	[[NSColor darkGrayColor]set];
	NSRectFill(rect);
    NSRect dstRect;
    NSSize imgSize=[[self backgroundImage] size];
    NSRect srcRect=NSMakeRect(0,0,imgSize.width,imgSize.height);
    NSPoint centerOffset=NSMakePoint(NSMidX(rect)-NSMidX(srcRect),NSMidY(rect)-NSMidY(srcRect));
    if (backgroundType == QSDesktopBackgroundTiled) {
        [[NSColor colorWithPatternImage:[self backgroundImage]] set];
        [[NSGraphicsContext currentContext]setPatternPhase:centerOffset];
        NSRectFill(rect);
        return;
    } else if (backgroundType == QSDesktopBackgroundCentered) {
        [[self backgroundColor] set];
        NSRectFill(rect);
        dstRect=NSOffsetRect(srcRect,centerOffset.x,centerOffset.y);
    } else if (backgroundType == QSDesktopBackgroundFillScreen) {
        dstRect=rect;
    } else if (backgroundType == QSDesktopBackgroundCrop) {
        CGFloat proportion=NSWidth(srcRect)/NSHeight(srcRect);
        NSRect lrgRect = NSUnionRect(NSMakeRect(0,0,rect.size.width,rect.size.width/proportion),NSMakeRect(0,0,rect.size.height*proportion,rect.size.height));
        dstRect=NSOffsetRect(lrgRect,NSMidX(rect)-NSMidX(lrgRect),NSMidY(rect)-NSMidY(lrgRect));
    } else {
		dstRect=rect;
	}

    [[self backgroundImage] drawInRect:dstRect fromRect:srcRect operation:NSCompositingOperationCopy fraction:1];
}



- (void)updateWithDictionary:(NSDictionary *)backgroundDict{
    NSArray *colorArray = [backgroundDict objectForKey:@"BackgroundColor"];
//	[SLog(@"back %@",[backgroundDict objectForKey:@"ImageFilePath"]);
    [self setBackgroundImage:[[NSImage allocWithZone:nil] initWithContentsOfFile: [backgroundDict objectForKey:@"ImageFilePath"]]];
    [self setBackgroundColor:[NSColor colorWithCalibratedRed:[[colorArray objectAtIndex:0] doubleValue] green:[[colorArray objectAtIndex:1] doubleValue] blue:[[colorArray objectAtIndex:2] doubleValue] alpha:1]];
    [self setBackgroundType:[[backgroundDict objectForKey:@"PlacementKeyTag"] integerValue]];
    [self setNeedsDisplay:YES];
}



- (void)updateDisplay{
    NSDictionary *backgroundsDict = (NSDictionary *) CFBridgingRelease(CFPreferencesCopyValue((CFStringRef) @"Background", (CFStringRef) @"com.apple.desktop", kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
	
	
	NSString *key=@"default";
	if (screenNumber)
		key=[NSString stringWithFormat:@"%ld", (long)screenNumber];
	NSDictionary *dict=[backgroundsDict objectForKey:key];
	//	QSLog(@"Screen %d %@, %@",screenNumber,dict,[backgroundsDict description]);
	
	[self updateWithDictionary:dict];
	
}

- (NSInteger)screenNumber { return screenNumber; }
- (void)setScreenNumber:(NSInteger)newScreenNumber{
	if (screenNumber!=newScreenNumber){
		screenNumber = newScreenNumber;
		[self updateDisplay];
	}
	
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
