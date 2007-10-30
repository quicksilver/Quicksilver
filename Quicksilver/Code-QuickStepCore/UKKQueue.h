//
//  UKKQueue.h
//  Filie
//
//  Created by Uli Kusterer on Sun Dec 21 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/event.h>


// Flags for notifyingAbout:
#define UKKQueueNotifyAboutRename					NOTE_RENAME		// Item was renamed.
#define UKKQueueNotifyAboutWrite					NOTE_WRITE		// Item contents changed (also folder contents changed).
#define UKKQueueNotifyAboutDelete					NOTE_DELETE		// item was removed.
#define UKKQueueNotifyAboutAttributeChange			NOTE_ATTRIB		// Item attributes changed.
#define UKKQueueNotifyAboutSizeIncrease				NOTE_EXTEND		// Item size increased.
#define UKKQueueNotifyAboutLinkCountChanged			NOTE_LINK		// Item's link count changed.
#define UKKQueueNotifyAboutAccessRevocation			NOTE_REVOKE		// Access to item was revoked.

// Notifications this sends:
//  (object is the file path registered with, and these are sent via the workspace notification center)
#define UKKQueueFileRenamedNotification				@"UKKQueueFileRenamedNotification"
#define UKKQueueFileWrittenToNotification			@"UKKQueueFileWrittenToNotification"
#define UKKQueueFileDeletedNotification				@"UKKQueueFileDeletedNotification"
#define UKKQueueFileAttributesChangedNotification   @"UKKQueueFileAttributesChangedNotification"
#define UKKQueueFileSizeIncreasedNotification		@"UKKQueueFileSizeIncreasedNotification"
#define UKKQueueFileLinkCountChangedNotification	@"UKKQueueFileLinkCountChangedNotification"
#define UKKQueueFileAccessRevocationNotification	@"UKKQueueFileAccessRevocationNotification"


@interface UKKQueue : NSObject
{
	int				queueFD;		// The actual queue ID.
	NSMutableArray* watchedPaths;   // List of NSStrings containing the paths we're watching.
	NSMutableArray* watchedFDs;		// List of NSNumbers containing the file descriptors we're watching.
}

-(int)  queueFD;		// I know you unix geeks want this...

// High-level file watching:
-(void) addPathToQueue: (NSString*)path;
-(void) addPathToQueue: (NSString*)path notifyingAbout: (u_int)fflags;
-(void) removePathFromQueue: (NSString*)path;

-(void) postNotification: (NSString*)nm forFile: (NSString*)fp; // Message-posting bottleneck.

// private:
-(void)		watcherThread: (id)sender;
-(void)		postNotification: (NSString*)nm forFile: (NSString*)fp;

@end
