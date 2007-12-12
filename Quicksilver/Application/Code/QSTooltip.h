

#import <AppKit/AppKit.h>

@interface NSToolTipPanel : NSPanel
@end
@interface NSToolTipPanel (TopRightCornerPlacementPatch)
- (void)orderFront:(id)sender;
@end

/*
@interface NSToolTipManager (QSMods)

+ (id)sharedToolTipManager;
- (id)init;
- (void)dealloc;
- (void)setInitialToolTipDelay:(double)fp8;
- (void)_checkToolTipDelay;
- (void)windowDidBecomeKeyNotification:(id)fp8;
- (BOOL)_shouldInstallToolTip:(void *)fp8;
- (int)_addTrackingRect:(struct _NSRect)fp8 andStartToolTipIfNecessary:(BOOL)fp24 view:(id)fp28 owner:(id)fp32 toolTip:(id)fp36 reuseExistingTrackingNum:(BOOL)fp40;
- (void)addTrackingRectForToolTip:(id)fp8 reuseExistingTrackingNum:(BOOL)fp12;
- (int)_setToolTip:(id)fp8 forView:(id)fp12 cell:(id)fp16 rect:(struct _NSRect)fp20 owner:(id)fp36 ownerIsDisplayDelegate:(BOOL)fp40 userData:(void *)fp44;
- (void)_removeToolTip:(id)fp8 stopTimerIfNecessary:(BOOL)fp12;
- (void)_removeTrackingRectForToolTip:(id)fp8 stopTimerIfNecessary:(BOOL)fp12;
- (int)setToolTipForView:(id)fp8 rect:(struct _NSRect)fp12 displayDelegate:(id)fp28 userData:(void *)fp32;
- (int)setToolTipForView:(id)fp8 rect:(struct _NSRect)fp12 owner:(id)fp28 userData:(void *)fp32;
- (void)setToolTipWithOwner:(id)fp8 forView:(id)fp12 cell:(id)fp16;
- (void)setToolTip:(id)fp8 forView:(id)fp12 cell:(id)fp16;
- (void)removeToolTipForView:(id)fp8 tag:(int)fp12;
- (BOOL)viewHasToolTips:(id)fp8;
- (void)removeAllToolTipsForView:(id)fp8;
- (void)removeAllToolTipsForView:(id)fp8 withOwner:(id)fp12;
- (id)toolTipForView:(id)fp8 cell:(id)fp12;
- (void)recomputeToolTipsForView:(id)fp8 remove:(BOOL)fp12 add:(BOOL)fp16;
- (void)startTimer:(float)fp8 userInfo:(id)fp12;
- (void)stopTimer;
- (void)_stopTimerIfRunningForToolTip:(id)fp8;
- (void)displayToolTip:(id)fp8;
- (void)orderOutToolTip;
- (void)fadeToolTip:(id)fp8;
- (void)orderOutToolTipImmediately:(BOOL)fp8;
- (void)abortToolTip;
- (void)mouseEnteredToolTip:(id)fp8 inWindow:(id)fp12 withEvent:(id)fp16;
- (void)mouseEntered:(id)fp8;
- (void)mouseExited:(id)fp8;

@end

*/

/*
@interface QSTooltipWindow : QSWindow
{
    NSTimer *closeTimer;
    id tooltipObject;
}
+ (id)tipWithString:(NSString *)tip frame:(NSRect)frame display:(BOOL)display;
+ (id)tipWithAttributedString:(NSAttributedString *)tip frame:(NSRect)frame display:(BOOL)display;

    // returns the approximate window size needed to display the tooltip string.
+ (NSSize)suggestedSizeForTooltip:(id)tooltip;

    // setting and getting the default duration..
+ (void)setDefaultDuration:(NSTimeInterval)inSeconds;
+ (NSTimeInterval)defaultDuration;

    // setting and getting the default bgColor
+ (void)setDefaultBackgroundColor:(NSColor *)bgColor;
+ (NSColor *)defaultBackgroundColor;

- (id)init;

- (id)tooltip;
- (void)setTooltip:(id)tip;

- (void)orderFrontWithDuration:(NSTimeInterval)seconds;

@end
*/