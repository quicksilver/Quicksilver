#import "QSActionProvider.h"
#import "QSLibrarian.h"
#import "NSBundle_BLTRExtensions.h"

@implementation QSActionProvider
+ (void)initialize {
	if (![NSImage imageNamed:QSDirectObjectIconProxy]){
		NSImage *theImg = (NSImage *)[[NSImage imageNamed:@"defaultAction"] copy];
		[theImg setName:QSDirectObjectIconProxy];
		[theImg release];
	}
}
+ (id)provider { return [[[[self class] alloc] init] autorelease];  }
- (NSArray *)types { return nil;  }
- (NSArray *)fileTypes { return nil;}
- (QSAction *)initializeAction:(QSAction *)action { return action;  }
- (int)argumentCountForAction:(NSString *)action {
    return [[[[QSAction actionWithIdentifier:action] objectForKey:kActionSelector] componentsSeparatedByString:@":"] count] - 1;
}

- (NSString *)titleForAction:(NSString *)action {
	NSString *title = [[NSBundle bundleForClass:[self class]] safeLocalizedStringForKey:action value:action table:@"QSAction.name"];
	return title ? title : action;
}
- (NSImage *)iconForAction:(NSString *)action { return [NSImage imageNamed:@"Arrow"];  }
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject { return nil;  }
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject { return nil;  }
- (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject { return nil;  }
- (NSArray *)actions { return nil;  }
@end
