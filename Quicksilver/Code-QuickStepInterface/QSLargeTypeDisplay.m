//
// QSLargeTypeDisplay.m
// Quicksilver
//
// Created by Alcor on 9/20/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSLargeTypeDisplay.h"
#import "NSUserDefaults_BLTRExtensions.h"
#import "QSBezelBackgroundView.h"
#import <QSFoundation/QSFoundation.h>

#define EDGEINSET 16

void QSShowLargeType(NSString *number) {
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSColor *textColor = [defaults colorForKey:@"QSAppearance1T"];
	NSColor *backColor = [defaults colorForKey:@"QSAppearance1B"];
	if (![number length]) {
		NSBeep();
		return;
	}
	float displayWidth = NSWidth(screenRect) *11/12-2*EDGEINSET;
	NSRange fullRange = NSMakeRange(0, [number length]);
	NSMutableAttributedString *formattedNumber = [[NSMutableAttributedString alloc] initWithString:number];
	int size;
	NSSize textSize;
	NSFont *textFont;
	for (size = 24; size<300; size++) {
		textFont = [NSFont boldSystemFontOfSize:size+1];
		textSize = [number sizeWithAttributes:[NSDictionary dictionaryWithObject:textFont forKey:NSFontAttributeName]];
		if (textSize.width> displayWidth+[textFont descender] *2) break;
		// ***warning  * use ascenders to calculate

	}
	[formattedNumber addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:size] range:fullRange];
	[formattedNumber addAttribute:NSForegroundColorAttributeName value:textColor range:fullRange];

	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	if ([number rangeOfString:@"\n"] .location == NSNotFound && [number rangeOfString:@"\r"] .location == NSNotFound)
		[style setAlignment:NSCenterTextAlignment];
		[style setLineBreakMode: NSLineBreakByWordWrapping];

	[formattedNumber addAttribute:NSParagraphStyleAttributeName value:style range:fullRange];
	[style release];

	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowOffset:NSMakeSize(5, -5)];
	[textShadow setShadowBlurRadius:10];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:0 alpha:0.64]];
	[formattedNumber addAttribute:NSShadowAttributeName value:textShadow range:fullRange];
	[textShadow release];

	NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, displayWidth, 0)];
	[textView setEditable:NO];
	[textView setSelectable:NO];
	[textView setDrawsBackground:NO];
	[[textView textStorage] setAttributedString:formattedNumber];
	[formattedNumber release];
	[textView sizeToFit];

	NSRect textFrame = [textView frame];

	NSLayoutManager *layoutManager = [textView layoutManager];
	unsigned numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
	NSRange lineRange;
	float height;
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++) {
		NSRect rect = [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		height += NSHeight(rect);
		index = NSMaxRange(lineRange);
	}
	//NSLog(@"size %f %d %f", height, numberOfLines, numberOfLines*[layoutManager defaultLineHeightForFont:[NSFont boldSystemFontOfSize:size]]);
	textFrame.size.height = (numberOfLines+0.1) *[layoutManager defaultLineHeightForFont:[NSFont boldSystemFontOfSize:size]];
	textFrame.size.height = MIN(NSHeight(screenRect) -80, NSHeight(textFrame));
	[textView setFrame:textFrame];
	//[numberView setAlignment:NSCenterTextAlignment];
	NSRect windowRect = centerRectInRect(textFrame, screenRect);
	windowRect = NSInsetRect(windowRect, -EDGEINSET, -EDGEINSET);
	windowRect = NSIntegralRect(windowRect);
	NSWindow *largeTypeWindow = [[QSVanishingWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:NO];
	[largeTypeWindow setIgnoresMouseEvents:YES];
	[largeTypeWindow setFrame:centerRectInRect(windowRect, screenRect) display:YES];
	[largeTypeWindow setBackgroundColor: [NSColor clearColor]];
	[largeTypeWindow setOpaque:NO];
	[largeTypeWindow setLevel:NSFloatingWindowLevel];
	[largeTypeWindow setHidesOnDeactivate:NO];
	//[largeTypeWindow setDelegate:self];
	//	[largeTypeWindow setNextResponder:self];

	QSBezelBackgroundView *content = [[NSClassFromString(@"QSBezelBackgroundView") alloc] initWithFrame:NSZeroRect];
	[content setRadius:32];
	[content setColor:backColor];
	[content setGlassStyle:QSGlossControl];
	[largeTypeWindow setHasShadow:YES];
	[largeTypeWindow setContentView:content];
	[textView setFrame:centerRectInRect([textView frame] , [content frame])];
	//[textView setTag:255];
	[content addSubview:textView];
	[textView release];
	[content release];

	[largeTypeWindow setAlphaValue:0];
	[largeTypeWindow makeKeyAndOrderFront:nil];
	[largeTypeWindow setInitialFirstResponder:textView];
	[largeTypeWindow setAlphaValue:1 fadeTime:0.333];
	[[largeTypeWindow contentView] display];
    /* Released when closed */
}



@implementation QSVanishingWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
		[self setReleasedWhenClosed:YES];
	}
	return self;
}

- (IBAction)copy:(id)sender {
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:[(NSTextField *)[self initialFirstResponder] stringValue] forType:NSStringPboardType];
}

- (BOOL)canBecomeKeyWindow {return YES;}

- (void)keyDown:(NSEvent *)theEvent {
	[self setAlphaValue:0 fadeTime:0.333];
	[self close];
}

- (void)resignKeyWindow {
	[super resignKeyWindow];
	if ([self isVisible]) {
		[self setAlphaValue:0 fadeTime:0.333];
		[self close];
	}
}
@end

@implementation QSLargeTypeView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
#if 0
	if (self) {		// Initialization code here.
	}
#endif
	return self;
}

- (BOOL)isOpaque {
	return NO;
}

- (void)drawRect:(NSRect)rect {
	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:rect withRadius:NSHeight(rect) /8];
	[[NSColor colorWithDeviceWhite:0 alpha:0.64] set];
	[roundRect fill];
	[super drawRect:rect];
}
@end

@interface QSLargeTypeScriptCommand : NSScriptCommand
@end

@implementation QSLargeTypeScriptCommand
- (id)performDefaultImplementation {
	QSShowLargeType([self directParameter]);
	return nil;
}
@end
