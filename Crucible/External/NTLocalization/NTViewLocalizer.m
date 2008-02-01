//
//  NTViewLocalizer.m
//  CocoaTechBase
//
//  Created by Steve Gehrman on Sun Mar 09 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTViewLocalizer.h"

#import "NSButton-NTExtensions.h"

@interface NTViewLocalizer (Private)
- (NSString*)localizedString:(NSString*)string;
- (void)localizeWindow:(NSWindow*)window;
- (void)localizeView:(NSView*)view;
@end

@implementation NTViewLocalizer

- (id)initWithTable:(NSString*)table bundle:(NSBundle*)bundle
{
    self = [super init];

    _table = [table retain];
    _bundle = [bundle retain];
    
    return self;
}

- (void)dealloc;
{
    [_table release];
    [_bundle release];
    [super dealloc];
}

+ (void)localizeWindow:(NSWindow*)window table:(NSString*)table bundle:(NSBundle*)bundle;
{
    NTViewLocalizer* localizer = [[[NTViewLocalizer alloc] initWithTable:table bundle:bundle] autorelease];

    [localizer localizeWindow:window];
}

+ (void)localizeView:(NSView*)view table:(NSString*)table bundle:(NSBundle*)bundle;
{
    NTViewLocalizer* localizer = [[[NTViewLocalizer alloc] initWithTable:table bundle:bundle] autorelease];

    [localizer localizeView:view];    
}

@end

@implementation NTViewLocalizer (Private)

- (void)localizeWindow:(NSWindow*)window;
{
    // localize window title
    NSString *windowTitle = [self localizedString:[window title]];
    if (windowTitle)
        [window setTitle:windowTitle];

    // localize window contentView
    [self localizeView:[window contentView]];
}

- (void)localizeView:(NSView*)view;
{
	NSArray* items;
	int i, cnt;
	NSTabViewItem* tabViewItem;
	
	if ([view isKindOfClass:[NSButton class]])
	{
		if ([view isKindOfClass:[NSPopUpButton class]])
		{
			// localize the menu items
			NSMenu *menu = [view menu];
			NSEnumerator *enumerator = [[menu itemArray] objectEnumerator];
			NSMenuItem* item;
			
			while ((item = [enumerator nextObject]))
				[item setTitle:[self localizedString:[item title]]];
		}
		else
		{
			[(NSButton*)view setTitle:[self localizedString:[(NSButton*)view title]]];
			[(NSButton*)view setAlternateTitle:[self localizedString:[(NSButton*)view alternateTitle]]];
			
			// resize to fit if a checkbox
			if ([(NSButton*)view isSwitchButton])
				[(NSButton*)view sizeToFit];
		}
	}
	else if ([view isKindOfClass:[NSBox class]])
	{
		[(NSBox*)view setTitle:[self localizedString:[(NSBox*)view title]]];
	}
	else if ([view isKindOfClass:[NSMatrix class]])
	{
		NSButtonCell* cell;
		
		// localize permission matrix
		items = [(NSMatrix*)view cells];
		
		cnt = [items count];
		for( i = 0; i < cnt; i++ )
		{
			cell = [items objectAtIndex:i];
			[cell setTitle:[self localizedString:[cell title]]];
			
			if( [cell isKindOfClass:[NSButtonCell class]] )
				[cell setAlternateTitle:[self localizedString:[cell alternateTitle]]];
		}
		
		// matrix needs to be resized when the strings are changed
		[(NSMatrix*)view setValidateSize:NO];
	}
	else if ([view isKindOfClass:[NSTabView class]])
	{
		// localize the tabs
		items = [(NSTabView*)view tabViewItems];
		
		cnt = [items count];
		for( i = 0; i < cnt; i++ )
		{
			tabViewItem = [items objectAtIndex:i];
			[tabViewItem setLabel:[self localizedString:[tabViewItem label]]];
			
			[self localizeView:[tabViewItem view]];
		}
	}
	else if ([view isKindOfClass:[NSTextField class]])
	{
		// handles NSTextFields and other non button NSControls
		[(NSTextField*)view setStringValue:[self localizedString:[(NSTextField*)view stringValue]]];
		
		// localize place holder string
		[[(NSTextField*)view cell] setPlaceholderString:[self localizedString:[[(NSTextField*)view cell] placeholderString]]];
	}
	else if ([view isKindOfClass:[NSTableView class]])
	{
		NSTableColumn *column;
		items = [(NSTableView*)view tableColumns];
		
		cnt = [items count];
		for( i = 0; i < cnt; i++ )
		{
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
		
		for( x = 0; x < xcnt; x++ )
		{
			[self localizeView:[subviews objectAtIndex:x]];
		}
	}
}
 
 
- (NSString*)localizedString:(NSString*)string;
{
    if ([string length])
		return [_bundle distributedLocalizedStringForKey:string value:string table:_table];
    return string;
}

@end
