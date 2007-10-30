

#import <AppKit/AppKit.h>


@interface QSKeyboardTriggerReferenceView : NSView {
    NSArray *rects;
    NSMutableDictionary *dict;
    
    NSRect enclosingRect;
}

@end
