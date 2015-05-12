

#import "QSObject_Menus.h"

#import "QSLibrarian.h"
#import "QSAction.h"

#import "QSCommand.h"
#import "QSExecutor.h"

#import "NSSortDescriptor+BLTRExtensions.h"

@implementation QSObject (Menus)
//
//- (NSMenu *)menu {
// NSLog(@"Menu for: %@", self);
//	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"ContextMenu"] autorelease];
//
//	NSArray *actions = [[QSLibrarian sharedInstance] validActionsForDirectObject:self indirectObject:nil];
//
//	// actions = [actions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//
//	NSMenuItem *item;
//	int i;
//	for (i = 0; i<[actions count]; i++) {
//		QSAction *action = [actions objectAtIndex:i];
//		if (action) {
//			NSArray *componentArray = [[action name] componentsSeparatedByString:@"/"];
//
//			NSImage *menuIcon = [[[action icon] copy] autorelease];
//			[menuIcon setSize:NSMakeSize(16, 16)];
//
//			if ([componentArray count] >1) {
//				NSMenuItem *groupMenu = [menu itemWithTitle:[componentArray objectAtIndex:0]];
//				if (!groupMenu) {
//					groupMenu = [[[NSMenuItem alloc] initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""] autorelease];
//					if (menuIcon) [groupMenu setImage:menuIcon];
//					[groupMenu setSubmenu: [[[NSMenu alloc] initWithTitle:[componentArray objectAtIndex:0]]autorelease]];
//					[menu addItem:groupMenu];
//				}
//				item = (NSMenuItem *)[[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1] action:@selector(performMenuAction:) keyEquivalent:@""];
//			}
//			else
//				item = (NSMenuItem *)[menu addItemWithTitle:[action name] action:@selector(performMenuAction:) keyEquivalent:@""];
//
//			[item setTarget:self];
//			[item setRepresentedObject:action];
//			if (menuIcon) [item setImage:menuIcon];
//
//		}
//	}
//
//
//	return menu;
//
//}
- (void)performActionFromMenuItem:(id)sender {
	NSLog(@"sender %@", sender);
	NSArray *actions = [QSExec rankedActionsForDirectObject:(QSObject *)self indirectObject:nil];

	QSCommand *command = [QSCommand commandWithDirectObject:self
											 actionObject:[actions objectAtIndex:0]
										  indirectObject:nil];
	[command execute];
}

- (NSMenuItem *)menuItem {
	return ([self menuItemWithChildren:NO]);
}

- (BOOL)applyIconToMenuItem:(NSMenuItem *)item {
	NSImage *iconCopy = [[self icon] copy];
	[iconCopy setSize:QSSize16];
	[item setImage:iconCopy];
	return YES;
}

- (BOOL)configureMenuItem:(NSMenuItem *)item includeChildren:(BOOL)includeChildren {
	NSString *title = [self name];
	if (!title) title = @"";
	[item setTitle:title];
	//	[self loadIcon];
	[self applyIconToMenuItem:item];
	[item setRepresentedObject:self];

	if (/* DISABLES CODE */ (0)) {
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, nil];
		NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:[self name] attributes:attrs];
		[item setAttributedTitle:attrTitle];
	}
	if (includeChildren) {
		NSMenu *submenu = [self fullMenu];
		NSTimer *timer = [NSTimer timerWithTimeInterval:0.0 target:self selector:@selector(loadIconAndUpdateMenuItem:) userInfo:item repeats:NO];

		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
		if (submenu) {
			[item setSubmenu:submenu];
		} else {
			[item setTarget:self];
			[item setAction:@selector(performActionFromMenuItem:)];
		}
	}
	return item != nil;
}
- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	//	NSLog(@"Validate %@", anItem);
	return YES;
}
- (void)loadIconAndUpdateMenuItem:(NSTimer *)timer {
	//NSLog(@"loadicon %@", self);
	NSMenuItem *item = [timer userInfo];
	[self loadIcon];
	[self applyIconToMenuItem:item];

}
- (NSMenuItem *)menuItemWithChildren:(BOOL)includeChildren {
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[self name] action:nil keyEquivalent:@""];
	[self configureMenuItem:item includeChildren:(BOOL)includeChildren];
	return item;
}
- (NSMenu *)menu {
	return [self actionsMenu];
}
#define kQSObjectFullMenu @"QSObjectFullMenu"
#define kQSObjectChildrenMenu @"QSObjectChildrenMenu"
#define kQSObjectActionsMenu @"QSObjectActionsMenu"

- (NSMenu *)actionsMenu {
	//QSObject *object = self;
	NSMenu *menu = [[NSMenu alloc] initWithTitle:kQSObjectActionsMenu];
	[menu setDelegate:self];
	return menu;
}

- (NSMenu *)fullMenu {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:kQSObjectFullMenu];
	[menu setDelegate:self];

	return menu;
}

- (NSMenu *)childrenMenu {
	if (![self hasChildren]) return nil;
	NSMenu *menu = [[NSMenu alloc] initWithTitle:kQSObjectChildrenMenu];
	[menu setDelegate:self];

	return menu;
}

