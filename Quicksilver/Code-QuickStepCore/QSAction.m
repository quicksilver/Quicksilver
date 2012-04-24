#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSObject.h"
#import "QSTypes.h"
#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "NDAppleScriptObject.h"
#import "NSBundle_BLTRExtensions.h"
#import "QSExecutor.h"

//static NSDictionary *actionPrecedence;

@implementation QSAction
#if 0
static BOOL gModifiersAreIgnored;
+ (void)setModifiersAreIgnored:(BOOL)flag { gModifiersAreIgnored = flag;  }
+ (BOOL)modifiersAreIgnored {
#ifdef DEBUG
	if (VERBOSE && gModifiersAreIgnored)
		NSLog(@"ignoring modifiers %d", gModifiersAreIgnored);
#endif
	return gModifiersAreIgnored;
}
#endif

+ (id)actionWithDictionary:(NSDictionary *)dict {
    return [[[self alloc] initWithDictionary:dict] autorelease];
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
	return [[[QSExec actionForIdentifier:newIdentifier] retain] autorelease];
}

+ (id) actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
    id obj = [self actionWithIdentifier:newIdentifier];

    // !!! Andre Berg 20091111: Incorporating patch Issue126-Fix.diff of pkohut
    if (!obj) {
        obj = [[[self alloc] initWithIdentifier:newIdentifier bundle:newBundle] autorelease];
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
    
    [rep release];
    return obj;
}

- (id)initWithDictionary:(NSDictionary *)dict {
	if (!dict) {
		[self release];
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
        dict = [[NSMutableDictionary alloc] init];
        [self setObject:dict forType:QSActionType];
    }
    return dict;
}

- (id)objectForKey:(NSString*)key {
    return [[self actionDict] objectForKey:key];
}

- (float)precedence {
	NSNumber *num = [[self actionDict] objectForKey:kActionPrecedence];
	return num ? [num floatValue] : 0.0;
}

- (int)rank { return rank;  }
- (void)_setRank:(int)newRank {
	[self willChangeValueForKey:@"rank"];
	rank = newRank;
	[self didChangeValueForKey:@"rank"];
}
- (void)setRank:(int)newRank {
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

- (int)userRank { return rank+1;  }
- (void)setUserRank:(int)newRank {
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

- (int)argumentCount {
    id obj = [[self actionDict] objectForKey:kActionArgumentCount];
    if (obj)
        return [obj intValue];
    
    id provider = [self provider];
    if ([provider respondsToSelector:@selector(argumentCountForAction:)])
        return [provider argumentCountForAction:[self identifier]];
    
    return [[QSActionProvider provider] argumentCountForAction:[self identifier]];
}

- (void)setArgumentCount:(int)newArgumentCount {
    [[self actionDict] setObject:[NSNumber numberWithInt:newArgumentCount]
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
 	[[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionIndirectOptional];
}

- (BOOL)displaysResult { 
   return [[[self actionDict] objectForKey:kActionDisplaysResult] boolValue]; 
}
- (void)setDisplaysResult:(BOOL)flag { [[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionDisplaysResult]; }

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
    return [[self actionDict] objectForKey:kActionDirectTypes];
}

- (void)setDirectTypes:(NSArray*)types {
    [[self actionDict] setObject:types forKey:kActionDirectTypes];
}

- (NSArray*)indirectTypes {
    return [[self actionDict] objectForKey:kActionIndirectTypes];
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
	item = (NSMenuItem *)[menu addItemWithTitle:[NSString stringWithFormat:@"Rank: %d", [self rank] +1] action:NULL keyEquivalent:@""];
	[item setTarget:nil];
	[menu addItem:[NSMenuItem separatorItem]];
	item = (NSMenuItem *)[menu addItemWithTitle:@"Make Default" action:@selector(promoteAction:) keyEquivalent:@""];
	[item setTarget:target];
#if 0
	item = (NSMenuItem *)[menu addItemWithTitle:@"Edit Actions..." action:@selector(editActions:) keyEquivalent:@""];
	[item setTarget:self];
#endif
	return [menu autorelease];
}

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [self actionDict];
	NSString *class = [dict objectForKey:kActionClass];
	QSActionProvider *provider = [dict objectForKey:kActionProvider];
	if (class || provider) {
		if (!provider) {
			provider = [QSReg getClassInstance:class];
		}
		if ([[dObject primaryType] isEqualToString:QSProxyType]) {
			dObject = (QSObject *)[dObject resolvedObject];
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
        
		if (!selector)
			return [provider performAction:(QSAction *)self directObject:dObject indirectObject:iObject];
		else if ([self argumentCount] == 2)
			return [provider performSelector:selector withObject:(reverseArgs?iObject:dObject) withObject:(reverseArgs?dObject:iObject)];
		else if ([self argumentCount] == 1)
			return [provider performSelector:selector withObject:dObject];
		else
			return [provider performSelector:selector];
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
		format = [[self actionDict] objectForKey:@"commandFormat"];
    
	// Check the main bundle
	if (!format)
		format = [[NSBundle mainBundle] safeLocalizedStringForKey:identi value:nil table:@"QSAction.commandFormat"];
    
	//Fallback format
	if (!format)
		format = [NSString stringWithFormat:@"%%@ (%@) %@", [self name], ([self argumentCount] > 1 ? @" %@" : @"")];
    
    return format;
}

- (float)score {
    return 0.0;
}

- (int)order {
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
	else
		return [[(QSAction *)object actionDict] objectForKey:@"description"];
}

- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[NSImage imageNamed:@"defaultAction"]]; }

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped { return NO; }

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *icon = [QSRez imageWithExactName:[object identifier]];
	NSString *name = [[object objectForType:QSActionType] objectForKey:kActionIcon];
	if (!icon && name)
		icon = [QSResourceManager imageNamed:name inBundle:[object bundle]];
    if(!icon) {
        if ([object respondsToSelector:@selector(provider)]) {
        NSObject <QSActionProvider> *provider = [(QSAction*)object provider];
        if(provider && [provider respondsToSelector:@selector(iconForAction:)])
            icon = [provider iconForAction:[object identifier]];
        }
    }
	if (icon) {
		[object setIcon:icon];
		return YES;
	} else
		return NO;
}

@end