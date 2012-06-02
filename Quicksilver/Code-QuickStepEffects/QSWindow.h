#import <Foundation/Foundation.h>
#import <QSFoundation/CGSPrivate.h>

@protocol QSWindowDelegate
- (void)firstResponderChanged:(NSResponder *)aResponder;
- (BOOL)shouldSendEvent:(NSEvent *)theEvent;
@end

@interface NSWindow (Effects)
- (void)pulse:(id)sender;
- (void)flare:(id)sender;
- (void)shrink:(id)sender;
- (void)fold:(id)sender;
@end

@class QSMoveHelper;

#define kQSWindowHideEffect @"hideEffect"
#define kQSWindowShowEffect @"showEffect"

#define kQSWindowExecEffect @"execEffect"
#define kQSWindowFadeEffect @"fadeEffect"
#define kQSWindowCancelEffect @"cancelEffect"

@interface QSWindow : NSPanel {
	NSRect trueRect;
	BOOL resizing;
	BOOL hidden;
	NSPoint mouseDownPoint;
	NSPoint hideOffset;
	NSPoint showOffset;
	BOOL fastShow;
	BOOL animationInvalid;
	BOOL isMoving;
	BOOL hadShadow;
	BOOL liesAboutKey;
	BOOL delegatesEvents;
	QSMoveHelper *helper;
	NSMutableDictionary *properties;
	NSMutableArray *eventDelegates;
}

- (NSMutableDictionary *)properties;
- (void)setProperties:(NSMutableDictionary *)newProperties;


- (IBAction)hideThreaded:(id)sender;
- (IBAction)showThreaded:(id)sender;


- (NSPoint)hideOffset;
- (void)setHideOffset:(NSPoint)newHideOffset;

- (NSPoint) showOffset;
- (void)setShowOffset:(NSPoint)newShowOffset;
- (void)reallyOrderFront:(id)sender;
- (void)fakeResignKey;
- (BOOL)liesAboutKey;
- (void)setLiesAboutKey:(BOOL)flag;
- (BOOL)delegatesEvents;
- (void)setDelegatesEvents:(BOOL)flag;
- (BOOL)fastShow;
- (void)setFastShow:(BOOL)flag;

- (QSMoveHelper *)helper;
- (void)setHelper:(QSMoveHelper *)aHelper;

- (id <QSWindowDelegate>)delegate;
- (void)setDelegate:(id <QSWindowDelegate>)delegate;
- (id)hideEffect;
- (void)setHideEffect:(id)aHideEffect;

- (id)showEffect;
- (void)setShowEffect:(id)aShowEffect;
- (void)reallyOrderOut:(id)sender;
- (void)hideWithEffect:(id)hideEffect;
- (void)performEffect:(NSDictionary *)effect;
- (void)finishHide:(id)sender;

- (void)setWindowProperty:(id)prop forKey:(NSString *)key;
@end

@interface QSBorderlessWindow : QSWindow 
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
<NSDraggingDestination>
#endif
@end

@interface NSWindow (CGSTransitionRedraw)
- (void)displayWithTransition:(CGSTransitionType) type option:(CGSTransitionOption)option duration:(CGFloat)duration;
@end
