/* =============================================================================
	POJECT:		UKProgressPanel
	PURPOSE:	MT-Newswatcher/Finder-style progress window for keeping the
				user current on concurrently running tasks.
	AUTHORS:	M. Uli Kusterer (UK), (c) 2003, all rights reserved.
	
	REQUIRES:	UKProgressPanel.h
				UKProgressPanel.nib
				UKProgressPanel.strings
				UKProgressPanelTask.h
				UKProgressPanelTask.m
				(UKProgressPanelTask.nib)
	
	NOTE:		UKProgressPanel and UKProgressPanelTask are thread-safe.
	
	DIRECTIONS:
			The only interesting part of this file really is the category
			at the bottom of the file. It implements the IBAction
			orderFrontProgressPanel:, which you can use to implement a menu
			item to show the progress panel.
   ========================================================================== */

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import "UKProgressPanel.h"
#import "UKProgressPanelTask.h"


/* -----------------------------------------------------------------------------
	Globals:
   -------------------------------------------------------------------------- */

static UKProgressPanel*		gMainProgressPanel = nil;	// Here we keep track of our shared panel instance (singleton pattern).
NSLock*						gUKProgressPanelThreadLock = nil;			// Users will want to use threads with this. We need a mutex lock to avoid several progress panels and such stuff.


@implementation UKProgressPanel

+(void)	initialize
{
	gUKProgressPanelThreadLock = [[NSLock alloc] init];
}


/* -----------------------------------------------------------------------------
	sharedProgressPanel:
		Returns a pointer to our shared UKProgresspanel instance, creating
		it if none exists yet.
   -------------------------------------------------------------------------- */

+(UKProgressPanel*)	sharedProgressPanel
{
	[gUKProgressPanelThreadLock lock];
	if( !gMainProgressPanel )
		gMainProgressPanel = [[self alloc] init];
	[gUKProgressPanelThreadLock unlock];
	
	return gMainProgressPanel;
}


/* -----------------------------------------------------------------------------
	Constructor:
		Loads the progress window from UKProgressPanel.nib and slightly changes
		its behavior in ways that aren't possible through the NIB.
		
	NOTE:
		This window's behavior has been chosen intentionally. It uses a utility
		window with small title bar since it's not associated with a document
		and isn't one itself, but it still performs the function of a palette.
		
		It is set not to hide when the application is in the background since
		the user may want to check whether the app has finished while it was
		in the background.
		
		It is also set to be at normal window level because the default level
		for utility windows is a system-wide floater, which would mean our
		progress window would obscure other apps' windows. It is also at normal
		window level to allow that the user send it behind another window when
		working.
   -------------------------------------------------------------------------- */

-(id)	init
{
	if( self = [super init] )
	{
		[NSBundle loadNibNamed: @"UKProgressPanel" owner: self];
		[taskListWindow setHidesOnDeactivate: NO];		// Allow checking on progress while app's in back.
		[taskListWindow setLevel: NSNormalWindowLevel];	// Allow sending it behind documents.
		[taskListWindow setReleasedWhenClosed: NO];		// Only hide on close box click.
	}
	
	return self;
}


/* -----------------------------------------------------------------------------
	Destructor:
		Note that you may *not* destruct this window while any tasks listed
		in it are still running. To avoid circular dependencies, this window
		does not know which tasks it contains. It does know about their content
		views, though.
   -------------------------------------------------------------------------- */

-(void)	dealloc
{
	[gUKProgressPanelThreadLock lock];
	[taskListWindow orderOut: nil];
	[taskListWindow release];
	
	gMainProgressPanel = nil;	// Make sure user can create a new shared instance if desired.
	[gUKProgressPanelThreadLock unlock];
	
	[super dealloc];
}


/* -----------------------------------------------------------------------------
	orderFront:
		Passes the message on to the task list panel.
   -------------------------------------------------------------------------- */

-(void)	orderFront: (id)sender
{
	[taskListWindow orderFront: sender];
}


/* -----------------------------------------------------------------------------
	addProgressPanelTask:
		This is called by UKProgressPanelTasks when they are created. It adds
		the task's view to the list in the window above the current tasks.
		Then it brings the window to the front so the user sees that there's
		a new task in progress. Since the window can't become key, the user
		shouldn't be too annoyed by this, as keyboard focus etc. aren't
		changed.
		
		This also updates the "n tasks in progress..." message at the top
		of the window.
   -------------------------------------------------------------------------- */

