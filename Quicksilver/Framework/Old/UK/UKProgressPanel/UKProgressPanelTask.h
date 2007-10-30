/* =============================================================================
	POJECT:		UKProgressPanel
	FILE:		UKProgressPanelTask.h
	PURPOSE:	A single "task" (i.e. progress bar and status text field) for
				our MT-Newswatcher/Finder-style progress window for keeping the
				user current on concurrently running tasks.
	AUTHORS:	M. Uli Kusterer (UK), (c) 2003, all rights reserved.
	
	REQUIRES:	UKProgressPanelTask.m
				UKProgressPanelTask.nib
				UKProgressPanel.h
				UKProgressPanel.m
				(UKProgressPanel.nib)
				(UKProgressPanel.strings)
	
	NOTE:		UKProgressPanel and UKProgressPanelTask are thread-safe.
	
	DIRECTIONS:
			Using the progress panel is very simple: Use newProgressPanelTask
			and consorts to create a new task when you begin your lengthy
			operation, and release it when you have finished.
			
			The task will automatically take care of creating and showing the
			progress panel if needed, and will add itself to the shared
			progress panel instance.
			
			A task supports most of the methods of NSProgressIndicator to
			allow you to control the progress bar without any deep-reaching
			code changes. Use setTitle: to provide a general title indicating
			what action this is (e.g. "Emptying the trash"). The title will be
			displayed in bold above the progress bar. Use setStatus: to provide
			information about the step currently being executed, expected time
			to finish etc. - This will be displayed below the progress bar.
   ========================================================================== */

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import <Cocoa/Cocoa.h>


/* -----------------------------------------------------------------------------
	UKProgressPanelTask:
		A single operation in the progress panel.
   -------------------------------------------------------------------------- */

@interface UKProgressPanelTask : NSObject
{
	// All member variables are *private*:
    IBOutlet NSProgressIndicator	*progressBar;			// Progress bar we update.
    IBOutlet NSView					*progressTaskView;		// View we display our stuff in.
    IBOutlet NSTextField			*progressStatusField;	// Status field we display detailed in.
    IBOutlet NSTextField			*progressTitleField;	// Title field that describes the general operation.
	IBOutlet NSButton				*progressStopButton;	// The "Stop" button for cancelling this task.
	
	IBOutlet id						stopDelegate;			// The delegate that is sent our "stop" message.
	SEL								stopAction;				// The selector to be called on the "stop delegate" when the user clicks the "stop" button. Defaults to stop:
	BOOL							stopped;				// Has this task been stopped by the user?
}

/* Convenience constructors:
	The caller (i.e. you) is responsible for releasing this object once the
	operation is finished. */
+(id)			newProgressPanelTask;


// Controlling progress bar:
-(double)		minValue;
-(double)		maxValue;
-(void)			setMinValue: (double)newMinimum;
-(void)			setMaxValue: (double)newMaximum;

-(double)		doubleValue;
-(void)			setDoubleValue: (double)doubleValue;
-(void)			incrementBy: (double)delta;

-(BOOL)			isIndeterminate;				
-(void)			setIndeterminate: (BOOL)flag;
-(void)			animate: (id)sender;						// I'm not letting you have automatic timer animation. This is for feedback, not for making the user dizzy.


// Title/Status:
-(void)			setTitle: (NSString*)title;		// "Emptying trash", or whatever, above the p-bar in bold-face.
-(void)			setStatus: (NSString*)status;	// "15 bytes of 1024 deleted" below the p-bar.


// Handling the "Stop" button:
-(BOOL)			stopped;						// Has the user requested this task to be stopped?

-(void)			setStopDelegate: (id)target;	// Alternate approach: Call an action on an object.
-(id)			stopDelegate;
-(void)			setStopAction: (SEL)action;
-(SEL)			stopAction;

// private:
-(IBAction)		stop: (id)sender;
-(NSView*)		progressTaskView;

@end
