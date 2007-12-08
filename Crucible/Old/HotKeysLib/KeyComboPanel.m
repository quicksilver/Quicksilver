//
//  KeyComboPanel.m
//
//  Created by Quentin D. Carnicelli on Thu Jun 18 2002.
//  Copyright (c) 2002 Subband inc.. All rights reserved.
//

#import "KeyComboPanel.h"
#import "KeyBroadcaster.h"
#import "KeyCombo.h"


@interface KeyComboPanel (Private)
	- (void)keyEvent: (NSNotification*)note;
	- (void)_keyComboChanged;
@end

@implementation KeyComboPanel

static id _sharedKeyComboPanel = nil;

+ (id)sharedPanel
{
	if( _sharedKeyComboPanel == nil )
		_sharedKeyComboPanel = [[self alloc] init];
	
	return _sharedKeyComboPanel;
}

- (id)init
{
	self = [super init];
	
	if( self )
	{
		if( ![NSBundle loadNibNamed:@"KeyComboPanel" owner:self] )
		{
			QSLog( NSLocalizedString( @"Failed to load KeyComboPanel nib file.", @"Error Message" ) );
			[self release];
			return nil;
		}
		
		[self clear: nil];
	
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector( keyEvent: )
			name: KeyBraodcasterKeyEvent
			object: nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self setKeyCombo: nil];
	
	[super dealloc];
}

- (NSWindow*)window
{
	return [mTextField window];
}

- (int)runModal
{
	int resultCode;
		
	[[self window] center];
	[[self window] makeKeyAndOrderFront: nil];

	resultCode = [[NSApplication sharedApplication] runModalForWindow: [self window]];

	[[self window] orderOut: nil];

	return resultCode;
}

- (KeyCombo*)keyCombo
{
	return mKeyCombo;
}

- (void)setKeyCombo: (KeyCombo*)combo
{
	[combo retain];
	[mKeyCombo release];
	mKeyCombo = combo;
	
	[self _keyComboChanged];
}

- (void)setKeyName: (NSString*)name
{
	
}

#pragma mark -

- (IBAction)ok:(id)sender
{
	[[self window] orderOut: nil];
//	[[NSApplication sharedApplication] stopModalWithCode: NSOKButton];
            [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)cancel:(id)sender
{
	[[self window] orderOut: nil];
//	[[NSApplication sharedApplication] stopModalWithCode: NSCancelButton];
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)clear:(id)sender
{
	KeyCombo* combo;

	combo = [KeyCombo clearKeyCombo];
	[self setKeyCombo: combo];
}

- (void)keyEvent: (NSNotification*)note
{
	NSDictionary* info = [note userInfo];
	short keyCode;
	long modifiers;
	KeyCombo* combo;
	
	keyCode = [[info objectForKey: @"KeyCode"] shortValue];
	modifiers = [[info objectForKey: @"Modifiers"] longValue];
	
	combo = [KeyCombo keyComboWithKeyCode: keyCode andModifiers: modifiers];
	[self setKeyCombo: combo];
}

- (void)_keyComboChanged
{
	NSString* newString;
	
	newString = [[self keyCombo] userDisplayRep];
	if( newString == nil )
		newString = @"";
		
	[mTextField setStringValue: newString];
}

@end
