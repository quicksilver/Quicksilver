

#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSObject.h"

#import "QSTypes.h"

#import "QSResourceManager.h"
#import "NDAppleScriptObject.h"
#import "NSBundle_BLTRExtensions.h"

#import "QSExecutor.h"

/* TODO 
 * Localization: [bundle safeLocalizedStringForKey:ident value:ident table:@"QSAction.name"]
 */

static BOOL gModifiersAreIgnored;

@implementation QSAction

+ (void)setModifiersAreIgnored:(BOOL)flag {
	gModifiersAreIgnored = flag;
}

+ (BOOL)modifiersAreIgnored {
	if (VERBOSE && gModifiersAreIgnored)
		QSLog(@"ignoring modifiers %d", gModifiersAreIgnored);
	return gModifiersAreIgnored;
}

+ (id)actionWithDictionary:(NSDictionary *)dict {
    return [[[self alloc] initWithDictionary:dict] autorelease];
}

+ (id)actionWithIdentifier:(NSString *)newIdentifier{
    return [[[QSExec actionForIdentifier:newIdentifier] retain] autorelease];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		rank = 999999;
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    if (!dict) {
		[self release];
		return nil;
	}
    
	if ((self = [self init])) {
		dict = [[dict mutableCopy] autorelease];
		[self setObject:dict forType:QSActionType];
		[self setPrimaryType:QSActionType];
        [self setIdentifier:[dict objectForKey:kActionIdentifier]];
    }
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@", [super description], [self identifier]];	
}

- (NSMutableDictionary *)actionDict {
	return [self objectForType:QSActionType];
}

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [self objectForType:QSActionType];
	
	NSString *class = [dict objectForKey:kActionClass];
	QSActionProvider *provider = [dict objectForKey:kActionProvider];
    
	if (class || provider) {
		if (!provider)
			provider = (QSActionProvider*)[QSReg instanceForPointID:kQSActionProviders withID:class];
		
		BOOL reverseArgs = [[dict objectForKey:kActionReverseArguments] boolValue];
		
		BOOL splitPlural = [[dict objectForKey:kActionSplitPluralArguments] boolValue];
		
		if (splitPlural && [dObject count] > 1) {
			NSArray *objects = [dObject splitObjects];
			QSObject *object;
            QSObject *result;
			QSCollection *collection = [QSCollection collection];
            
			//QSLog(@"split %@",objects);
			for (object in objects) {
				//	QSLog(@"split %@",object);
                result = [self performOnDirectObject:object indirectObject:iObject];
                if (result)
                    [collection addObject:result];
			}
			return collection;
		}
		
		SEL selector = NSSelectorFromString([dict objectForKey:kActionSelector]);
		if (!selector)
			return [provider performAction:(QSAction *)self directObject:dObject indirectObject:iObject];
		else if ([self argumentCount] == 2)
			return [provider performSelector:selector withObject:(reverseArgs ? iObject : dObject) withObject:(reverseArgs ? dObject : iObject)];
		else if ([self argumentCount] == 1)
			return [provider performSelector:selector withObject:dObject];
		else
			return [provider performSelector:selector];
	} else {
		
	}
	
	return nil;
}

- (QSAction *)alternate {
	NSString *alternateID = [[self actionDict] objectForKey:kActionAlternate];
	
	return [QSExec actionForIdentifier:alternateID];	
}

- (id)provider {
	NSDictionary *dict = [self actionDict];
	
	id provider = [dict objectForKey:kActionProvider];
	if (!provider) {
		NSString *class = [dict objectForKey:kActionClass];
		provider = [QSReg instanceForPointID:kQSActionProviders withID:class];
	}
	return provider;
}

- (void)setProvider:(id)newProvider {
	[[self actionDict] setObject:NSStringFromClass([newProvider class]) forKey:kActionClass];
	[[self actionDict] setObject:newProvider forKey:kActionProvider];
}

- (NSString *)class {
    return [[self actionDict] objectForKey:kActionClass];
}

- (void)setClass:(NSString *)class {
    [[self actionDict] setObject:class forKey:kActionClass];
}

- (SEL)action {
    return NSSelectorFromString([[self actionDict] objectForKey:kActionSelector]);
}

- (void)setAction:(SEL)newAction {
	if(newAction)
		[[self actionDict] setObject:NSStringFromSelector(newAction) forKey:kActionSelector];
	else
		[[self actionDict] removeObjectForKey:kActionSelector];
}

- (int)rank {
    return rank;
}

- (int)_rank {
    return rank;
}

- (void)_setRank:(int)newRank {
	[self willChangeValueForKey:@"rank"];
    rank = newRank;
	[self didChangeValueForKey:@"rank"];
}

