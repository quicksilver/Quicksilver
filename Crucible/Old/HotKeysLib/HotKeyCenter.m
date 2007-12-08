//
//  HotKeyCenter.m
//
//  Created by Quentin D. Carnicelli on Thu Jun 06 2002.
//  Copyright (c) 2002 Subband inc.. All rights reserved.
//
//  Feedback welcome at qdc@subband.com
//  This code is provided AS IS, so don't hurt yourself with it...
//

#import "HotKeyCenter.h"
#import "KeyCombo.h"

#import <Carbon/Carbon.h>

#define kHotKeyCenterSignature 'HKyC'

//*** _HotKeyData
@interface _HotKeyData : NSObject
{
@public
	BOOL mRegistered;
	EventHotKeyRef	mRef;
	KeyCombo* mCombo;
	id mTarget;
	SEL mAction;
}
@end

@implementation _HotKeyData
@end

//**** HotKeyCenter
@interface HotKeyCenter (Private)
	- (OSStatus)handleHotKeyEvent: (EventRef)inEvent;

	- (BOOL)_registerHotKeyIfNeeded: (_HotKeyData*)hk;
	- (void)_unregisterHotKeyIfNeeded: (_HotKeyData*)hk;

	+ (BOOL)_systemSupportsHotKeys;
	- (void)_hotKeyUp: (_HotKeyData*)hotKey;
	- (void)_hotKeyDown: (_HotKeyData*)hotKey;
	- (void)_hotKeyDownWithRef: (EventHotKeyRef)ref;
	- (void)_hotKeyUpWithRef: (EventHotKeyRef)ref;
	- (_HotKeyData*)_findHotKeyWithRef: (EventHotKeyRef)ref;

	pascal OSErr keyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void* refCon );
@end

@implementation HotKeyCenter

static id _sharedHKCenter = nil;

+ (id)sharedCenter
{
	if( _sharedHKCenter != nil )
		return _sharedHKCenter;
	
	_sharedHKCenter = [[HotKeyCenter alloc] init];
	
	if( [self _systemSupportsHotKeys] )
	{
		EventTypeSpec eventSpec[2] = {
			{ kEventClassKeyboard, kEventHotKeyPressed },
			{ kEventClassKeyboard, kEventHotKeyReleased }
		};    

		InstallEventHandler( GetEventDispatcherTarget(),
							 NewEventHandlerUPP((EventHandlerProcPtr) keyEventHandler), 
							 2, eventSpec, nil, nil);
	}
	
	return _sharedHKCenter;
}

