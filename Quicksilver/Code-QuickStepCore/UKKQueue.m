//
//  UKKQueue.m
//  Filie
//
//  Created by Uli Kusterer on Sun Dec 21 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import "UKKQueue.h"
#import <stdio.h>
#import <fcntl.h>
#import <unistd.h>


@implementation UKKQueue

// -----------------------------------------------------------------------------
//	* CONSTRUCTOR:
//		Creates a new KQueue and starts that thread we use for our
//		notifications.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(id)   init
{
	if( self = [super init] )
	{
		queueFD = kqueue();
		if( queueFD == -1 )
		{
			[self release];
			return nil;
		}
		
		watchedPaths = [[NSMutableArray alloc] init];
		watchedFDs = [[NSMutableArray alloc] init];
		
		// Start new thread that fetches and processes our events:
		[NSThread detachNewThreadSelector:@selector(watcherThread:) toTarget:self withObject:self];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
//	* DESTRUCTOR:
//		Releases the kqueue again.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(void) dealloc
{
	if( queueFD != -1 )
	{
		int		oldKQ = queueFD;
		queueFD = -1;
		close( oldKQ );
	}
	
	[watchedPaths release];
	[watchedFDs release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//	queueFD:
//		Returns a Unix file descriptor for the KQueue this uses. The descriptor
//		is owned by this object. Do not close it!
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(int)  queueFD
{
	return queueFD;
}


// -----------------------------------------------------------------------------
//	addPathToQueue:
//		Tell this queue to listen for all interesting notifications sent for
//		the object at the specified path. If you want more control, use the
//		addPathToQueue:notifyingAbout: variant instead.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(void) addPathToQueue: (NSString*)path
{
	[self addPathToQueue: path notifyingAbout: UKKQueueNotifyAboutRename
												| UKKQueueNotifyAboutWrite
												| UKKQueueNotifyAboutDelete
												| UKKQueueNotifyAboutAttributeChange];
}


// -----------------------------------------------------------------------------
//	addPathToQueue:notfyingAbout:
//		Tell this queue to listen for the specified notifications sent for
//		the object at the specified path.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(void) addPathToQueue: (NSString*)path notifyingAbout: (u_int)fflags
{
	struct timespec		nullts = { 0, 0 };
	struct kevent		ev;
	int					fd = open( [path fileSystemRepresentation], O_RDONLY, 0 );
	
    if( fd > 0 )
    {
        EV_SET( &ev, fd, EVFILT_VNODE, 
				EV_ADD | EV_ENABLE | EV_CLEAR,
				fflags, 0, (void*)path );
		
		[watchedPaths addObject: path];
		[watchedFDs addObject: [NSNumber numberWithInt: fd]];
    }
	
	kevent( queueFD, &ev, 1, NULL, 0, &nullts );
}


// -----------------------------------------------------------------------------
//	removePathFromQueue:
//		Stop listening for changes to the specified path. This removes all
//		notifications. Use this to balance both addPathToQueue:notfyingAbout:
//		as well as addPathToQueue:.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(void) removePathFromQueue: (NSString*)path
{
	int		index = [watchedPaths indexOfObject: path];
	
	if( index == NSNotFound )
		return;
	
	int			fd = [[watchedFDs objectAtIndex: index] intValue];
	
	[watchedFDs removeObjectAtIndex: index];
	[watchedPaths removeObjectAtIndex: index];
	
	close(fd);
}


// -----------------------------------------------------------------------------
//	watcherThread:
//		This method is called by our NSThread to loop and poll for any file
//		changes that our kqueue wants to tell us about. This sends separate
//		notifications for the different kinds of changes that can happen.
//		All messages are sent via the postNotification:forFile: main bottleneck.
//
//		This also calls sharedWorkspace's noteFileSystemChanged.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(void)		watcherThread: (id)sender
{
	int					n;
    struct kevent		ev;
    
    while( queueFD != -1 )
    {
		NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
		
		NS_DURING
			n = kevent( queueFD, NULL, 0, &ev, 1, NULL );
			if( n > 0 )
			{
				if( ev.filter == EVFILT_VNODE )
				{
					if( ev.fflags )
					{
						NSString*		fpath = (NSString *)ev.udata;
						NSLog(@"UKKQueue: Detected file change: %@ %x", fpath,ev.fflags);
						//[[NSWorkspace sharedWorkspace] noteFileSystemChanged: fpath];
						
						if( (ev.fflags & NOTE_RENAME) == NOTE_RENAME )
							[self postNotification: UKKQueueFileRenamedNotification forFile: fpath];
						if( (ev.fflags & NOTE_WRITE) == NOTE_WRITE )
							[self postNotification: UKKQueueFileWrittenToNotification forFile: fpath];
						if( (ev.fflags & NOTE_DELETE) == NOTE_DELETE )
							[self postNotification: UKKQueueFileDeletedNotification forFile: fpath];
						if( (ev.fflags & NOTE_ATTRIB) == NOTE_ATTRIB )
							[self postNotification: UKKQueueFileAttributesChangedNotification forFile: fpath];
						if( (ev.fflags & NOTE_EXTEND) == NOTE_EXTEND )
							[self postNotification: UKKQueueFileSizeIncreasedNotification forFile: fpath];
						if( (ev.fflags & NOTE_LINK) == NOTE_LINK )
							[self postNotification: UKKQueueFileLinkCountChangedNotification forFile: fpath];
						if( (ev.fflags & NOTE_REVOKE) == NOTE_REVOKE )
							[self postNotification: UKKQueueFileAccessRevocationNotification forFile: fpath];
					}
				}
			}
		NS_HANDLER
			NSLog(@"Error in UKKQueue: %@",localException);
		NS_ENDHANDLER
		
		[pool release];
    }
}


// -----------------------------------------------------------------------------
//	postNotification:forFile:
//		This is the main bottleneck for posting notifications. If you don't want
//		the notifications to go through NSWorkspace, override this method and
//		send them elsewhere.
//
//	REVISIONS:
//		2004-03-13	witness	Documented.
// -----------------------------------------------------------------------------

-(void) postNotification: (NSString*)nm forFile: (NSString*)fp
{
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName: nm object: fp];
	NSLog(@"Notification: %@ (%@)", nm, fp);
}


@end