-(void)	addProgressPanelTask: (UKProgressPanelTask*)theElement
{
	[gUKProgressPanelThreadLock lock];

	NSArray*			subs = [taskContentView subviews];
	NSView*				lastTaskView = [subs lastObject];
	
	[taskContentView addSubview: [theElement progressTaskView]];
	
	if( lastTaskView )
	{
		NSRect	lastBox = [lastTaskView frame];
		NSSize	newSize;
		
		// Position the new box above all others:
		lastBox.origin.y += lastBox.size.height;							// Move box up one slot.
		[[theElement progressTaskView] setFrameOrigin: lastBox.origin];	// Move new field to this position.
		
		// Calculate total height up to our new box:
		newSize = lastBox.size;
		newSize.height += lastBox.origin.y;					// So the final separator line gets "tucked under" the top of the scroll area.
		[taskContentView setFrameSize: newSize];			// Make content view that size.
		
		// Scroll new box into view:
		[taskContentView scrollRectToVisible: lastBox];
	}
	
	// Update "number of tasks" status display:
	[taskStatus setStringValue: [NSString stringWithFormat: NSLocalizedStringFromTable(@"%u tasks in progress...",@"UKProgressPanel", nil), [subs count]]];
	[taskStatus setNeedsDisplay:YES];
	
	[taskListWindow orderFront: nil];
	[taskContentView setNeedsDisplay:YES];

	[gUKProgressPanelThreadLock unlock];
}


/* -----------------------------------------------------------------------------
	removeProgressPanelTask:
		This is called by UKProgressPanelTasks when they are destroyed. It
		removes the task's view from the list in the window, moving down any
		views above it.
		
		This also updates the "n tasks in progress..." message at the top
		of the window.
   -------------------------------------------------------------------------- */

-(void)	removeProgressPanelTask: (UKProgressPanelTask*)theElement
{
	[gUKProgressPanelThreadLock lock];

	NSArray*			subs = [taskContentView subviews];
	unsigned int		pos = [subs indexOfObject: [theElement progressTaskView]];
	NSEnumerator*		elEnum = [subs objectEnumerator];
	NSSize				sizeGone = [[theElement progressTaskView] frame].size;
	unsigned int		x;
	NSView*				currElemView;
	
	// Move down elements above the one we're removing:
	for( x = 0; currElemView = [elEnum nextObject]; x++ )
	{
		if( x > pos )
		{
			NSPoint		currOrigin = [currElemView frame].origin;
			currOrigin.y -= sizeGone.height;
			[currElemView setFrameOrigin: currOrigin];
		}
	}
	
	[[theElement progressTaskView] removeFromSuperview];
	[taskContentView setNeedsDisplay:YES];
	
	// Update "number of tasks" status display:
	unsigned int tCount = [subs count];
	if( tCount == 0 )
		[taskStatus setStringValue: NSLocalizedStringFromTable(@"No active tasks.",@"UKProgressPanel", nil)];
	else
		[taskStatus setStringValue: [NSString stringWithFormat: NSLocalizedStringFromTable(@"%u tasks in progress...",@"UKProgressPanel", nil), tCount]];
	[taskStatus setNeedsDisplay:YES];
	
	// Resize scroller's content area:
	NSSize		newSize = [taskContentView frame].size;
	newSize.height -= sizeGone.height;
	[taskContentView setFrameSize: newSize];
	[taskContentView setNeedsDisplay:YES];

	[gUKProgressPanelThreadLock unlock];
}


@end


@implementation NSApplication (UKProgressPanel)

/* -----------------------------------------------------------------------------
	orderFrontProgressPanel:
		Category on NSApplication that adds a method for bringing the shared
		progress panel to front, creating it if there isn't one yet. You can
		use this as the action of a menu item (suggested name "Tasks") in your
		"Window" menu to allow that the user re-show the progress window once
		he has hidden it by clicking its close box.
   -------------------------------------------------------------------------- */

-(IBAction)			orderFrontProgressPanel: (id)sender
{
	[[UKProgressPanel sharedProgressPanel] orderFront: self];
}

@end
