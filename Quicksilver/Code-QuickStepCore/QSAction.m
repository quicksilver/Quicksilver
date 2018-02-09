#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSObject.h"
#import "QSTypes.h"
#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "NSBundle_BLTRExtensions.h"
#import "QSExecutor.h"
#import <objc/objc-runtime.h>

//static NSDictionary *actionPrecedence;

@implementation QSAction
#if 0
static BOOL gModifiersAreIgnored;
+ (void)setModifiersAreIgnored:(BOOL)flag { gModifiersAreIgnored = flag;  }
+ (BOOL)modifiersAreIgnored {
#ifdef DEBUG
	if (VERBOSE && gModifiersAreIgnored)
#warning 64BIT: Check formatting arguments
		NSLog(@"ignoring modifiers %d", gModifiersAreIgnored);
#endif
	return gModifiersAreIgnored;
}
#endif

+ (id)actionWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithDictionary:dict];
}

+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident {
    id obj = [self actionWithIdentifier:ident];
    if (obj)
        return obj;
    
    obj = [self actionWithDictionary:dict];
    [obj setIdentifier:ident];
    return obj;
}

+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle {
    id obj = [self actionWithDictionary:dict identifier:ident];
    [obj setBundle:bundle];
	return obj;
}

+ (id)actionWithIdentifier:(NSString *)newIdentifier {
	return [QSExec actionForIdentifier:newIdentifier];
}

+ (id) actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
    id obj = [self actionWithIdentifier:newIdentifier];

    // !!! Andre Berg 20091111: Incorporating patch Issue126-Fix.diff of pkohut
    if (!obj) {
        obj = [[self alloc] initWithIdentifier:newIdentifier bundle:newBundle];
    } else {
        [obj setBundle:newBundle];
    }
    // patch end
    return obj;
}

- (id)init {
	if (self = [super init]) {
		rank = 999999;
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)aBundle {
    NSMutableDictionary *rep = [dict mutableCopy];
    [rep setObject:ident forKey:kActionIdentifier];
    id obj = [self initWithDictionary:rep];
    [obj setBundle:aBundle];
    
    return obj;
}

- (id)initWithDictionary:(NSDictionary *)dict {
	if (!dict) {
		return nil;
	}
	if (self = [self init]) {
		[self setObject:dict forType:QSActionType];
		[self setPrimaryType:QSActionType];
	}
	return self;
}

// !!! Andre Berg 20091111: Incorporating patch Issue126-Fix.diff of pkohut 
- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
   NSString * normalizedIdentifier = newIdentifier == 0 ? @"" : newIdentifier;
   id obj = [self initWithDictionary:[NSDictionary dictionary] identifier:normalizedIdentifier bundle:newBundle];
   if(obj) {
      [self setIdentifier:newIdentifier];
      [self setName:[newBundle safeLocalizedStringForKey:newIdentifier value:newIdentifier table:@"QSAction.name"]];
      [self setDisplaysResult:YES];
      [self setArgumentCount:1];
   }
   return obj;
}
// end patch

- (NSMutableDictionary*)actionDict {
    NSMutableDictionary *dict = [self objectForType:QSActionType];
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        [self setObject:dict forType:QSActionType];
    }
    return dict;
}

- (id)objectForKey:(NSString*)key {
    return [[self actionDict] objectForKey:key];
}

- (CGFloat)precedence {
	NSNumber *num = [[self actionDict] objectForKey:kActionPrecedence];
	return num ? [num doubleValue] : 0.0;
}

- (void)setPrecedence:(CGFloat)precedence
{
	NSNumber *num = [NSNumber numberWithFloat:precedence];
	[[self actionDict] setObject:num forKey:kActionPrecedence];
}

- (NSInteger)rank { return rank;  }
- (void)_setRank:(NSInteger)newRank {
	[self willChangeValueForKey:@"rank"];
	rank = newRank;
	[self didChangeValueForKey:@"rank"];
}
- (void)setRank:(NSInteger)newRank {
	rank = newRank;
	[QSExec updateRanks];
}

