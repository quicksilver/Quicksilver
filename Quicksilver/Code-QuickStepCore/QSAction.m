#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSObject.h"
#import "QSTypes.h"
#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "NDAppleScriptObject.h"
#import "NSBundle_BLTRExtensions.h"
#import "QSExecutor.h"

static NSDictionary *actionPrecedence;

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

+ (void)initialize {
	actionPrecedence = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ActionsPrecedence" ofType:@"plist"]] retain];
}
+ (id)actionWithIdentifier:(NSString *)newIdentifier {
	return [self actionWithIdentifier:newIdentifier bundle:[NSBundle mainBundle]];
}
+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
	return [[[QSAction alloc] initWithIdentifier:newIdentifier bundle:newBundle] autorelease];
}
- (NSString *)description { return [self name];  }
- (id)init {
	if (self = [super init]) {
		rank = 999999;
	}
	return self;
}

- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
	if (self = [super init]) {
		[self setObject:[NSMutableDictionary dictionary] forType:QSActionType];
		[self setIdentifier:newIdentifier];
		[self setName:[newBundle safeLocalizedStringForKey:newIdentifier value:newIdentifier table:@"QSAction.name"]];
		[self setPrimaryType:QSActionType];
		[self setDisplaysResult:YES];
		[self setBundle:newBundle];
	}
	return self;
}

- (float) precedence {
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
- (int) rank { return rank;  }
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
- (void)setDisplayName:(NSString *)dname {
	[self setLabel:dname];
	[QSExec noteNewName:dname forAction:self];
}

- (int) userRank { return rank+1;  }
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

- (NSNumber *)defaultEnabled { return [[self actionDict] objectForKey:kActionEnabled];  }

//- (SEL) action { return [self actionDict];  }
- (void)setAction:(SEL)newAction {
	if (newAction)
		[[self actionDict] setObject:NSStringFromSelector(newAction) forKey:kActionSelector];
	else
		[[self actionDict] removeObjectForKey:kActionSelector];
}
#if 0
- (void)setArgumentCount:(int)newArgumentCount {
	//	[[self actionDict] setObject:[NSNumber numberWithInt:newArgumentCount] forKey:kActionArgumentCount];
}
#endif

//- (BOOL)reverse { return [[[self actionDict] objectForKey:kActionReverseArguments] boolValue];  }
- (void)setReverse:(BOOL)flag {
	[[self actionDict] setObject:[NSNumber numberWithBool:flag] forKey:kActionReverseArguments];
}

//- (NSImage *)icon {if (icon) return icon; return [NSImage imageNamed:@"defaultAction"];}

//- (BOOL)indirectOptional { return indirectOptional;  }
- (void)setIndirectOptional:(BOOL)flag {
 	[[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionIndirectOptional];
}

//- (BOOL)displaysResult { return displaysResult;  }
- (void)setDisplaysResult:(BOOL)flag { [[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionDisplaysResult];  }

- (id)userData { return [self objectForMeta:kUserDataMeta];  }
- (void)setUserData:(id)someData {[self setObject:someData forMeta:kUserDataMeta];}

- (NSBundle *)bundle {
	NSBundle *bundle = [self objectForMeta:kSourceBundleMeta];
	if (!bundle)
		bundle = [QSReg bundleForClassName:[[self objectForType:QSActionType] objectForKey:kActionProvider]];
	return bundle;
}

- (id)provider {
	NSDictionary *dict = [self objectForType:QSActionType];
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

- (QSAction *)alternate { return [QSExec actionForIdentifier:[[self objectForType:QSActionType] objectForKey:kActionAlternate]];  }

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

@end

@implementation QSActionHandler

- (NSString *)identifierForObject:(id <QSObject>)object {
	return nil;
#if 0
	return [object objectForType:QSActionType];
#endif
}

- (NSString *)detailsOfObject:(QSObject *)object {
	NSString *newDetails = [[(QSAction *)object bundle] safeLocalizedStringForKey:[object identifier] value:@"missing" table:@"QSAction.description"];
	if ([newDetails isEqualToString:@"missing"])
		newDetails = nil;
	if (newDetails)
		return newDetails;
	else
		return [[(QSAction *)object actionDict] objectForKey:@"description"];
}

- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[NSImage imageNamed:@"defaultAction"]];  }

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped { return NO;  }

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *icon = [QSRez imageWithExactName:[object identifier]];
	NSString *name = [[(QSAction *)object actionDict] objectForKey:@"icon"];
	if (!icon && name)
		icon = [QSResourceManager imageNamed:name inBundle:[object bundle]];
	if (icon) {
		[object setIcon:icon];
		return YES;
	} else
		return NO;
}

@end

@implementation QSObject (ActionHandling)

+ (QSAction *)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle {
	return [[[self alloc] initWithActionDictionary:dict identifier:ident bundle:bundle] autorelease];
}

- (id)initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle {
	if (!dict) {
		[self release];
		return nil;
	}
	if (self = [self init]) {
		dict = [dict mutableCopy];

		[self setObject:dict forType:QSActionType];
		[self setPrimaryType:QSActionType];
		if (ident)
			[self setIdentifier:ident];

		NSString *newName = [bundle safeLocalizedStringForKey:ident value:ident table:@"QSAction.name"];

		if ([newName isEqualToString:ident] || !newName)
			newName = [dict objectForKey:@"name"];
		if (!newName)
			newName = ident;
		[self setName:newName];

		if (bundle)
			[self setObject:bundle forMeta:kSourceBundleMeta];

		[dict release];
	}
	return self;
}

- (NSMutableDictionary *)actionDict { return [self objectForType:QSActionType];  }

- (int)argumentCount { return [[[[self actionDict] objectForKey:kActionSelector] componentsSeparatedByString:@":"] count] - 1;  }

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [self objectForType:QSActionType];
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

- (NSString *)commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject {
	NSString *format;
	NSString *identi = [self identifier];

	//check class bundle
	format = [[(QSAction *)self bundle] safeLocalizedStringForKey:identi value:nil table:@"QSAction.commandFormat"];

	//Check the action dictionary
	if ([format isEqualToString:identi])
		format = [[self actionDict] objectForKey:@"commandFormat"];

	// Check the main bundle
	if ([format isEqualToString:identi])
		format = [[NSBundle mainBundle] safeLocalizedStringForKey:identi value:nil table:@"QSAction.commandFormat"];

	//Fallback format
	if (!format || [format isEqualToString:identi])
		format = [NSString stringWithFormat:@"%%@ (%@) %@", [self displayName], [self argumentCount] > 1 ? @" %@":@""];

	return [NSString stringWithFormat:format, [dObject displayName], iObject ? [iObject displayName] : @"<?>"];
}

//Accessors
- (NSBundle *)bundle { return [self objectForMeta:kSourceBundleMeta];  }
- (void)setBundle:(NSBundle *)aBundle { [self setObject:aBundle forMeta:kSourceBundleMeta];  }

@end
