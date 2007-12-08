/* ProgressAppDelegate */

#import <Cocoa/Cocoa.h>

@interface ProgressAppDelegate : NSObject
{
}

// Action called by the "Test" button:
-(IBAction)	doProgressThing: (id)sender;

// Actions dispatched in a thread by doProgressThing:
-(IBAction)	doFirstProgressThing: (id)sender;
-(IBAction)	doSecondProgressThing: (id)sender;
-(IBAction)	doThirdProgressThing: (id)sender;

@end
