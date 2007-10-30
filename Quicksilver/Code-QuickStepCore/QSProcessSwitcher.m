

#import "QSProcessSwitcher.h"

typedef int CGSConnection;
typedef enum {
    CGSGlobalHotKeyEnable = 0,
    CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;

extern CGSConnection _CGSDefaultConnection(void);
extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, 
                                               CGSGlobalHotKeyOperatingMode mode);



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