- (id)init
{
	self = [super init];
	
	if( self )
	{
		mEnabled = YES;
		mHotKeys = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[mHotKeys release];
	[super dealloc];
}


#pragma mark -

- (BOOL)addHotKey: (NSString*)name combo:(KeyCombo*)combo target: (id)target action:(SEL)action;
{
	_HotKeyData* oldHotKey;
	_HotKeyData* newHotKey;
	
	NSParameterAssert( name != nil );
	NSParameterAssert( combo != nil );
	NSParameterAssert( target != nil );
	NSParameterAssert( action != nil );
	
	//** Check if we have one of these yet
	oldHotKey = [mHotKeys objectForKey: name];
	
	if( oldHotKey ) //Registered already?
		[self removeHotKey: name];

	//** Save the hot key to our own list
	newHotKey = [[[_HotKeyData alloc] init] autorelease];
	newHotKey->mRegistered = NO;
	newHotKey->mRef = nil;
	newHotKey->mCombo = [combo retain];
	newHotKey->mTarget = target; //Retain this?
	newHotKey->mAction = action;
	
	[mHotKeys setObject: newHotKey forKey: name];

	return [self _registerHotKeyIfNeeded: newHotKey];
}

- (void)removeHotKey: (NSString*)name;
{
	_HotKeyData* hotKey;
	
	hotKey = [mHotKeys objectForKey: name];
	if( hotKey == nil ) //Not registered
		return;
	
	[self _unregisterHotKeyIfNeeded: hotKey];
	
	[hotKey->mCombo release];

	//Drop it from our hot key list
	[mHotKeys removeObjectForKey: name];
}

- (NSArray*)allNames
{
	return [mHotKeys allKeys];
}

- (KeyCombo*)keyComboForName: (NSString*)name
{
	_HotKeyData* hotKey;
	
	hotKey = [mHotKeys objectForKey: name];
	if( hotKey == nil ) //Not registered
		return nil;

	return hotKey->mCombo;
}

- (void)setEnabled: (BOOL)enabled
{
	NSEnumerator* enumerator;
	_HotKeyData* hotKey;
	
	enumerator = [mHotKeys objectEnumerator];

	while( (hotKey = [enumerator nextObject]) != nil )
	{
		if( enabled )
			[self _registerHotKeyIfNeeded: hotKey];
		else
			[self _unregisterHotKeyIfNeeded: hotKey];
	}
	
	mEnabled = enabled;
}

- (BOOL)enabled
{
	return mEnabled;
}

#pragma mark -

- (void)sendEvent: (NSEvent*)event;
{
	long subType;
	EventHotKeyRef hotKeyRef;
	
	//We only have to intercept sendEvent to do hot keys on old system versions
	if( [HotKeyCenter _systemSupportsHotKeys] == YES )
		return;
	
	if( [event type] == NSSystemDefined )
	{
		subType = [event subtype];
		
		if( subType == 6 ) //6 is hot key down
		{
			hotKeyRef= (EventHotKeyRef)[event data1]; //data1 is our hot key ref
			if( hotKeyRef != nil )
				[self _hotKeyDownWithRef: hotKeyRef];
		}
		else if( subType == 9 ) //9 is hot key up
		{
			hotKeyRef= (EventHotKeyRef)[event data1];
			if( hotKeyRef != nil )
				[self _hotKeyUpWithRef: hotKeyRef];
		}
	}
}

- (OSStatus)handleHotKeyEvent: (EventRef)inEvent
{
	OSStatus err;
	EventHotKeyID hotKeyID;
	_HotKeyData* hk;
	
	//Shouldnt get here on non-hotkey supporting system versions
	NSAssert( [HotKeyCenter _systemSupportsHotKeys] == YES, @"" );
	NSAssert( GetEventClass( inEvent ) == kEventClassKeyboard, @"Got unhandled event class" );

	err = GetEventParameter(	inEvent,
								kEventParamDirectObject, 
								typeEventHotKeyID,
								nil,
								sizeof(EventHotKeyID),
								nil,
								&hotKeyID );

	if( err )
		return err;
		
	NSAssert( hotKeyID.signature == kHotKeyCenterSignature, @"Got unknown hot key" );
	
	hk = (_HotKeyData*)hotKeyID.id;
	NSAssert( hk != nil, @"Got bad hot key" );
	
	switch( GetEventKind( inEvent ) )
	{
		case kEventHotKeyPressed:
			[self _hotKeyDown: hk]; break;

		case kEventHotKeyReleased:
			[self _hotKeyUp: hk]; break;

		default:break;
	}
	
	return noErr;
}

#pragma mark -

+ (BOOL)_systemSupportsHotKeys
{
	SInt32 vers; 
	Gestalt(gestaltSystemVersion,&vers); 
	
	return (vers >= 0x00001020);
}

- (BOOL)_registerHotKeyIfNeeded: (_HotKeyData*)hk
{
	KeyCombo* combo;
	
	NSParameterAssert( hk != nil );
	
	combo = hk->mCombo;

	if( mEnabled == YES && 
		hk->mRegistered == NO &&
		[combo isValid] == YES )
	{
		EventHotKeyID keyID;
		OSStatus err;

		keyID.signature = kHotKeyCenterSignature;
		keyID.id = (unsigned long)hk;
		err = RegisterEventHotKey( [combo keyCode], [combo modifiers], 
					keyID, GetEventDispatcherTarget(), 0, &hk->mRef);
		if( err )
			return NO;
			
		hk->mRegistered = YES;
	}

	return YES;
}

- (void)_unregisterHotKeyIfNeeded: (_HotKeyData*)hk
{
	NSParameterAssert( hk != nil );
	
	if( hk->mRegistered && hk->mRef != nil )
		UnregisterEventHotKey( hk->mRef );
}

- (void)_hotKeyDown: (_HotKeyData*)hotKey
{
	id target = hotKey->mTarget;
	SEL action = hotKey->mAction;

        [target performSelector: action withObject:[[mHotKeys allKeysForObject:hotKey]lastObject]];
}

- (void)_hotKeyUp: (_HotKeyData*)hotKey
{
}

- (void)_hotKeyDownWithRef: (EventHotKeyRef)ref
{
	_HotKeyData* hotKey;
	
	hotKey = [self _findHotKeyWithRef: ref];
	if( hotKey )
		[self _hotKeyDown: hotKey];
}

- (void)_hotKeyUpWithRef: (EventHotKeyRef)ref
{
}

- (_HotKeyData*)_findHotKeyWithRef: (EventHotKeyRef)ref
{
	NSEnumerator* enumerator;
	_HotKeyData* hotKey;
	
	enumerator = [mHotKeys objectEnumerator];

	while( (hotKey = [enumerator nextObject]) != nil )
	{
		if( hotKey->mRef == ref )
			return hotKey;
	}
	
	return nil;
}

pascal OSErr keyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void* refCon )
{
	return [[HotKeyCenter sharedCenter] handleHotKeyEvent: inEvent];
}

@end

