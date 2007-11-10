//
//  NSColor_QSModifications.m
//  Quicksilver
//
//  Created by Alcor on Fri Mar 19 2004.

//

#import "NSColor_QSModifications.h"


@implementation NSDrawerFrame (QSMods)
- (id)contentFill{
    return [NSColor colorWithDeviceWhite:0.93 alpha:1.0];
}
//- (void)drawRect:(NSRect)rect{
//	[[self contentFill]set];
//	NSRectFill(rect);
//}
@end


//
//@interface NSToolbarView : NSView
//@end
//
//@implementation NSToolbarView (QSMods)
//
////- (BOOL)_inTexturedWindow{return YES;}
//
//- (struct CGSize)_toolbarPatternPhase{
//	CGSize s;
//	s.height=200;
//		s.width=10;
//		return s;
//}
//
//@end
//


@implementation NSColor (Contrast)
+ (id)toolTipColor{
	return [NSColor grayColor];	
}



-(NSColor *)colorWithLighting:(float)light{
	return [self colorWithLighting:light plasticity:0];
}
	
-(NSColor *)colorWithLighting:(float)light plasticity:(float)plastic{
	if (plastic>1)plastic=1.0;
	if (plastic<0)plastic=0.0;
	NSColor *color=[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	float h,s,b,a;
	
	[color getHue:&h
	   saturation:&s brightness:&b alpha:&a];
	
	b+=light;//*(1-plastic);
	
//	float overflow=MAX(b-1.0,0);
	
//	s=s-overflow*plastic;
	//QSLog(@"%f %f %f",brightness,saturation,overflow);
	color=[NSColor colorWithCalibratedHue:h
								saturation:s
								brightness:b
								alpha:a];	
	
	if (plastic){
		color=[color blendedColorWithFraction:plastic*light ofColor:
			[NSColor colorWithCalibratedWhite:1.0 alpha:[color alphaComponent]]];
	}
	return color;
}



-(NSColor *)readableTextColor{
	if ([[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace]brightnessComponent]>0.5)
		return [NSColor blackColor];
	else
		return [NSColor whiteColor];
}

static NSColor *accentColor=nil;
+ (NSColor *)accentColor{
	if (!accentColor){
	    	
	}
	return accentColor;
}
+ (void)setAccentColor:(NSColor *)color{
	[accentColor release];
	accentColor=[color retain];
	
}
@end