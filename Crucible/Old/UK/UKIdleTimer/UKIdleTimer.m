//
//  UKIdleTimer.m
//  CocoaMoose
//
//  Created by Uli Kusterer on Tue Apr 06 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import "UKIdleTimer.h"
#include <Carbon/Carbon.h>

pascal void		UKIdleTimerProc( EventLoopTimerRef inTimer,
							EventLoopIdleTimerMessage inMessage, void *refCon );


@implementation UKIdleTimer

-(id)   initWithTimeInterval: (NSTimeInterval)interval
{
	self = [super init];
	if( !self )
		return nil;
	
	static EventLoopIdleTimerUPP eventLoopIdleTimerUPP = NULL;
	if( !eventLoopIdleTimerUPP )
		eventLoopIdleTimerUPP = NewEventLoopIdleTimerUPP(UKIdleTimerProc);

	if( InstallEventLoopIdleTimer( GetCurrentEventLoop(),
								kEventDurationSecond * interval,
								kEventDurationSecond * interval,
								eventLoopIdleTimerUPP,
								self, (EventLoopTimerRef*) &carbonTimerRef) != noErr )
	{
		[self release];
		return nil;
	}
	
	return self;
}

-(void) dealloc
{
	RemoveEventLoopTimer( (EventLoopTimerRef) carbonTimerRef );
	
	[super dealloc];
}

-(void) setFireTime: (NSTimeInterval)foo
{
	SetEventLoopTimerNextFireTime( (EventLoopTimerRef) carbonTimerRef, kEventDurationSecond * foo );
}


-(id)	delegate
{
    return delegate;
}

-(void)	setDelegate: (id)newDelegate
{
	delegate = newDelegate;
}


-(void) timerBeginsIdling: (id)sender
{
	if( [delegate respondsToSelector: @selector(timerBeginsIdling:)] )
		[delegate timerBeginsIdling: self];
}


-(void) timerContinuesIdling: (id)sender
{
	if( [delegate respondsToSelector: @selector(timerContinuesIdling:)] )
		[delegate timerContinuesIdling: self];
}


-(void) timerFinishedIdling: (id)sender
{
	if( [delegate respondsToSelector: @selector(timerFinishedIdling:)] )
		[delegate timerFinishedIdling: self];
}

@end

pascal void		UKIdleTimerProc( EventLoopTimerRef inTimer,
							EventLoopIdleTimerMessage inMessage, void *refCon )
{
	switch( inMessage )
	{
		case kEventLoopIdleTimerStarted:
			[((UKIdleTimer*)refCon) timerBeginsIdling: nil];
			break;
		
		case kEventLoopIdleTimerIdling:
			[((UKIdleTimer*)refCon) timerContinuesIdling: nil];
			break;

		case kEventLoopIdleTimerStopped:
			[((UKIdleTimer*)refCon) timerFinishedIdling: nil];
			break;
	}
}
