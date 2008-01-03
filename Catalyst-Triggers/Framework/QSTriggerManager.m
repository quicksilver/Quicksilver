//
//  QSTriggerManager.m
//  Quicksilver
//
//  Created by Alcor on 11/9/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSTriggerManager.h"

@implementation QSTriggerManager
- (NSView *) settingsView {
    if (!settingsView){
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];		
	}
    return [[settingsView retain] autorelease];
}

- (QSTrigger *)selection {
    return [self currentTrigger];
}

- (QSTrigger *)currentTrigger {
    return [[currentTrigger retain] autorelease];
}

- (void)setCurrentTrigger:(QSTrigger *)value {
    if (currentTrigger != value) {
        [currentTrigger autorelease];
        currentTrigger = [value retain];
    }
}

- (QSTrigger *)settingsSelection {
    return currentTrigger;
}

- (void)populateInfoFields {};

- (NSWindow *)triggerDisplayWindowWithTrigger:(QSTrigger *)trigger {
	NSImage *image = [[trigger command] icon];
	
	int quadrant = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSNotifierDefaultQuadrant"];
	NSImage *splashImage = image;
	[splashImage createRepresentationOfSize:NSMakeSize(128,128)];
	[splashImage setSize:NSMakeSize(128,128)];
	[splashImage setFlipped:NO];
	NSRect screenRect = [[NSScreen mainScreen] frame];
	
	NSRect windowRect = NSMakeRect(0,0,178,188);
	QSWindow *splashWindow = [[QSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[splashWindow setIgnoresMouseEvents:YES];
	NSRect centeredRect = NSOffsetRect(windowRect, NSMidX(screenRect) - NSMidX(windowRect), NSMidY(screenRect) - NSMidY(windowRect)); //-NSHeight(screenRect)/4);
	if (quadrant)
		centeredRect = alignRectInRect(centeredRect, NSInsetRect([[NSScreen mainScreen] visibleFrame], 6, 6), oppositeQuadrant(quadrant));
	
	[splashWindow setFrame:centeredRect display:YES]; 
	[splashWindow setBackgroundColor:[NSColor clearColor]];
	[splashWindow setOpaque:NO];
	[splashWindow setLevel:NSFloatingWindowLevel];
	[splashWindow setContentView:[[[QSBezelBackgroundView alloc] init] autorelease]];
	[(QSBezelBackgroundView *)[splashWindow contentView] setRadius:16.0];	
	[(QSBezelBackgroundView *)[splashWindow contentView] setGlassStyle:QSGlossUpArc];
	[(QSBezelBackgroundView *)[splashWindow contentView] bindColors];
	[[splashWindow contentView] display];
	
	//[splashWindow setContentView:[[[QSBackgroundView alloc]init]autorelease]];
	[splashWindow setShowOffset:NSMakePoint(0, -NSHeight(screenRect) / 8)];
	[splashWindow setHidesOnDeactivate:NO];	
	[splashWindow setSticky:YES];
	[splashWindow setReleasedWhenClosed:YES];
	
	//NSBox *boxView = [[[NSBox alloc] initWithFrame:NSMakeRect(18, 36, 140, 140)] autorelease];
	//[boxView setTitlePosition:NSNoTitle];
	//[[splashWindow contentView] addSubview:boxView];
	
	NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(24,42,128,128)] autorelease];
	[imageView setImage:splashImage];
	[imageView setImageFrameStyle:NSImageFrameNone];	
	[imageView setImageScaling:NSScaleNone];	
	[[splashWindow contentView] addSubview:imageView];
	
//  NSString *titleString = [attributes objectForKey:QSNotifierTitle];
//
//	NSColor *textColor=[[[splashWindow contentView] backgroundColor] readableTextColor];
//	if (titleString){
//		NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(2,(textString ? 20 : 14), 174, 12)] autorelease];
//		[titleField setStringValue:titleString];
//		[titleField setBezeled:NO];	
//		[titleField setDrawsBackground:NO];
//		[titleField setSelectable:NO];
//		[titleField setAlignment:NSCenterTextAlignment];
//		[titleField setFont:[NSFont boldSystemFontOfSize:10]];
//		[titleField setTextColor:textColor];
//		[[splashWindow contentView] addSubview:titleField];
//	}
    
	return splashWindow;
}
@end

@implementation QSGroupTriggerManager
- (void) initializeTrigger:(NSMutableDictionary *)trigger {
	if (![trigger objectForKey:@"name"])
		[trigger setObject:@"untitled" forKey:@"name"];
}

- (NSImage *) image {
	return [[NSImage imageNamed:@"CatalogGroup"] duplicateOfSize:QSSize16];
}
- (NSString *) name {
	return @"Group";
}
- (BOOL) enableTrigger:(QSTrigger *)trigger {
    return YES;
}

- (BOOL) disableTrigger:(QSTrigger *)trigger {
    return YES;
}

- (NSString *) descriptionForTrigger:(QSTrigger *)trigger {
    return @"";
}

@end
