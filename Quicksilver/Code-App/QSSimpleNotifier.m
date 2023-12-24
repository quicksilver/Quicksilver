//
// QSGrowlNotifier.m
// QSGrowlNotifier
//
// Created by Alcor on 7/12/04.
// Copyright Blacktree 2004. All rights reserved.
//

#import <QSCore/QSNotifyMediator.h>
#import "QSSimpleNotifier.h"
#import "QSBackgroundView.h"
#import "QSWindow.h"
#import "NSColor_QSModifications.h"
#import "QSWindowAnimation.h"

#import <QSFoundation/QSFoundation.h>
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
		[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25", @"duration", @"QSPurgeEffect", @"transformFn", @"visible", @"type", nil]];
		[(QSWindow *)window reallyOrderOut:self];
	} else {
		[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25", @"duration", @"QSShrinkEffect", @"transformFn", @"hide", @"type", nil]];
		[(QSWindow *)window reallyOrderOut:self];
	}
	[window close];
}

- (void)loadWindow {
	[super loadWindow];
	NSWindow *window = [self window];
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect windowRect = [[super window] frame];
	[window setIgnoresMouseEvents:YES];
	NSInteger quadrant = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSNotifierDefaultQuadrant"];

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

	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSCenterTextAlignment];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];

	[textView setDefaultParagraphStyle:style];
}

- (void)mainThreadDisplayNotificationWithAttributes:(NSDictionary *)attributes {
	QSWindow *window = (QSWindow *)[self window];

	NSImage *splashImage = [attributes objectForKey:QSNotifierIcon];
	[splashImage setSize:QSSizeMax];

	NSString *titleString = [attributes objectForKey:QSNotifierTitle];
	NSString *textString = [attributes objectForKey:QSNotifierText];
	NSAttributedString *detailsString = [attributes objectForKey:QSNotifierDetails];
	if (textString)
		titleString = [titleString stringByAppendingFormat:@"\r%@", textString];

//	NSLog(@"attr %@", attributes);
	NSMutableAttributedString *newAttributedString = [[NSMutableAttributedString alloc] initWithString:titleString
																			attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:11] , NSFontAttributeName,
			[textView defaultParagraphStyle] , NSParagraphStyleAttributeName,
			nil]];

	if (detailsString) {
		[newAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\r"]];
		[newAttributedString appendAttributedString:detailsString];
	}
//	[newAttributedString addAttribute:NSParagraphStyleAttributeName value:[textView defaultParagraphStyle] range:NSMakeRange(0, [newAttributedString length])];
	//NSLog(@"%@", newAttributedString);

	NSColor *textColor = [[[window contentView] backgroundColor] readableTextColor];
	//	[textView setFont:];

	//	[titleString attribute

	CGFloat oldHeight = [[textView enclosingScrollView] frame] .size.height;
	NSSize size = [newAttributedString size];
	//NSLog(@"size should be %f not %f", size.height, oldHeight);
	CGFloat sizeChange = size.height-oldHeight+1;
	NSRect frame = [[self window] frame];
	//NSLog(@"size %f", sizeChange);
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

	NSInteger direction = 1;

	if ([window isVisible]) {
        [[self window] display];
        
		[textView display]; // Not always showing correctly....
        
		[curTimer invalidate];
		curTimer = nil;
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

	[[NSRunLoop currentRunLoop] addTimer:curTimer forMode:NSModalPanelRunLoopMode];
	//		[attributes objectForKey:QSNotifierTitle] , GROWL_NOTIFICATION_TITLE,
	//		[attributes objectForKey:QSNotifierText] , GROWL_NOTIFICATION_DESCRIPTION,
	//		[[attributes objectForKey:QSNotifierIcon] TIFFRepresentation] , GROWL_NOTIFICATION_ICON,
}
- (void)hideNotification:(NSTimer *)timer {
	NSWindow *window = [timer userInfo];
	if (window) [self hideWindow:window early:NO];

	if (timer == curTimer) {
		curTimer = nil;
	}
}

- (NSString *)thisTitle {
	return thisTitle;
}

- (void)setThisTitle:(NSString *)value {
	if (thisTitle != value) {
		thisTitle = [value copy];
	}
}

- (NSString *)lastTitle {
	return lastTitle;
}

- (void)setLastTitle:(NSString *)value {
	if (lastTitle != value) {
		lastTitle = [value copy];
	}
}

@end
