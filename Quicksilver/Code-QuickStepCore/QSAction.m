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
	if (VERBOSE && gModifiersAreIgnored)
		NSLog(@"ignoring modifiers %d", gModifiersAreIgnored);
	return gModifiersAreIgnored;
}
#endif

/*+ (void)initialize {
	actionPrecedence = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ActionsPrecedence" ofType:@"plist"]] retain];
}*/

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

+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
    id obj = [self actionWithIdentifier:newIdentifier];
    [obj setBundle:newBundle];
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

- (NSMutableDictionary*)actionDict {
    return [self objectForType:QSActionType];
}

- (float)precedence {
	NSNumber *num = [[self actionDict] objectForKey:kActionPrecedence];
#if 0
	if (!num) num = [[self actionDict] objectForKey:@"rankModification"];
#warning remove
#endif
	return num?[num floatValue] :0.0;
}

#if 0
- (float) rankModification {
	return [self precedence];
}
#endif
- (int)rank { return rank;  }
//- (int) _rank { return rank;  }
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

- (BOOL)menuEnabled {
	return menuEnabled;
}
- (void)_setMenuEnabled:(BOOL)flag { menuEnabled = flag;  }
- (void)setMenuEnabled:(BOOL)flag {
	menuEnabled = flag;
	[QSExec setAction:self isMenuEnabled:flag];
}

- (BOOL)enabled { return enabled;  }
- (void)_setEnabled:(BOOL)flag { enabled = flag;  }
- (void)setEnabled:(BOOL)flag {
	enabled = flag;
	[QSExec setAction:self isEnabled:flag];
}

- (BOOL)defaultEnabled { 
    NSNumber *n = [[self actionDict] objectForKey:kActionEnabled];
    if(n)
        return [n boolValue];
    return YES;
}

//- (SEL) action { return [self actionDict];  }
- (void)setAction:(SEL)newAction {
	if (newAction)
		[[self actionDict] setObject:NSStringFromSelector(newAction) forKey:kActionSelector];
	else
		[[self actionDict] removeObjectForKey:kActionSelector];
}

- (void)setArgumentCount:(int)newArgumentCount {
	[[self actionDict] setObject:[NSNumber numberWithInt:newArgumentCount] forKey:kActionArgumentCount];
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

- (BOOL)displaysResult { return [[[self actionDict] objectForKey:kActionDisplaysResult] boolValue];  }
- (void)setDisplaysResult:(BOOL)flag { [[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionDisplaysResult];  }

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

- (BOOL)canThread { return ![[[self actionDict] objectForKey:kActionRunsInMainThread] boolValue];  }

- (QSAction *)alternate { return [QSExec actionForIdentifier:[[self actionDict] objectForKey:kActionAlternate]];  }

- (int) order {return [self rank];}
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
	if (fALPHA) {
		item = (NSMenuItem *)[menu addItemWithTitle:@"Edit Actions..." action:@selector(editActions:) keyEquivalent:@""];
		[item setTarget:self];
	}
#endif
	return [menu autorelease];
}

- (int)argumentCount { return [[[[self actionDict] objectForKey:kActionSelector] componentsSeparatedByString:@":"] count] - 1;  }

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [self actionDict];
	NSString *class = [dict objectForKey:kActionClass];
	QSActionProvider *provider = [dict objectForKey:kActionProvider];
	if (class || provider) {
		if (!provider)
			provider = [QSReg getClassInstance:class];
		if ([[dict objectForKey:kActionSplitPluralArguments] boolValue] && [dObject count] > 1) {
			NSArray *objects = [dObject splitObjects];
			NSEnumerator *e = [objects objectEnumerator];
			id object;
			while (object = [e nextObject]) {
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

@end

@implementation QSActionHandler
- (id)objectForRepresentation:(NSDictionary*)dictionary {
    QSAction *obj = [[QSAction alloc] init];
    [[obj actionDict] setDictionary:dictionary];
    return [obj autorelease];
}

- (NSDictionary*)representationForObject:(QSBasicObject*)object {
    return [(QSAction*)object actionDict];
}

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

- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[NSImage imageNamed:@"defaultAction"]];  }

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped { return NO;  }

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *icon = [QSRez imageWithExactName:[object identifier]];
	NSString *name = [[object objectForType:QSActionType] objectForKey:kActionIcon];
	if (!icon && name)
		icon = [QSResourceManager imageNamed:name inBundle:[object bundle]];
    if(!icon) {
        NSObject <QSActionProvider> *provider = [(QSAction*)object provider];
        if(provider && [provider respondsToSelector:@selector(iconForAction:)])
            icon = [provider iconForAction:[object identifier]];
    }
	if (icon) {
		[object setIcon:icon];
		return YES;
	} else
		return NO;
}

@end