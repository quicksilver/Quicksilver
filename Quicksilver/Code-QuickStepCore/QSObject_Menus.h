

#import <Foundation/Foundation.h>

#import "QSObject.h"
@interface QSObject (Menus) <NSMenuDelegate>
- (NSMenu *)menu;
- (NSMenuItem *)menuItem;
- (NSMenu *)rankMenuWithTarget:(NSView *)target;

- (NSMenu *)actionsMenu;

- (NSMenu *)fullMenu;

- (NSMenu *)childrenMenu;
- (NSMenuItem *)menuItemWithChildren:(BOOL)includeChildren;
@end