- (NSString*)name {
    NSString *n = [super name];
    NSString *ident = [self identifier];
    if (!n) {
        n = [[self bundle] safeLocalizedStringForKey:ident
                                               value:nil
                                               table:@"QSAction.name"];
        if (!n) n = [[self actionDict] objectForKey:kActionName];
        
        if (!n) {
            NSObject <QSActionProvider> *provider = [self provider];
            if(provider && [provider respondsToSelector:@selector(titleForAction:)])
                n = [[self provider] titleForAction:ident];
        }
		
#ifdef DEBUG
        if(!n)
            NSLog(@"Action %@ without provider.", ident);
#endif
		
        [self setName:n];
        
        if (!n) n = ident;
    }
    return n;
}

- (void)setDisplayName:(NSString *)dname {
	[self setLabel:dname];
	[QSExec noteNewName:dname forAction:self];
}

- (NSInteger)userRank { return rank+1;  }
- (void)setUserRank:(NSInteger)newRank {
	rank = newRank-1;
	[QSExec updateRanks];
}

- (BOOL)menuEnabled { return [QSExec actionIsMenuEnabled:self]; }
- (void)setMenuEnabled:(BOOL)flag {
	[QSExec setAction:self isMenuEnabled:flag];
}

- (BOOL)enabled { return [QSExec actionIsEnabled:self];  }
- (void)setEnabled:(BOOL)flag { [QSExec setAction:self isEnabled:flag]; }

- (BOOL)defaultEnabled { 
    NSNumber *n = [[self actionDict] objectForKey:kActionEnabled];
    if(n)
        return [n boolValue];
    return YES;
}

- (SEL)action { return NSSelectorFromString([[self actionDict] objectForKey:kActionSelector]); }

- (void)setAction:(SEL)newAction {
	if (newAction)
		[[self actionDict] setObject:NSStringFromSelector(newAction) forKey:kActionSelector];
	else
		[[self actionDict] removeObjectForKey:kActionSelector];
}

- (BOOL)setActionUisngBlock:(QSObject *(^)(id, QSObject *))actionBlock selectorName:(NSString *)selName
{
	if (![self provider]) {
		NSLog(@"define provider before setting a block as the action");
		return NO;
	}
	IMP actionFunction = imp_implementationWithBlock(actionBlock);
	SEL actionSelector = NSSelectorFromString(selName);
	BOOL actionDefined = class_addMethod([[self provider] class], actionSelector, actionFunction, "@@:@");
	if (actionDefined) {
		[self setAction:actionSelector];
	} else {
		NSLog(@"Unable to add action %@ to %@", selName, [self provider]);
	}
	return actionDefined;
}

- (BOOL)setActionWithIndirectUisngBlock:(QSObject *(^)(id, QSObject *, QSObject *))actionBlock  selectorName:(NSString *)selName
{
	if (![self provider]) {
		NSLog(@"define provider before setting a block as the action");
		return NO;
	}
	IMP actionFunction = imp_implementationWithBlock(actionBlock);
	SEL actionSelector = NSSelectorFromString(selName);
	BOOL actionDefined = class_addMethod([[self provider] class], actionSelector, actionFunction, "@@:@@");
	if (actionDefined) {
		[self setAction:actionSelector];
	} else {
		NSLog(@"Unable to add action %@ to %@", selName, [self provider]);
	}
	return actionDefined;
}

- (NSInteger)argumentCount {
    id obj = [[self actionDict] objectForKey:kActionArgumentCount];
    if (obj)
        return [obj integerValue];
    
    id provider = [self provider];
    if ([provider respondsToSelector:@selector(argumentCountForAction:)])
        return [provider argumentCountForAction:[self identifier]];
    
    return [[QSActionProvider provider] argumentCountForAction:[self identifier]];
}

- (void)setArgumentCount:(NSInteger)newArgumentCount {
    [[self actionDict] setObject:[NSNumber numberWithInteger:newArgumentCount]
                          forKey:kActionArgumentCount];
}

- (BOOL)reverse { return [[[self actionDict] objectForKey:kActionReverseArguments] boolValue]; }
- (void)setReverse:(BOOL)flag {
	[[self actionDict] setObject:[NSNumber numberWithBool:flag] forKey:kActionReverseArguments];
}

