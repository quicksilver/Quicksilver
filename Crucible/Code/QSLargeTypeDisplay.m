//
//  QSLargeTypeDisplay.m
//  Quicksilver
//
//  Created by Alcor on 9/20/04.

//

#import "QSLargeTypeDisplay.h"

#import "NSUserDefaults_BLTRExtensions.h"
#import "QSBezelBackgroundView.h"

#define EDGEINSET 16
void QSShowLargeType( NSString *number ) {
	NSRect screenRect = [[NSScreen mainScreen] frame];
	
	NSColor *textColor = [[NSUserDefaults standardUserDefaults] colorForKey:@"QSAppearance1T"];
	NSColor *backColor = [[NSUserDefaults standardUserDefaults] colorForKey:@"QSAppearance1B"];
	
	
	if (![number length]) {
		NSBeep();
		return;
	}
    
	float displayWidth = NSWidth( screenRect ) * 11 / 12 - 2 * EDGEINSET;
	NSRange fullRange = NSMakeRange( 0, [number length] );
	NSMutableAttributedString *formattedNumber = [[[NSMutableAttributedString alloc] initWithString:number] autorelease];
	int size;
	NSSize textSize;
	NSFont *textFont;
	for(size = 24; size < 300; size++ ) {
		textFont = [NSFont boldSystemFontOfSize:size+1];
		textSize = [number sizeWithAttributes:[NSDictionary dictionaryWithObject:textFont forKey:NSFontAttributeName]];
		if (textSize.width > displayWidth + [textFont descender] * 2) break;
		// ***warning   * use ascenders to calculate
	}
    
	[formattedNumber addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:size] range:fullRange];
	[formattedNumber addAttribute:NSForegroundColorAttributeName value:textColor range:fullRange];

	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	if ([number rangeOfString:@"\n"].location == NSNotFound && [number rangeOfString:@"\r"].location == NSNotFound)
		[style setAlignment:NSCenterTextAlignment];
    [style setLineBreakMode: NSLineBreakByWordWrapping];
	
	[formattedNumber addAttribute:NSParagraphStyleAttributeName value:style range:fullRange];
	
	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
	[textShadow setShadowOffset:NSMakeSize( 5, -5 )];
	[textShadow setShadowBlurRadius:10];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:0 alpha:0.64]];
	[formattedNumber addAttribute:NSShadowAttributeName value:textShadow range:fullRange];
	
	NSTextView *textView = [[[NSTextView alloc] initWithFrame:NSMakeRect( 0, 0, displayWidth, 0 )] autorelease];
	[textView setEditable:NO];
	[textView setSelectable:NO];
//	[numberView setBezeled:NO];
//	[numberView setBordered:NO];
	[textView setDrawsBackground:NO];
    [[textView textStorage] setAttributedString:formattedNumber];
	[textView sizeToFit];
	
	NSRect textFrame = [textView frame];

	//NSRect frame=NSMakeRect(0,0,displayWidth,0);
	NSLayoutManager *layoutManager = [textView layoutManager];
	unsigned numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
	NSRange lineRange;
	float height;
	for( numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++ ) {
		NSRect rect = [layoutManager lineFragmentRectForGlyphAtIndex:index 
                                                      effectiveRange:&lineRange];
		height += NSHeight( rect );
		index = NSMaxRange( lineRange );
	}
	//QSLog(@"size %f %d %f",height,numberOfLines,numberOfLines*[layoutManager defaultLineHeightForFont:[NSFont boldSystemFontOfSize:size]]);
	
	textFrame.size.height = ( numberOfLines + 0.1 ) * [layoutManager defaultLineHeightForFont:[NSFont boldSystemFontOfSize:size]];
	
	textFrame.size.height = MIN( NSHeight( screenRect ) - 80, NSHeight( textFrame ));
	
	[textView setFrame:textFrame];

	NSRect windowRect = centerRectInRect( textFrame, screenRect );
	windowRect = NSInsetRect( windowRect, -EDGEINSET, -EDGEINSET );
	windowRect = NSIntegralRect( windowRect );
	NSWindow *largeTypeWindow = [[QSVanishingWindow alloc] initWithContentRect:windowRect
                                                                     styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
                                                                       backing:NSBackingStoreBuffered
                                                                         defer:NO];
	[largeTypeWindow setIgnoresMouseEvents:YES];
	[largeTypeWindow setFrame:centerRectInRect( windowRect, screenRect ) display:YES];
	[largeTypeWindow setBackgroundColor: [NSColor clearColor]];
	[largeTypeWindow setOpaque:NO];
	[largeTypeWindow setLevel:NSFloatingWindowLevel];
	[largeTypeWindow setHidesOnDeactivate:NO];
	//[largeTypeWindow setDelegate:self];  
	//[largeTypeWindow setNextResponder:self];
	
	QSBezelBackgroundView *content = [[[NSClassFromString(@"QSBezelBackgroundView") alloc] initWithFrame:NSZeroRect] autorelease];
	[content setRadius:32];
	[content setColor:backColor];
	[content setGlassStyle:QSGlossControl];
	[largeTypeWindow setHasShadow:YES];
	[largeTypeWindow setContentView:content];
	[textView setFrame:centerRectInRect( [textView frame], [content frame] )];
	//[textView setTag:255];
	[content addSubview:textView];
	[largeTypeWindow setAlphaValue:0];
	[largeTypeWindow makeKeyAndOrderFront:nil];
	
	[largeTypeWindow setInitialFirstResponder:textView];
	[largeTypeWindow setAlphaValue:1 fadeTime:0.333];
	[[largeTypeWindow contentView] display];
}

@implementation QSVanishingWindow
- (id) initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
	if( self ) {
		[self setReleasedWhenClosed:YES];
	}
    return self;
}

-(IBAction) copy:(id)sender {
	//if (![[self firstResponder] respondsToSelector: @selector(stringValue)]) return;
//	QSLog(@"copy,%@",[self initialFirstResponder]);
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:[(NSTextField *)[self initialFirstResponder] stringValue] forType:NSStringPboardType];
}

/*
 -(void)dealloc{
	 QSLog(@"dealloc");
	 [super dealloc];	
	 
 }
 */

- (BOOL) canBecomeKeyWindow { return YES; }

- (void) keyDown:(NSEvent *)theEvent {
	[self setAlphaValue:0 fadeTime:0.333];
	[self close];
}

- (void) resignKeyWindow {
	[super resignKeyWindow];
	
	if([self isVisible]) {
		[self setAlphaValue:0 fadeTime:0.333];
		[self close];
	}
}
@end

@implementation QSLargeTypeView
- (id) initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {        // Initialization code here.
    }
    return self;
    
}

- (BOOL) isOpaque {
    return NO;
}

- (void) drawRect:(NSRect)rect {
    NSBezierPath *roundRect = [NSBezierPath bezierPath];
    [roundRect appendBezierPathWithRoundedRectangle:rect withRadius:NSHeight( rect ) / 8];
    [[NSColor colorWithDeviceWhite:0 alpha:0.64]set];
    [roundRect fill];  
    
    [super drawRect:rect];
}
@end

@interface QSLargeTypeScriptCommand : NSScriptCommand
@end

@implementation QSLargeTypeScriptCommand
- (id) performDefaultImplementation {
	//NSDictionary *args = [self evaluatedArguments];	
	QSShowLargeType( [self directParameter] );
	return nil;
}
@end