

#import <Foundation/Foundation.h>
#import <QSEffects/QSWindow.h>
#import <QSEffects/QSTrackingWindow.h>

@interface QSDockingWindow : QSBorderlessWindow {
	
	NSTrackingRectTag trackingRect;
	// BOOL hidden;
	
	NSTimer *hideTimer;
	NSTimeInterval lastTime;
	NSTimeInterval timeEntered;
	BOOL moving, locked, allowKey;
	
	NSString *autosaveName;
}

- (void)updateTrackingRect:(id)sender;
- (IBAction)hide:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)toggle:(id)sender;

/*!
 @lock
 @abstract locks a QSDocking window
 @discussion Locks the window, stopping it from closing if the mouse exits the window
			 or there's a key down. Called when a QSDockingWindow menu is opened
*/
- (void)lock;

/*!
 @unlock
 @abstract unlocks a QSDocking window
 @discussion unlocks the window, allowing it to close if the mouse exits the window
 or there's a key down. Called when a QSDockingWindow menu is closed
 */
- (void)unlock;

/*
 @isDocked
 @abstract Defines how the QSDocking window appears/disappears
 @discussion If the QSDocking window is touching a screen edge, returns YES otherwise NO
 @result YES if window is hidden into the screen edge, otherwise NO
*/
- (BOOL)isDocked;
- (BOOL)canFade;

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)newAutosaveName;
- (void)resignKeyWindowNow;
- (IBAction)orderFrontHidden:(id)sender;
- (void)saveFrame;
- (BOOL)hidden;
- (IBAction)hideOrOrderOut:(id)sender;
- (IBAction)showKeyless:(id)sender;
@end
