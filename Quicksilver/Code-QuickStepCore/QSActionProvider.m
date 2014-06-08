#import "QSActionProvider.h"
#import "QSLibrarian.h"
#import "NSBundle_BLTRExtensions.h"

@implementation QSActionProvider
+ (void)initialize {
	if (![QSResourceManager imageNamed:QSDirectObjectIconProxy]){
		NSImage *theImg = [[QSResourceManager imageNamed:@"defaultAction"] copy];
		[theImg setName:QSDirectObjectIconProxy];
	}
}
+ (id)provider { return [[[self class] alloc] init];  }
- (NSArray *)types { return nil;  }
- (NSArray *)fileTypes { return nil;}
- (QSAction *)initializeAction:(QSAction *)action { return action;  }
- (NSInteger)argumentCountForAction:(NSString *)action {
    NSString *selectorName = [[QSAction actionWithIdentifier:action] objectForKey:kActionSelector];
    if (selectorName) {
        return [[selectorName componentsSeparatedByString:@":"] count] - 1;
    }
    // -[QSAction actionWithIdentifier:] can't look up actions that only exist as part of a command in the first pane
    return 0;
}

- (NSString *)titleForAction:(NSString *)action {
	NSString *title = [[NSBundle bundleForClass:[self class]] safeLocalizedStringForKey:action value:action table:@"QSAction.name"];
	return title ? title : action;
}
- (NSImage *)iconForAction:(NSString *)action { return [QSResourceManager imageNamed:@"Arrow"];  }
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject { return nil;  }
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject { return nil;  }
- (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject { return nil;  }
- (NSArray *)actions { return nil;  }
@end