- (void)setRank:(int)newRank {
    rank = newRank;
	[QSExec updateRanks];
}

- (int)userRank {
	return rank + 1;
}

- (void)setUserRank:(int)newRank {
    rank = newRank - 1;
	[QSExec updateRanks];
}

- (float)precedence {
#warning remove (tiennou: really ?)
	NSNumber *num = [[self actionDict] objectForKey:kActionPrecedence];
	if (!num) num = [[self actionDict] objectForKey:@"rankModification"];
	return num ? [num floatValue] : 0.0;
}

- (BOOL)defaultEnabled {
    NSNumber *actionEnabledValue = [[self actionDict] objectForKey:kActionEnabled];
    return (actionEnabledValue != nil ? [actionEnabledValue boolValue] : YES);
}

- (BOOL)enabled {
    return enabled;
}

- (void)_setEnabled:(BOOL)flag {
    enabled = flag;
}

- (void)setEnabled:(BOOL)flag {
    enabled = flag;
	[QSExec setAction:self isEnabled:flag];
}

- (BOOL)menuEnabled {
    return menuEnabled;
}

- (void)_setMenuEnabled:(BOOL)flag {
    menuEnabled = flag;
}

- (void)setMenuEnabled:(BOOL)flag {
    menuEnabled = flag;
	[QSExec setAction:self isMenuEnabled:flag];
}

- (int)argumentCount {
    int argCount = -1;
    NSNumber *argCountValue = [[self actionDict] objectForKey:kActionArgumentCount];
    if (argCountValue)
        argCount = [argCountValue intValue];
    
    if (argCount == -1) {
        NSString *selector = [[self actionDict] objectForKey:kActionSelector];
        if (selector)
            argCount = [[selector componentsSeparatedByString:@":"] count] - 1;
    }
    
    if (argCount == -1)
        [NSException raise:NSInternalInconsistencyException format:@"Can't guess -argumentCount"];
    
    return argCount;
}

- (void)setArgumentCount:(int)newArgumentCount {
	[[self actionDict] setObject:[NSNumber numberWithInt:newArgumentCount] forKey:kActionArgumentCount];	
}

- (BOOL)canThread {
	return ![[[self actionDict] objectForKey:kActionRunsInMainThread] boolValue];
}

- (BOOL)displaysResult {
    NSNumber *dispValue = [[self actionDict] objectForKey:kActionDisplaysResult];
    return (dispValue ? [dispValue boolValue] : YES);
}

- (void)setDisplaysResult:(BOOL)flag {
    [[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionDisplaysResult];
}

- (BOOL)indirectOptional { return [[[self actionDict] objectForKey:kActionIndirectOptional] boolValue]; }
- (void)setIndirectOptional:(BOOL)flag {
 	[[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionIndirectOptional];
}

- (BOOL)validatesObject {
    NSNumber *validates = [[self actionDict] objectForKey:kActionValidatesObject];
    return (validates ? [validates boolValue] : YES);
}

- (void)setValidatesObject:(BOOL)flag {
    [[self actionDict] setObject:[NSNumber numberWithBool:flag] forKey:kActionValidatesObject];
}

- (NSArray *)directTypes { return [[self actionDict] objectForKey:kActionDirectTypes]; }
- (NSArray *)directFileTypes { return [[self actionDict] objectForKey:kActionDirectFileTypes]; }
- (NSArray *)indirectTypes { return [[self actionDict] objectForKey:kActionIndirectTypes]; }
- (NSArray *)resultTypes { return [[self actionDict] objectForKey:kActionResultTypes]; }

- (NSMenu *)rankMenuWithTarget:(NSView *)target {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"RankMenu"] autorelease];
	
    NSMenuItem *item;
	
	NSString *title = [NSString stringWithFormat:@"Rank: %d", [self rank] + 1];
	
	item = [menu addItemWithTitle:title action:NULL keyEquivalent:@""];
	[item setTarget:nil];
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [menu addItemWithTitle:@"Make Default" action:@selector(promoteAction:) keyEquivalent:@""];
	[item setTarget:target];
	
	if (fALPHA) {
		item = [menu addItemWithTitle:@"Edit Actions..." action:@selector(editActions:) keyEquivalent:@""];
		[item setTarget:self];
	}
	
	return menu;
}

- (NSString *)commandFormat {
    NSString *format = [[self bundle] safeLocalizedStringForKey:[self identifier] value:nil table:@"QSAction.commandFormat"];
    
	// Fallback format
    if (!format)
        format = ([self argumentCount] > 1 ? @"%@ (%@) %@" : @"%@ (%@)");
    
    return format;
}

@end

