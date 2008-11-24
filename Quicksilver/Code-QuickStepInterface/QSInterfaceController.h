/* QSController */

#import <Cocoa/Cocoa.h>

@class QSSearchObjectView;
@class QSActionMatrix;

@class QSWindow;
@class QSMenuButton;
//@class QSPrefsController;
@class QSObject, QSBasicObject;
@class QSCommand;
@interface QSInterfaceController : NSWindowController {
	IBOutlet QSSearchObjectView *dSelector;
	IBOutlet QSSearchObjectView *aSelector;
	IBOutlet QSSearchObjectView *iSelector;

	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet id commandView;
	IBOutlet QSMenuButton *menuButton;
    
	NSTimer *hideTimer;
	NSTimer *actionsUpdateTimer;
	NSTimer *clearTimer;
	BOOL hidingWindow;
	BOOL preview;
}
- (QSCommand *)currentCommand;
- (void)setCommand:(QSCommand *)command;
- (void)setCommandWithArray:(NSArray *)array;

- (IBAction)showInterface:(id)sender;
- (IBAction)activate:(id)sender;
- (IBAction)activateInTextMode:(id)sender;
- (IBAction)actionActivate:(id)sender;

- (IBAction)executeCommand:(id)sender;
- (IBAction)executeCommandAndContinue:(id)sender;
- (IBAction)shortCircuit:(id)sender;
- (IBAction)encapsulateCommand:(id)sender;

- (IBAction)customize:(id)sender;

- (IBAction)hideWindows:(id)sender;

- (IBAction)showTasks:(id)sender;

- (void)selectObject:(QSBasicObject *)object;
- (QSBasicObject *)selection;

- (void)searchArray:(NSArray *)array;
- (void)showArray:(NSArray *)array;

- (void)showMainWindow:(id)sender;
- (void)hideMainWindow:(id)sender;
- (void)hideMainWindowFromExecution:(id)sender;
- (void)hideMainWindowFromCancel:(id)sender;
- (void)hideMainWindowFromFade:(id)sender;

- (void)showIndirectSelector:(id)sender;
- (void)hideIndirectSelector:(id)sender;

- (void)updateActions;
- (void)updateActionsNow;

- (void)updateIndirectObjects;
- (void)updateViewLocations;
- (void)invalidateHide;

- (void)encapsulateCommand;

- (void)executeCommandThreaded;
- (void)executePartialCommand:(NSArray *)array;

- (void)searchObjectChanged:(NSNotification*)notif;

- (QSSearchObjectView *)dSelector;
- (QSSearchObjectView *)aSelector;
- (QSSearchObjectView *)iSelector;

- (QSMenuButton *)menuButton;

- (NSProgressIndicator *)progressIndicator;

- (NSSize)maxIconSize;

- (void)fireActionUpdateTimer;
- (void)setClearTimer;

// set to YES to prevent hiding, no to allow hiding again.
- (BOOL)hiding;
- (void)setHiding:(BOOL)flag;

- (BOOL)preview;
- (void)setPreview:(BOOL)flag;

@end