- (BOOL)indirectOptional {
    return [[[self actionDict] objectForKey:kActionIndirectOptional] boolValue];
}

- (void)setIndirectOptional:(BOOL)flag {
 	[[self actionDict] setObject:[NSNumber numberWithInteger:flag] forKey:kActionIndirectOptional];
}

- (BOOL)validatesObjects
{
	return [[[self actionDict] objectForKey:kActionValidatesObjects] boolValue];
}
- (void)setValidatesObjects:(BOOL)flag
{
	[[self actionDict] setObject:[NSNumber numberWithInteger:flag] forKey:kActionValidatesObjects];
}

- (BOOL)resolvesProxy {
    if ([[self actionDict] objectForKey:kActionResolvesProxy] == nil) {
        return YES;
    }
    return [[[self actionDict] objectForKey:kActionResolvesProxy] boolValue];
}

- (void)setResolvesProxy:(BOOL)flag {
 	[[self actionDict] setObject:[NSNumber numberWithInteger:flag] forKey:kActionResolvesProxy];
}

- (BOOL)displaysResult { 
   return [[[self actionDict] objectForKey:kActionDisplaysResult] boolValue]; 
}
- (void)setDisplaysResult:(BOOL)flag { [[self actionDict] setObject:[NSNumber numberWithInteger:flag] forKey:kActionDisplaysResult]; }

- (id)provider {
	NSDictionary *dict = [self actionDict];
	id provider = [dict objectForKey:kActionProvider];
	if (!provider)
		provider = [QSReg getClassInstance:[dict objectForKey:kActionClass]];
	return provider;
}

- (void)setProvider:(id)newProvider {
	NSMutableDictionary *dict = [self actionDict];
	[dict setObject:NSStringFromClass([newProvider class]) forKey:kActionClass];
	[dict setObject:newProvider forKey:kActionProvider];
}

- (NSArray*)directTypes {
    return [[[self actionDict] objectForKey:kActionDirectTypes] arrayByEnumeratingArrayUsingBlock:^NSString *(NSString *type) {
        return QSUTIForAnyTypeString(type);
    }];
}

- (void)setDirectTypes:(NSArray*)types {
    [[self actionDict] setObject:types forKey:kActionDirectTypes];
}

- (NSArray*)directFileTypes {
    return [[[self actionDict] objectForKey:kActionDirectFileTypes] arrayByEnumeratingArrayUsingBlock:^NSString *(NSString *type) {
        return QSUTIForAnyTypeString(type);
    }];
}

- (void)setDirectFileTypes:(NSArray *)types {
    [[self actionDict] setObject:types forKey:kActionDirectFileTypes];
}

- (NSArray*)indirectTypes {
    return [[[self actionDict] objectForKey:kActionIndirectTypes] arrayByEnumeratingArrayUsingBlock:^NSString *(NSString *type) {
        return QSUTIForAnyTypeString(type);
    }];
}

- (void)setIndirectTypes:(NSArray*)types {
    [[self actionDict] setObject:types forKey:kActionIndirectTypes];
}

- (NSArray*)resultTypes {
    return [[self actionDict] objectForKey:kActionResultType];
}

- (void)setResultTypes:(NSArray*)types {
    [[self actionDict] setObject:types forKey:kActionResultType];
}

- (BOOL)canThread { return ![[[self actionDict] objectForKey:kActionRunsInMainThread] boolValue];  }

- (QSAction *)alternate { return [QSExec actionForIdentifier:[[self actionDict] objectForKey:kActionAlternate]]; }

#if 0
- (IBAction)editActions:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[NSClassFromString(@"QSPreferencesController") performSelector:@selector(showPaneWithIdentifier:) withObject:@"QSActionsPrefPane"];
}
#endif

- (NSMenu *)rankMenuWithTarget:(NSView *)target {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"RankMenu"];

	NSMenuItem *item;
	item = (NSMenuItem *)[menu addItemWithTitle:[NSString stringWithFormat:@"Rank: %ld", (long)[self rank] +1] action:NULL keyEquivalent:@""];
	[item setTarget:nil];
	[menu addItem:[NSMenuItem separatorItem]];
	item = (NSMenuItem *)[menu addItemWithTitle:@"Make Default" action:@selector(promoteAction:) keyEquivalent:@""];
	[item setTarget:target];
