//
//  NTViewLocalizer.m
//  CocoaTechBase
//
//  Created by Steve Gehrman on Sun Mar 09 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTViewLocalizer.h"

#import "QSLocalization.h"
#import "NSButton-NTExtensions.h"

@interface NTViewLocalizer (Private)
- (NSString*)localizedString:(NSString*)string;
- (void)localizeWindow:(NSWindow*)window;
- (void)localizeView:(NSView*)view;
@end

@implementation NTViewLocalizer

- (id)initWithTable:(NSString*)table bundle:(NSBundle*)bundle {
	if(self = [super init]){
		_table = [table retain];
		_bundle = [bundle retain];
	}
	return self;
}

- (void)dealloc; {
	[_table release];
	[_bundle release];
	[super dealloc];
}

+ (void)localizeWindow:(NSWindow*)window table:(NSString*)table bundle:(NSBundle*)bundle; {
	NTViewLocalizer* localizer = [[NTViewLocalizer alloc] initWithTable:table bundle:bundle];
	[localizer localizeWindow:window];
	[localizer release];
}

+ (void)localizeView:(NSView*)view table:(NSString*)table bundle:(NSBundle*)bundle; {
	NTViewLocalizer* localizer = [[NTViewLocalizer alloc] initWithTable:table bundle:bundle];
	[localizer localizeView:view];
	[localizer release];
}

@end

@implementation NTViewLocalizer (Private)

- (void)localizeWindow:(NSWindow*)window; {
	NSString *windowTitle = [self localizedString:[window title]];
	if (windowTitle)
		[window setTitle:windowTitle];
	[self localizeView:[window contentView]];
}

- (void)localizeView:(NSView*)view; {
	NSArray* items;
	int i, cnt;
	NSTabViewItem* tabViewItem;

	if ([view isKindOfClass:[NSButton class]]) {
		if ([view isKindOfClass:[NSPopUpButton class]]) {
			// localize the menu items
			NSMenu *menu = [view menu];
			NSEnumerator *enumerator = [[menu itemArray] objectEnumerator];
			NSMenuItem* item;

			while (item = [enumerator nextObject])
				[item setTitle:[self localizedString:[item title]]];
		} else {
			[view setTitle:[self localizedString:[view title]]];
			[view setAlternateTitle:[self localizedString:[view alternateTitle]]];

			// resize to fit if a checkbox
			if ([view isSwitchButton])
				[view sizeToFit];
		}
	} else if ([view isKindOfClass:[NSBox class]]) {
		[view setTitle:[self localizedString:[view title]]];
	} else if ([view isKindOfClass:[NSMatrix class]]) {
		NSButtonCell* cell;

		// localize permission matrix
		items = [view cells];

		cnt = [items count];
		for (i = 0; i<cnt; i++) {
			cell = [items objectAtIndex:i];
			[cell setTitle:[self localizedString:[cell title]]];

			if ([cell isKindOfClass:[NSButtonCell class]])
				[cell setAlternateTitle:[self localizedString:[cell alternateTitle]]];
		}

		// matrix needs to be resized when the strings are changed
		[view setValidateSize:NO];
	} else if ([view isKindOfClass:[NSTabView class]]) {
		// localize the tabs
		items = [view tabViewItems];

		cnt = [items count];
		for (i = 0; i<cnt; i++) {
			tabViewItem = [items objectAtIndex:i];
			[tabViewItem setLabel:[self localizedString:[tabViewItem label]]];

			[self localizeView:[tabViewItem view]];
		}
	} else if ([view isKindOfClass:[NSTextField class]]) {
		// handles NSTextFields and other non button NSControls
		[view setStringValue:[self localizedString:[view stringValue]]];

		// localize place holder string
		[[view cell] setPlaceholderString:[self localizedString:[[view cell] placeholderString]]];
	} else if ([view isKindOfClass:[NSTableView class]]) {
		NSTableColumn *column;
		items = [view tableColumns];

		cnt = [items count];
		for (i = 0; i<cnt; i++) {
			column = [items objectAtIndex:i];

			if (column)
				[[column headerCell] setStringValue:[self localizedString:[[column headerCell] stringValue]]];
		}
	}

	// localize any tooltip
	[view setToolTip:[self localizedString:[view toolTip]]];

	// if has subviews, localize them too
	if ([[view subviews] count]) {
		NSArray *subviews = [view subviews];
		int x, xcnt = [subviews count];

		for (x = 0; x<xcnt; x++) {
			[self localizeView:[subviews objectAtIndex:x]];
		}
	}
}

- (NSString*)localizedString:(NSString*)string; {
	if ([string length])
		return [_bundle distributedLocalizedStringForKey:string value:string table:_table];
	return string;
}

@end
