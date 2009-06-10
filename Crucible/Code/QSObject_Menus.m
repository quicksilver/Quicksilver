

#import "QSObject_Menus.h"

#import "QSLibrarian.h"
#import "QSAction.h"

#import "QSCommand.h"
#import "QSExecutor.h"
#import "NSSortDescriptor+BLTRExtensions.h"

#import "NSImage_BLTRExtensions.h"

@implementation QSBasicObject (Menus)
//
//- (NSMenu *)menu{
//  QSLog(@"Menu for: %@",self);
//    NSMenu *menu=[[[NSMenu alloc]initWithTitle:@"ContextMenu"]autorelease];
//    
//    NSArray *actions=[[QSLibrarian sharedInstance]validActionsForDirectObject:self indirectObject:nil];
//    
//    // actions = [actions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//    
//    NSMenuItem *item;
//    int i;
//    for (i=0;i<[actions count];i++){
//        QSAction *action=[actions objectAtIndex:i];
//        if (action){
//            NSArray *componentArray=[[action name]componentsSeparatedByString:@"/"];
//            
//            NSImage *menuIcon=[[[action icon]copy]autorelease];
//            [menuIcon setSize:NSMakeSize(16,16)];
//            
//            if ([componentArray count]>1){
//                NSMenuItem *groupMenu=[menu itemWithTitle:[componentArray objectAtIndex:0]];
//                if (!groupMenu){
//                    groupMenu=[[[NSMenuItem alloc]initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""]autorelease];
//                    if (menuIcon)[groupMenu setImage:menuIcon];
//                    [groupMenu setSubmenu: [[[NSMenu alloc]initWithTitle:[componentArray objectAtIndex:0]]autorelease]];    
//                    [menu addItem:groupMenu];
//                }       
//                item=(NSMenuItem *)[[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1] action:@selector(performMenuAction:) keyEquivalent:@""];
//            }
//            else 
//                item=(NSMenuItem *)[menu addItemWithTitle:[action name] action:@selector(performMenuAction:) keyEquivalent:@""];
//            
//            [item setTarget:self];
//            [item setRepresentedObject:action];
//            if (menuIcon)[item setImage:menuIcon];
//            
//        }
//    }
//    
//
//    return menu;
//    
//}
- (void)performActionFromMenuItem:(id)sender {
	QSLog(@"sender %@",sender);
	NSArray *actions = [QSExec rankedActionsForDirectObject:self indirectObject:nil];
	
	QSCommand *command = [QSCommand commandWithDirectObject:self
                                               actionObject:[actions objectAtIndex:0]
                                             indirectObject:nil];
	[command execute];
}

- (NSMenuItem *)menuItem {
	return [self menuItemWithChildren:NO];
}

- (BOOL)applyIconToMenuItem:(NSMenuItem *)item {
	NSImage *iconCopy = [[[self icon] copy] autorelease];
	[iconCopy setSize:NSMakeSize(16,16)];
	[iconCopy setFlipped:NO];
	[item setImage:iconCopy];	
	return YES;
}

- (BOOL)configureMenuItem:(NSMenuItem *)item includeChildren:(BOOL)includeChildren {
	NSString *title = [self name];
	if (!title)
        title = @"";
	[item setTitle:title];
	[self applyIconToMenuItem:item];
	[item setRepresentedObject:self];
	
	if (0) {
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12], NSFontAttributeName, nil];
		NSAttributedString *attrTitle = [[[NSAttributedString alloc] initWithString:[self name] attributes:attrs] autorelease];
		[item setAttributedTitle:attrTitle];
	}
	if (includeChildren) {
		NSMenu *submenu = [self fullMenu];
		NSTimer *timer = [NSTimer timerWithTimeInterval:0.0
                                                 target:self
                                               selector:@selector(loadIconAndUpdateMenuItem:)
                                               userInfo:item
                                                repeats:NO];
		
		
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
		if (submenu) {
			[item setSubmenu:submenu];
		} else {
			[item setTarget:self];
			[item setAction:@selector(performActionFromMenuItem:)];
		}
	}
	return (item != nil);
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	return YES;
}

- (void)loadIconAndUpdateMenuItem:(NSTimer *)timer {
	//QSLog(@"loadicon %@",self);
	NSMenuItem *item = [timer userInfo];
	[self loadIcon];
	[self applyIconToMenuItem:item];
}

- (NSMenuItem *)menuItemWithChildren:(BOOL)includeChildren {
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:[self name] action:nil keyEquivalent:@""] autorelease];
	[self configureMenuItem:item includeChildren:includeChildren];
	return item;
}

- (NSMenu *)menu{
	return [self actionsMenu];
}

#define kQSObjectFullMenu @"QSObjectFullMenu"
#define kQSObjectChildrenMenu @"QSObjectChildrenMenu"
#define kQSObjectActionsMenu @"QSObjectActionsMenu"

- (NSMenu *)actionsMenu {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:kQSObjectActionsMenu] autorelease];
    [menu setDelegate:self];
	return menu;
}

- (NSMenu *)fullMenu {
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:kQSObjectFullMenu] autorelease];
	[menu setDelegate:self];
	return menu;
}


- (NSMenu *)childrenMenu {
	if (![self hasChildren])
        return nil;
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:kQSObjectChildrenMenu] autorelease];
	[menu setDelegate:self];	
	return menu;
}

- (BOOL)addChildrenInArray:(NSArray *)children count:(int)count toMenu:(NSMenu *)menu indent:(int)indent {
	count = MIN(count, [children count]);
	for (QSBasicObject *child in [self children]) {
		NSMenuItem *item = [child menuItemWithChildren:YES];
		[item setIndentationLevel:indent];
		[menu addItem:item];
	}
	return YES;
}

