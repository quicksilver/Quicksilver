/* =============================================================================
	POJECT:		UKProgressPanel
	PURPOSE:	MT-Newswatcher/Finder-style progress window for keeping the
				user current on concurrently running tasks.
	AUTHORS:	M. Uli Kusterer (UK), (c) 2003, all rights reserved.
	
	REQUIRES:	UKProgressPanel.m
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

#import <Cocoa/Cocoa.h>


/* -----------------------------------------------------------------------------
	Forwards:
   -------------------------------------------------------------------------- */

@class UKProgressPanelTask;		// Forward declaration.


/* -----------------------------------------------------------------------------
	Controller:
   -------------------------------------------------------------------------- */

@interface UKProgressPanel : NSObject
{
	// All instance variables are *private*:
    IBOutlet NSView			*taskContentView;	// View that we add our progress elements' views to.
    IBOutlet NSTextField	*taskStatus;		// Status field displaying the number of tasks.
	IBOutlet NSWindow		*taskListWindow;	// The window in which we display our task list.
}

+(UKProgressPanel*)	sharedProgressPanel;


-(void)			orderFront: (id)sender;

// Private (automatically done for you on task creation):
-(void)			addProgressPanelTask: (UKProgressPanelTask*)element;
-(void)			removeProgressPanelTask: (UKProgressPanelTask*)element;

@end


/* -----------------------------------------------------------------------------
	Progress Panel NSApplication category:
		Use this for implementing a "Tasks" menu item.
   -------------------------------------------------------------------------- */

@interface NSApplication (UKProgressPanel)

-(IBAction)			orderFrontProgressPanel: (id)sender;	// Create and show the progress panel.

@end