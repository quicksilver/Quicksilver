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

static NSMutableArray *_largeTypeWindows;

#pragma mark QSLargeTypeDisplay

void QSShowLargeType(NSString *aString) {
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSColor *textColor = [defaults colorForKey:@"QSAppearance1T"];
	NSColor *backColor = [defaults colorForKey:@"QSAppearance1B"];
	if (![aString length]) {
		NSBeep();
		return;
	}
	CGFloat displayWidth = NSWidth(screenRect) *11/12-2*EDGEINSET;
    CGFloat displayHeight = NSHeight(screenRect) * 11/12 - 2*EDGEINSET;
	NSRange fullRange = NSMakeRange(0, [aString length]);
    
	NSMutableAttributedString *formattedNumber = [[NSMutableAttributedString alloc] initWithString:aString];
	NSInteger size;
	NSSize textSize;
	NSFont *textFont;
	for (size = 24; size<300; size++) {
		textFont = [NSFont boldSystemFontOfSize:size+1];
		textSize = [aString sizeWithAttributes:[NSDictionary dictionaryWithObject:textFont forKey:NSFontAttributeName]];
        if (textSize.width > displayWidth+[textFont descender] *2 || (textSize.height > displayHeight+[textFont descender] *2)) {
            break;
        }		// ***warning  * use ascenders to calculate

	}
	[formattedNumber addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:size] range:fullRange];
	[formattedNumber addAttribute:NSForegroundColorAttributeName value:textColor range:fullRange];

	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	if ([aString rangeOfString:@"\n"] .location == NSNotFound && [aString rangeOfString:@"\r"] .location == NSNotFound)
		[style setAlignment:NSCenterTextAlignment];
		[style setLineBreakMode: NSLineBreakByWordWrapping];

	[formattedNumber addAttribute:NSParagraphStyleAttributeName value:style range:fullRange];

	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowOffset:NSMakeSize(5, -5)];
	[textShadow setShadowBlurRadius:10];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:0 alpha:0.64]];
	[formattedNumber addAttribute:NSShadowAttributeName value:textShadow range:fullRange];

	QSLargeTypeView *textView = [[QSLargeTypeView alloc] initWithFrame:NSMakeRect(0, 0, displayWidth, 0)];
	[[textView textStorage] setAttributedString:formattedNumber];
	[textView sizeToFit];

	NSRect textFrame = [textView frame];

	NSLayoutManager *layoutManager = [textView layoutManager];
	NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
	NSRange lineRange;
	CGFloat height = 0;
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
    
    if (!_largeTypeWindows) {
        _largeTypeWindows = [[NSMutableArray alloc] init];
    }
    
	QSVanishingWindow *largeTypeWindow = [[QSVanishingWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:NO];
    [_largeTypeWindows addObject:largeTypeWindow];
	[largeTypeWindow setFrame:centerRectInRect(windowRect, screenRect) display:YES];

	QSBezelBackgroundView *content = [[NSClassFromString(@"QSBezelBackgroundView") alloc] initWithFrame:NSZeroRect];
	[content setRadius:32];
	[content setColor:backColor];
	[content setGlassStyle:QSGlossControl];
	[largeTypeWindow setContentView:content];
	[textView setFrame:centerRectInRect([textView frame] , [content frame])];
	[content addSubview:textView];

	[largeTypeWindow makeKeyAndOrderFront:nil];
	[largeTypeWindow setInitialFirstResponder:textView];
	[largeTypeWindow setAlphaValue:1 fadeTime:0.333];
	[[largeTypeWindow contentView] display];
    /* Released when closed */
}

#pragma mark QSVainishingWindow

@implementation QSVanishingWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
		[self setReleasedWhenClosed:YES];
        [self setBackgroundColor: [NSColor clearColor]];
        [self setOpaque:NO];
        [self setLevel:NSFloatingWindowLevel];
        [self setHidesOnDeactivate:NO];
        [self setHasShadow:YES];
        [self setAlphaValue:0];

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

- (void)dealloc {
    [_largeTypeWindows removeObject:self];
    if ([_largeTypeWindows count] == 0) {
        _largeTypeWindows = nil;
    }
}

- (void)resignKeyWindow {
	[super resignKeyWindow];
	if ([self isVisible]) {
		[self setAlphaValue:0 fadeTime:0.333];
		[self close];
	}
}

@end

#pragma mark QSLargeTypeView

@implementation QSLargeTypeView

- (instancetype)init {
    if (self = [super init]) {
        [self setEditable:NO];
        [self setSelectable:NO];
        [self setDrawsBackground:NO];
    }
    return self;
}

- (BOOL)isOpaque {
	return NO;
}

@end

#pragma mark QSLargeTypeScriptCommand

@interface QSLargeTypeScriptCommand : NSScriptCommand
@end

@implementation QSLargeTypeScriptCommand
- (id)performDefaultImplementation {
	QSShowLargeType([self directParameter]);
	return nil;
}
@end