- (BOOL)addActionsInArray:(NSArray *)actions count:(int)count toMenu:(NSMenu *)menu indent:(int)indent {
	count = MIN(count, [actions count]);
	int i;
	NSMenuItem *item;
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSFont menuBarFontOfSize:0],NSFontAttributeName,
                           [NSNumber numberWithFloat:0.25],NSObliquenessAttributeName,
                           nil];
	
	for (QSAction *action in actions) {
		if (action) {
			NSArray *componentArray = [[action name] componentsSeparatedByString:@"/"];
			[action loadIcon];
			NSImage *iconCopy = [[[action icon] copy] autorelease];
			[iconCopy setSize:NSMakeSize(16,16)];
			[iconCopy setFlipped:NO];
			
			id command = [QSCommand commandWithDirectObject:self actionObject:action indirectObject:nil];
			if ([componentArray count] > 1) {
				NSMenuItem *groupMenu = [menu itemWithTitle:[componentArray objectAtIndex:0]];
				if (!groupMenu) {
					groupMenu = [[[NSMenuItem alloc] initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""] autorelease];
					if (iconCopy)
                        [groupMenu setImage:iconCopy];
					[groupMenu setSubmenu:[[[NSMenu alloc] initWithTitle:[componentArray objectAtIndex:0]] autorelease]];
					[menu addItem:groupMenu];
				}       
				item = [[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1]
                                                      action:@selector(executeFromMenu:)
                                               keyEquivalent:@""];
			} else {
				item = [menu addItemWithTitle:[action name] action:@selector(executeFromMenu:) keyEquivalent:@""];
				if ([action argumentCount] > 1) {
					NSMenu *sub = [[[NSMenu alloc] initWithTitle:[action name]] autorelease];
					[sub setDelegate:command];
					[command retain]; // so it doesn't get released too early when menu deconstructed
					[item setSubmenu:sub];
				}
			}
			[item setAttributedTitle:[[[NSAttributedString alloc] initWithString:[item title] attributes:attrs] autorelease]];
			
			[item setTarget:command];
			[item setRepresentedObject:command];
			if (iconCopy)
                [item setImage:iconCopy];
			[item setIndentationLevel:indent];
		}
	}
	return YES;
}


- (void)menuNeedsUpdate:(NSMenu *)menu{ 	
	if ([[menu title] isEqualToString:kQSObjectChildrenMenu]) {
		NSArray *children = [self children];
		[self addChildrenInArray:children count:[children count] toMenu:menu indent:0];
	} else if ([[menu title] isEqualToString:kQSObjectFullMenu]) {
		[menu addItem:[self menuItem]];
		[menu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *item;
		
		NSArray *actions = [QSExec validActionsForDirectObject:self indirectObject:nil];
		[actions sortedArrayUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"rank" ascending:YES selector:@selector(compare:)]];
		
		item = [menu addItemWithTitle:[NSString stringWithFormat:@"Actions (...All%C)",0x25B8] action:(SEL)0 keyEquivalent:@""];
		[item setImage:[[NSImage imageNamed:@"defaultAction"] duplicateOfSize:QSSize16]];
		[item setSubmenu:[self actionsMenu]];
		[self addActionsInArray:actions count:3 toMenu:menu indent:1];
		
		NSArray *children = nil;
		if ([self hasChildren] && (children = [self children]) && [children count]) {
		//	item=(NSMenuItem *)[menu addItemWithTitle:@"Actions" action:(SEL)0 keyEquivalent:@""];
			
		//	[item setImage:[[NSImage imageNamed:@"defaultAction"]duplicateOfSize:QSSize16]];
		//	[item setSubmenu:[self actionsMenu]];

			[menu addItem:[NSMenuItem separatorItem]];
			item = [menu addItemWithTitle:@"Contents" action:(SEL)0 keyEquivalent:@""];
			
			[item setImage:[[NSImage imageNamed:@"Dot"] duplicateOfSize:QSSize16]];
			[self addChildrenInArray:children count:[children count] toMenu:menu indent:1];
			
		} else {
			//item=(NSMenuItem *)[menu addItemWithTitle:@"Actions" action:(SEL)0 keyEquivalent:@""];
		}
		//[menu setDelegate:self];	
		
		
	} else if ([[menu title] isEqualToString:kQSObjectActionsMenu]) {
	    NSArray *actions = [QSExec validActionsForDirectObject:self indirectObject:nil];
		
		[actions sortedArrayUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];

		if ([actions count]) {
			[self addActionsInArray:actions count:[actions count] toMenu:menu indent:0];
		}	
	}
	
}
//- (int)numberOfItemsInMenu:(NSMenu*)menu{
//	//QSLog(@"MENU %@ count",[menu title]);
//
//	if ([[menu title]isEqualToString:kQSObjectChildrenMenu]){
//		return MIN(20,[[self children]count])+2;
//	}	
//	return 0;
//}
//- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel{
//	//QSLog(@"MENU %@ index %d",[menu title],index);
//	if ([[menu title]isEqualToString:kQSObjectChildrenMenu]){
//		QSBasicObject *child=[[self children] objectAtIndex:index];
//		item=[child configureMenuItem:item];
//		//[child setSubmenu:[child fullMenu]];
//		return YES;
//	}
//	return NO;
//}
//
//- (BOOL)menuHasKeyEquivalent:(NSMenu*)menu forEvent:(NSEvent*)event target:(id*)target action:(SEL*)action{return NO;}
//

- (NSMenu *)rankMenuWithTarget:(NSView *)target {
	return nil;
}

@end
