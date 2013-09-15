#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

/* Deprecated. Use [NSApp completedLaunch] */
extern BOOL QSApplicationCompletedLaunch;

@interface QSApp : NSApplication {
	BOOL shouldRelaunch;
	IBOutlet NSMenu *hiddenMenu;
	NSResponder *globalKeyEquivalentTarget;
	NSMutableArray *eventDelegates;
}

- (void)forwardWindowlessRightClick:(NSEvent *)theEvent;
- (BOOL)completedLaunch;
- (BOOL)isPrerelease;
- (NSResponder *)globalKeyEquivalentTarget;
- (void)setGlobalKeyEquivalentTarget:(NSResponder *)value;
- (void)addEventDelegate:(id)eDelegate;
- (void)removeEventDelegate:(id)eDelegate;

- (void)qs_beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)docWindow completionHandler:(void (^)(NSInteger result))completionHandler;
@end