#if 0
	item = (NSMenuItem *)[menu addItemWithTitle:@"Edit Actions..." action:@selector(editActions:) keyEquivalent:@""];
	[item setTarget:self];
#endif
	return menu;
}

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [self actionDict];
	NSString *class = [dict objectForKey:kActionClass];
	QSActionProvider *provider = [dict objectForKey:kActionProvider];
	if (class || provider) {
		if (!provider) {
			provider = [QSReg getClassInstance:class];
		}
        if ([self resolvesProxy]) {
            dObject = [dObject resolvedObject];
        }
		if ([[dict objectForKey:kActionSplitPluralArguments] boolValue] && [dObject count] > 1) {
			NSArray *objects = [dObject splitObjects];
			id object;
			for (object in objects) {
				[self performOnDirectObject:object indirectObject:iObject];
			}
			return nil;
		}
        
		BOOL reverseArgs = [[dict objectForKey:kActionReverseArguments] boolValue];
		SEL selector = NSSelectorFromString([dict objectForKey:kActionSelector]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		if (!selector)
			return [provider performAction:(QSAction *)self directObject:dObject indirectObject:iObject];
		else if ([self argumentCount] == 2)
			return [provider performSelector:selector withObject:(reverseArgs?iObject:dObject) withObject:(reverseArgs?dObject:iObject)];
		else if ([self argumentCount] == 1)
			return [provider performSelector:selector withObject:dObject];
		else
			return [provider performSelector:selector];
#pragma clang diagnostic pop
	}
	return nil;
}

- (NSString *)commandFormat {
	NSString *format;
	NSString *identi = [self identifier];
    
	//check class bundle
	format = [[self bundle] safeLocalizedStringForKey:identi value:nil table:@"QSAction.commandFormat"];
    
	//Check the action dictionary
	if (!format)
		format = [[self actionDict] objectForKey:kActionCommandFormat];
    
	// Check the main bundle
	if (!format)
		format = [[NSBundle mainBundle] safeLocalizedStringForKey:identi value:nil table:@"QSAction.commandFormat"];
    
	//Fallback format
	if (!format)
		format = [NSString stringWithFormat:@"%%@ (%@) %@", [self name], ([self argumentCount] > 1 ? @" %@" : @"")];
    
    return format;
}

- (void)setCommandFormat:(NSString *)commandFormat
{
	[[self actionDict] setObject:commandFormat forKey:kActionCommandFormat];
}

- (CGFloat)score {
    return 0.0;
}

- (NSInteger)order {
    return [self rank];
}

@end

@implementation QSActionHandler

- (NSString *)identifierForObject:(QSObject *)object {
	return [[object objectForType:QSActionType] objectForKey:kActionIdentifier];
}

- (NSString *)detailsOfObject:(QSObject *)object {
	NSString *newDetails = [[object bundle] safeLocalizedStringForKey:[object identifier] value:nil table:@"QSAction.description"];
	if (newDetails)
		return newDetails;
	else if ([object respondsToSelector:@selector(actionDict)])
		return [[(QSAction *)object actionDict] objectForKey:@"description"];
	else
		return @"";
}

- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[QSResourceManager imageNamed:@"defaultAction"]]; }

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped { return NO; }

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *icon = [[QSResourceManager sharedInstance] imageWithExactName:[object identifier]];
	NSString *name = [[object objectForType:QSActionType] objectForKey:kActionIcon];
	if (!icon && name)
		icon = [QSResourceManager imageNamed:name inBundle:[object bundle]];
    if(!icon && [object respondsToSelector:@selector(provider)]) {
        NSObject <QSActionProvider> *provider = [(QSAction*)object provider];
        if(provider && [provider respondsToSelector:@selector(iconForAction:)]) {
            icon = [provider iconForAction:[object identifier]];
        }
    }
	if (icon) {
		[object setIcon:icon];
        [object setRetainsIcon:YES];
		return YES;
	} else
		return NO;
}

@end
