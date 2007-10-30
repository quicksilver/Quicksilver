//
//  UKIdleTimer.h
//  CocoaMoose
//
//  Created by Uli Kusterer on Tue Apr 06 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UKIdleTimer : NSObject
{
	void*		carbonTimerRef;
	id			delegate;
}


-(id)   initWithTimeInterval: (NSTimeInterval)interval; // After this much inactivity, the timer will fire, then periodically again with this interval until the user does something.

-(id)	delegate;
-(void)	setDelegate: (id)newDelegate;

-(void) setFireTime: (NSTimeInterval)foo;

// The following three messages are sent to the delegate if it handles them:
-(void) timerBeginsIdling: (id)sender;
-(void) timerContinuesIdling: (id)sender;
-(void) timerFinishedIdling: (id)sender;

@end
