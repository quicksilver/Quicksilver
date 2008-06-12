

#import <Foundation/Foundation.h>

#import "QSMoveHelper.h"
@interface NSObject (QSWindowDelegate)
- (void)firstResponderChanged:(NSResponder *)aResponder;
- (BOOL)shouldSendEvent:(NSEvent *)theEvent;
@end

@interface NSWindow (Effects)
- (void)pulse:(id)sender;
- (void)flare:(id)sender;
- (void)shrink:(id)sender;
- (void)fold:(id)sender;
@end

#define kQSWindowHideEffect @"hideEffect"
#define kQSWindowShowEffect @"showEffect"

#define kQSWindowExecEffect @"execEffect"
#define kQSWindowFadeEffect @"fadeEffect"
#define kQSWindowCancelEffect @"cancelEffect"

@interface QSWindow : NSPanel {
    NSRect trueRect;
    bool resizing;
    bool hidden;
    NSPoint mouseDownPoint;
    NSPoint hideOffset;
    NSPoint showOffset;
    bool fastShow;
    bool animationInvalid;
    bool isMoving;
    bool hadShadow;
    bool liesAboutKey;
    bool delegatesEvents;
	QSMoveHelper *helper;
	NSMutableDictionary *properties;
	NSMutableArray *eventDelegates;
}

- (NSMutableDictionary *)properties;
- (void)setProperties:(NSMutableDictionary *)newProperties;

- (IBAction) hideThreaded:(id)sender;
- (IBAction) showThreaded:(id)sender;

- (NSPoint)hideOffset;
- (void)setHideOffset:(NSPoint)newHideOffset;

- (NSPoint)showOffset;
- (void)setShowOffset:(NSPoint)newShowOffset;
- (void)reallyOrderFront:(id)sender;
- (void)fakeResignKey;
- (bool)liesAboutKey;
- (void)setLiesAboutKey:(bool)flag;
- (bool)delegatesEvents;
- (void)setDelegatesEvents:(bool)flag;
- (bool)fastShow;
- (void)setFastShow:(bool)flag;

- (QSMoveHelper *)helper;
- (void)setHelper:(QSMoveHelper *)aHelper;

- (id)hideEffect;
- (void)setHideEffect:(id)aHideEffect;

- (id)showEffect;
- (void)setShowEffect:(id)aShowEffect;
- (void)reallyOrderOut:(id)sender;
- (void)hideWithEffect:(id)hideEffect;
- (void)performEffect:(NSDictionary *)effect;
- (void)finishHide:(id)sender;

- (id)windowPropertyForKey:(NSString *)key;
- (void)setWindowProperty:(id)prop forKey:(NSString *)key;
@end

@interface QSBorderlessWindow : QSWindow
@end

@interface NSWindow (CGSTransitionRedraw)
- (void) displayWithTransition:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(float)duration;
@end