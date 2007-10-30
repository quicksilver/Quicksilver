

#import <AppKit/AppKit.h>

#import "SystemUIPlugin.h"


@interface NSStatusBarButton:NSButton
{
}

+ (void)initialize;

- initWithFrame:(NSRect)fp8 inStatusBar:fp24;
- statusMenu;
- (void)setStatusMenu:fp8;
- (char)highlightMode;
- (void)setHighlightMode:(char)fp8;

@end

@interface QSMenuExtraView : NSMenuExtraView {
    //NSStatusItem *statusItem;
    id delegate;
}

- initWithFrame:(NSRect)frame menuExtra:(NSMenuExtra *)extra;
	
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
@end
 