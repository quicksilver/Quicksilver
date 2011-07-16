/* QSController */

#import <Cocoa/Cocoa.h>
#import <QSFoundation/QSFoundation.h>
#import <QSCore/QSCore.h>
#import <QSInterface/QSResizingInterfaceController.h>

// added by RCS
@class QSMenuButton;

@interface QSBezelInterfaceController : QSResizingInterfaceController {
	NSRect standardRect;
	IBOutlet NSTextField *details;

    // added by RCS
    // outlet for pull-down menu button
    // connected to QSBezelInterface.xib in Interface Builder
    IBOutlet QSMenuButton *qsMenuButton;
}

- (NSRect) rectForState:(BOOL)expanded;


// added by RCS
// event handler for pull-down menu button
// connected to QSBezelInterface.xib in Interface Builder
- (IBAction)qsMenuButtonPressed:(id)sender;

@end

@interface NSWindow (QSBezelInterfaceController)

-(NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame;

@end