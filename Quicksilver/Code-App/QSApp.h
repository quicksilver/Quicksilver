#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface QSApp : NSApplication {
	BOOL shouldRelaunch;
	IBOutlet NSMenu *hiddenMenu;
	NSResponder *globalKeyEquivalentTarget;
	NSMutableArray *eventDelegates;
}

- (void)forwardWindowlessRightClick:(NSEvent *)theEvent;
- (BOOL)completedLaunch;
+ (void)setCompletedLaunch:(BOOL)flag;
- (BOOL)isPrerelease;
- (NSResponder *)globalKeyEquivalentTarget;
- (void)setGlobalKeyEquivalentTarget:(NSResponder *)value;
- (void)addEventDelegate:(id)eDelegate;
- (void)removeEventDelegate:(id)eDelegate;

@end
