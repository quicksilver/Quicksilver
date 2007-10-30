

#import <Foundation/Foundation.h>
#import "SystemUIPlugin.h"
@protocol QSController
- (NSMenu *)statusMenuWithQuit;
- (void)activateInterface:(id)sender; 
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard;
- (void)displayStatusMenuAtPoint:(NSPoint)point;
- (NSImage *)daedalusImage;
@end


@interface QSMenuExtra : NSMenuExtra {
    NSBundle *qsBundle;
    NSMenu *menu;
    NSMenu *remoteMenu;
    BOOL qsRunning;
    NSConnection *connection;
//    NSDistantObject <QSController> *qsController;
}
-(void)openQS:(id)sender;
//-(void)activateQS:(id)sender;

//- (BOOL)establishConnection;
//- (void)setQsController:(NSDistantObject <QSController> *)newQsController;

- (NSDistantObject <QSController> *)qsController;
- (NSConnection *)connection;
- (void)setConnection:(NSConnection *)aConnection;

@end
