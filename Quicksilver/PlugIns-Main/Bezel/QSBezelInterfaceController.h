/* QSController */

#import <Cocoa/Cocoa.h>
#import <QSFoundation/QSFoundation.h>
#import <QSCore/QSCore.h>
#import <QSInterface/QSResizingInterfaceController.h>

@class QSMenuButton;

@interface QSBezelInterfaceController : QSResizingInterfaceController {
	NSRect standardRect;
	IBOutlet NSTextField *details;

    // outlet for pull-down menu button
    // connected to QSBezelInterface.xib in Interface Builder
    //IBOutlet QSMenuButton *menuButton;
}

- (NSRect) rectForState:(BOOL)expanded;


// event handler for pull-down menu button
// connected to QSBezelInterface.xib in Interface Builder
- (IBAction)qsMenuButtonPressed:(id)sender;

@end

@interface NSWindow (QSBezelInterfaceController)

-(NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame;

@end