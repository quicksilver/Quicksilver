//
//  QSGrowlNotifier.m
//  QSGrowlNotifier
//
//  Created by Alcor on 7/12/04.

//

#import "QSSimpleNotifier.h"

@implementation QSSilverNotifier


- (void)displayNotificationWithAttributes:(NSDictionary *)attributes {
	[self performSelectorOnMainThread:@selector(mainThreadDisplayNotificationWithAttributes:)
						   withObject:attributes waitUntilDone:NO];
}

- (id)init {
	self = [super initWithWindowNibName:@"QSSimpleNotifier" owner:self];
	
	if (self != nil) {
		thisTitle = nil;
		lastTitle = nil;
	}
	return self;
}


- (void)hideWindow:(NSWindow *)window early:(BOOL)early {
	
	if (early) {
		//[window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExtraExtraEffect", @"transformFn", @"show", @"type", nil]];
		[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25", @"duration", @"QSPurgeEffect", @"transformFn", @"visible", @"type", nil]];
		[(QSWindow *)window reallyOrderOut:self];
		
		//[[QSWindowAnimation helper] flipHide:window]; 	
	} else {
		[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25", @"duration", @"QSShrinkEffect", @"transformFn", @"hide", @"type", nil]];
		
		[(QSWindow *)window reallyOrderOut:self];
		
	}
	[window close];
}


- (void)loadWindow {
	[super loadWindow];
	NSWindow *window = [super window];
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect windowRect = [[super window] frame];
	[window setIgnoresMouseEvents:YES];
	int quadrant = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSNotifierDefaultQuadrant"];
	
	NSRect centeredRect = NSOffsetRect(windowRect, NSMidX(screenRect) -NSMidX(windowRect), NSMidY(screenRect)-NSMidY(windowRect)); //-NSHeight(screenRect)/4);
	if (quadrant)
		centeredRect = alignRectInRect(centeredRect, NSInsetRect([[NSScreen mainScreen] visibleFrame] , 6, 6), oppositeQuadrant(quadrant) );
	
	//[window setContentView:[QSBackgroundView alloc] init] autorelease]];
	[window setFrame:centeredRect display:YES];  
	[window setLevel:NSFloatingWindowLevel];
	[(QSWindow *)window setShowOffset:NSMakePoint(0, -NSHeight(screenRect)/8)];
	[window setHidesOnDeactivate:NO]; 	
	[window setSticky:YES];
	
	
	[textView setDrawsBackground:NO];
	[[textView enclosingScrollView] setDrawsBackground:NO];
	
	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setAlignment:NSCenterTextAlignment];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
	
	[textView setDefaultParagraphStyle:style];
}


- (void)mainThreadDisplayNotificationWithAttributes:(NSDictionary *)attributes {
	QSWindow *window = (QSWindow *)[self window];
	
	NSImage *splashImage = [attributes objectForKey:QSNotifierIcon];
	//splashImage = nil;
	[splashImage createRepresentationOfSize:NSMakeSize(128, 128)];
	[splashImage setSize:NSMakeSize(128, 128)];
	[splashImage setFlipped:NO];
	
	NSString *titleString = [attributes objectForKey:QSNotifierTitle];
	NSString *textString = [attributes objectForKey:QSNotifierText];
	NSAttributedString *detailsString = [attributes objectForKey:QSNotifierDetails];
	if (textString)
		titleString = [titleString stringByAppendingFormat:@"\r%@", textString];


//	QSLog(@"attr %@", attributes);
	NSMutableAttributedString *newAttributedString = [[[NSMutableAttributedString alloc] initWithString:titleString
																			attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:11] , NSFontAttributeName,
			[textView defaultParagraphStyle] , NSParagraphStyleAttributeName,
			nil]]autorelease];
	
	if (detailsString) {
		[newAttributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\r"] autorelease]];
		[newAttributedString appendAttributedString:detailsString];
	}
//	[newAttributedString addAttribute:NSParagraphStyleAttributeName value:[textView defaultParagraphStyle] range:NSMakeRange(0, [newAttributedString length])];
	//QSLog(@"%@", newAttributedString);
	
	NSColor *textColor = [[[window contentView] backgroundColor] readableTextColor];
	//	[textView setFont:];
	
	//	[titleString attribute
	
	float oldHeight = [[textView enclosingScrollView] frame] .size.height;
	NSSize size = [newAttributedString size];
	//QSLog(@"size should be %f not %f", size.height, oldHeight);
	float sizeChange = size.height-oldHeight+1;
	NSRect frame = [[self window] frame];
	//QSLog(@"size %f", sizeChange);
	frame.size.height += sizeChange;
	frame.origin.y -= sizeChange;
	if (sizeChange) {
		[[textView textStorage] addAttribute:NSForegroundColorAttributeName
									   value:[textColor colorWithAlphaComponent:0.25]
									   range:NSMakeRange(0, [[textView textStorage] length] )];
		[window setFrame:frame display:YES animate:YES];
		//[[textView enclosingScrollView] scrollPoint:NSMakePoint(0, NSHeight([[textView enclosingScrollView] frame]) )];
	}
	
	[imageView setImage:splashImage];
	[[textView textStorage] setAttributedString:newAttributedString];

	int direction = 1;
	
	
	if ([titleString isEqualToString:lastTitle])
		direction = -1;
	if ([titleString isEqualToString:thisTitle])
		direction = 0;
	
	if ([window isVisible]) {
		[curTimer invalidate];
		[curTimer release];
		curTimer = nil;
		
		int transition = CGSLeft;
		
		if (direction == -1)
			transition = CGSRight;
		if (direction == 0)
			transition = CGSDown;
		
		//		[window displayWithTransition:CGSCube option:CGSLeft duration:0.33f];
		QSCGSTransition *t = [QSCGSTransition transitionWithWindow:window
															type:CGSCube option:transition duration:0.5f];
		
		
		[[self window] display];
		
		[textView display]; // Not always showing correctly....
		[t runTransition:0.5];
		
		//[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25", @"duration", @"QSBingeEffect", @"transformFn", @"visible", @"type", nil]];
		
		//[[QSWindowAnimation helper] flipShow:window];
	} else {
		[[window contentView] display];
		
		[window setHasShadow:YES];
		[window reallyOrderFront:self];
		[window setAlphaValue:0];
		[[window contentView] display];
		[window setAlphaValue:1 fadeTime:0.25];
	}
	
	if (direction == 1) {
	[self setLastTitle:thisTitle];
	}
	
	[self setThisTitle:titleString];
	//
	//[window pulse:self];
	
	curTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideNotification:) userInfo:window repeats:NO];
	
	[curTimer retain];
	[[NSRunLoop currentRunLoop] addTimer:curTimer forMode:NSModalPanelRunLoopMode];
	//		[attributes objectForKey:QSNotifierTitle] , GROWL_NOTIFICATION_TITLE,
	//		[attributes objectForKey:QSNotifierText] , GROWL_NOTIFICATION_DESCRIPTION,
	//		[[attributes objectForKey:QSNotifierIcon] TIFFRepresentation] , GROWL_NOTIFICATION_ICON,
}
- (void)hideNotification:(NSTimer *)timer {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSWindow *window = [timer userInfo];
	if (window) [self hideWindow:window early:NO];
	
	if (timer == curTimer) {
		[curTimer release];
		curTimer = nil;
	}
	//[pool release];
}


- (NSString *)thisTitle {
    return [[thisTitle retain] autorelease];
}

- (void)setThisTitle:(NSString *)value {
    if (thisTitle != value) {
        [thisTitle release];
        thisTitle = [value copy];
    }
}

- (NSString *)lastTitle {
    return [[lastTitle retain] autorelease];
}

- (void)setLastTitle:(NSString *)value {
    if (lastTitle != value) {
        [lastTitle release];
        lastTitle = [value copy];
    }
}



@end