- (BOOL)addChildrenInArray:(NSArray *)children count:(NSUInteger)count toMenu:(NSMenu *)menu indent:(NSInteger)indent {
	NSUInteger index;
	count = MIN(count, [children count]);
	for (index = 0; index<count; index++) {
		QSObject *child = [[self children] objectAtIndex:index];
		NSMenuItem *item = [child menuItemWithChildren:YES];
		[item setIndentationLevel:indent];
		[menu addItem:item];
	}
	return YES;
}

- (BOOL)addActionsInArray:(NSArray *)actions count:(NSUInteger)count toMenu:(NSMenu *)menu indent:(NSInteger)indent {
	count = MIN(count, [actions count]);
	NSUInteger i;
	NSMenuItem *item;

	for (i = 0; i<count; i++) {
		QSAction *action = [actions objectAtIndex:i];
		if (action) {
			NSArray *componentArray = [[action name] componentsSeparatedByString:@"/"];
			[action loadIcon];
			NSImage *iconCopy = [[action icon] copy];
			[iconCopy setSize:QSSize16];

			id command = [QSCommand commandWithDirectObject:self actionObject:action indirectObject:nil];
			if ([componentArray count] >1) {
				NSMenuItem *groupMenu = [menu itemWithTitle:[componentArray objectAtIndex:0]];
				if (!groupMenu) {
					groupMenu = [[NSMenuItem alloc] initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""];
					if (iconCopy) [groupMenu setImage:iconCopy];
					[groupMenu setSubmenu: [[NSMenu alloc] initWithTitle:[componentArray objectAtIndex:0]]];
					[menu addItem:groupMenu];
				}
				item = (NSMenuItem *)[[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1] action:@selector(executeFromMenu:) keyEquivalent:@""];
			} else {
				item = (NSMenuItem *)[menu addItemWithTitle:[action name] action:@selector(executeFromMenu:) keyEquivalent:@""];
				if ([action argumentCount] >1) {
					NSMenu *sub = [[NSMenu alloc] initWithTitle:[action name]];
					[sub setDelegate:command];
					[item setSubmenu:sub];
				}
			}
			[item setTarget:command];
			[item setRepresentedObject:command];
			if (iconCopy) [item setImage:iconCopy];
			[item setIndentationLevel:indent];
		}
	}
	return YES;
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
  BOOL actionsItem = NO;
  BOOL actionsList = NO;
  BOOL contentsList = NO;
  
  if ([[menu title] isEqualToString:kQSObjectFullMenu]) {
    if ([self hasChildren] && ([[self children] count])) {
      actionsItem = YES;
      contentsList = YES;
    }
    else actionsList = YES;
  }
  if ([[menu title] isEqualToString:kQSObjectChildrenMenu]) {
    contentsList = ([self hasChildren] && ([[self children] count]));
  }
  if ([[menu title] isEqualToString:kQSObjectActionsMenu]) {
    actionsList = YES;
  }
  
  
  if (actionsItem || actionsList) {
    NSMutableArray *actions = (NSMutableArray *)[QSExec validActionsForDirectObject:(QSObject *)self indirectObject:nil];
    NSArray *rankSortedActions = [actions sortedArrayUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"rank" ascending:YES selector:@selector(compare:)]];
    [self addActionsInArray:rankSortedActions count:2 toMenu:menu indent:0];
    
    if (actionsItem) {
      NSMenuItem *item = (NSMenuItem *)[menu addItemWithTitle:@"Actions" action:(SEL)0 keyEquivalent:@""];
      [item setImage:[[QSResourceManager imageNamed:@"defaultAction"] duplicateOfSize:QSSize16]];
      [item setSubmenu:[self actionsMenu]];
      [menu addItem:[NSMenuItem separatorItem]];
    }
    if (actionsList) {
      [menu addItem:[NSMenuItem separatorItem]];
      NSArray *nameSortedActions = [actions sortedArrayUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
      [self addActionsInArray:nameSortedActions count:[nameSortedActions count] toMenu:menu indent:0];
    }
  }
  if (contentsList) {
    [self addChildrenInArray:[self children] count:[[self children] count] toMenu:menu indent:0];
  }
  [menu setDelegate:self];
}
//- (int) numberOfItemsInMenu:(NSMenu*)menu {
//	//NSLog(@"MENU %@ count", [menu title]);
//
//	if ([[menu title] isEqualToString:kQSObjectChildrenMenu]) {
//		return MIN(20, [[self children] count]) +2;
//	}
//	return 0;
//}
//- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel {
//	//NSLog(@"MENU %@ index %d", [menu title] , index);
//	if ([[menu title] isEqualToString:kQSObjectChildrenMenu]) {
//		QSBasicObject *child = [[self children] objectAtIndex:index];
//		item = [child configureMenuItem:item];
//		//[child setSubmenu:[child fullMenu]];
//		return YES;
//	}
//	return NO;
//}
//
//- (BOOL)menuHasKeyEquivalent:(NSMenu*)menu forEvent:(NSEvent*)event target:(id*)target action:(SEL*)action {return NO;}
//

- (NSMenu *)rankMenuWithTarget:(NSView *)target {
	return nil;
}

@end
