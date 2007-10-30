

#import "QSActionProvider.h"
#import "QSLibrarian.h"

#import "NSBundle_BLTRExtensions.h"
// URL Actions


@implementation QSActionProvider
+ (void)initialize{
	if (![NSImage imageNamed:QSDirectObjectIconProxy]) 
		[(NSImage *)[[NSImage imageNamed:@"defaultAction"]copy]setName:QSDirectObjectIconProxy];
}


+ (id) provider{return [[[[self class] alloc]init]autorelease];}
- (NSArray *) types{return nil;}
- (NSArray *) fileTypes{return nil;}
- (QSAction *) initializeAction:(QSAction *)action{return action;}
- (int)argumentCountForAction:(NSString *)action{return 1;}

- (NSString *) titleForAction:(NSString *)action{
    NSString *title=[[NSBundle bundleForClass:[self class]]safeLocalizedStringForKey:action value:action table:@"QSAction.name"];
    if (!title) title=action;
    return title;
}
- (NSImage *) iconForAction:(NSString *)action{return [NSImage imageNamed:@"Arrow"];}
- (NSArray *) validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{return nil;}
- (NSArray *) validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{return nil;}
- (QSObject *) performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject{return nil;}

//- (void) loadActions{[self setActions:[self actions]];}




- (NSArray *) actions{
	return nil;
}
@end