

#import <Foundation/Foundation.h>

#import "QSObject.h"
@interface QSObject (Menus)
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
   <NSMenuDelegate>
#endif
- (NSMenu *)menu;
- (NSMenuItem *)menuItem;
- (NSMenu *)rankMenuWithTarget:(NSView *)target;

- (NSMenu *)actionsMenu;

- (NSMenu *)fullMenu;

- (NSMenu *)childrenMenu;
- (NSMenuItem *)menuItemWithChildren:(BOOL)includeChildren;
@end
