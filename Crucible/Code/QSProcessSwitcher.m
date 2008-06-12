

#import "QSProcessSwitcher.h"

@implementation QSProcessSwitcher

- (id)initWithWindow:(NSWindow *)window{
    if (!(self=[super initWithWindow:window])) return nil;

    return self;
}


- (void)activate:(id)sender{
     //   CGSConnection conn = _CGSDefaultConnection();
    //    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
}

- (void)deactivate:(id)sender{
       // CGSConnection conn = _CGSDefaultConnection();
       // CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
}
	
@end
