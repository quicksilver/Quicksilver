#import "ProgressAppDelegate.h"
#import "UKProgressPanelTask.h"
#import "UKProgressPanel.h"			// Our validateMenuItem handler needs that.
#include <unistd.h>

@implementation ProgressAppDelegate


// This action is called by our "test" button:
-(IBAction)	doProgressThing: (id)sender
{
	[NSThread detachNewThreadSelector: @selector(doFirstProgressThing:) toTarget: self withObject: nil];
	[NSThread detachNewThreadSelector: @selector(doSecondProgressThing:) toTarget: self withObject: nil];
	[NSThread detachNewThreadSelector: @selector(doThirdProgressThing:) toTarget: self withObject: nil];
}


// The following three actions are called in separate threads:
-(IBAction)	doFirstProgressThing: (id)sender
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];			// Threads need one of these.
	
	int							x, xmax = 25;							// Just some vars so we can fake a lengthy operation
	UKProgressPanelTask*		task = [UKProgressPanelTask newProgressPanelTask];	// Create a progress bar etc. in our progress panel, showing and creating a panel if necessary.
	
	// Set up the progress bar and title/status message to be shown for this task:
	[task setIndeterminate: YES];										// By default, you get a determinate scrollbar, but we want barber-pole style.
	[task setTitle: @"Inviting folks to the party"];					// Title should describe the action the user triggered, so she knows what progress bar belongs to what operation.
	[task setStatus: @"The Witnesses of TeachText are everywhere..."];	// Status is the display that changes and gives some more information than the progress bar would.

	for( x = 0; x <= xmax && ![task stopped]; x++ )		// Loop until we have xmax iterations or the user clicked the "Stop" button.
	{
		[task animate: nil];	// Keep the progress bar spinning.
		sleep(1);				// short delay so user can see the tasks in the task panel. Otherwise this loop would be over before the user even notices.
	}
	
	[task release];		// Remove the progress bar, status fields etc. from the progress panel, we're finished!
	[pool release];		// Kill everything in the pool.
}


-(IBAction)	doSecondProgressThing: (id)sender
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// doFirstProgressThing: documents most of this already.
	
	int							x, xmax = 100;
	UKProgressPanelTask*		task = [UKProgressPanelTask newProgressPanelTask];
	
	[task setMaxValue: xmax];	// Set the maximum value of the scroll bar.
	[task setTitle: @"Inventing my own programming language"];
	[task setStatus: @"Not much to do here."];

	for( x = 0; x <= xmax && ![task stopped]; x++ )
	{
		[task setDoubleValue: x];	// Change the value of the progress bar to indicate our progress.
		sleep(1);
	}
	
	[task release];
	[pool release];
}


-(IBAction)	doThirdProgressThing: (id)sender
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	int							x, xmax = 64;
	UKProgressPanelTask*		task = [UKProgressPanelTask newProgressPanelTask];
	
	[task setMaxValue: xmax];
	[task setTitle: @"Learning to play the piano"];

	for( x = 0; x <= xmax && ![task stopped]; x++ )
	{
		[task setDoubleValue: x];
		[task setStatus: [NSString stringWithFormat: @"Key %d.", x]];	// Just to show you that you can also display some more detailed status info.
		sleep(1);
	}
	
	[task release];
	[pool release];
}


@end
