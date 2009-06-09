

#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSObject.h"

#import "QSTypes.h"

#import "QSResourceManager.h"
#import "NDAppleScriptObject.h"
#import "NSBundle_BLTRExtensions.h"

#import "QSExecutor.h"

static BOOL gModifiersAreIgnored;

@implementation QSAction

+ (void)setModifiersAreIgnored:(BOOL)flag {
	gModifiersAreIgnored = flag;
}

+ (BOOL)modifiersAreIgnored {
	if (VERBOSE && gModifiersAreIgnored)
		QSLog(@"ignoring modifiers %d",gModifiersAreIgnored);
	return gModifiersAreIgnored;
}

+ (id)actionWithDictionary:(NSDictionary *)dict {
    return [[[self alloc] initWithDictionary:dict] autorelease];
}

+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle {
    return [[[self alloc] initWithActionDictionary:dict identifier:ident bundle:bundle] autorelease];
}

+ (id)actionWithIdentifier:(NSString *)newIdentifier{
    return [[[QSExec actionForIdentifier:newIdentifier] retain] autorelease];
}

+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
    return [[[self alloc] initWithIdentifier:newIdentifier bundle:newBundle] autorelease];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		rank = 999999;
	}
	return self;
}

- (id)initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle {
    if (!dict) {
		[self release];
		return nil;
	}
	if ((self = [self init])) {
		dict = [[dict mutableCopy]autorelease];
		[self setObject:dict forType:QSActionType];
		[self setPrimaryType:QSActionType];
        
		if (ident)
			[self setIdentifier:ident];
		
		NSString *newName = [bundle safeLocalizedStringForKey:ident value:ident table:@"QSAction.name"];
		
		if ([newName isEqualToString:ident] || !newName)
			newName = [dict objectForKey:@"name"];	
		
		if (!newName)
			newName=ident;
		
        [self setName:newName];
		
		if (bundle)
			[self setObject:bundle forMeta:kSourceBundleMeta];
	}
    return self;
}

- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle {
    if ((self = [super init])) {
		[self setObject:[NSMutableDictionary dictionary] forType:QSActionType];
        [self setIdentifier:newIdentifier];
        [self setName:[newBundle safeLocalizedStringForKey:newIdentifier value:newIdentifier table:@"QSAction-name"]];

		[self setPrimaryType:QSActionType];

		[self setArgumentCount:1];
		[self setBundle:newBundle];
    }
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@", [super description], [self identifier]];	
}

- (NSMutableDictionary *)actionDict {
	return [self objectForType:QSActionType];
}

- (float)precedence {
	NSNumber *num = [[self actionDict] objectForKey:kActionPrecedence];
	if (!num) num = [[self actionDict] objectForKey:@"rankModification"];
#warning remove
	return num ? [num floatValue] : 0.0;
}

- (float)rankModification {
	return [self precedence];
}

- (void)setRankModification:(float)aRankModification {
	QSLog(@"setRankModification: deprecated");
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

- (void)setDisplayName:(NSString *)dname{
	[self setLabel:dname];
	[QSExec noteNewName:dname forAction:self];
}

- (int)userRank {
	return rank+1;
}

- (void)setUserRank:(int)newRank {
    rank = newRank - 1;
	[QSExec updateRanks];
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

- (BOOL)defaultEnabled {
    NSNumber *actionEnabledValue = [[self actionDict] objectForKey:kActionEnabled];
    return (actionEnabledValue != nil ? [actionEnabledValue boolValue] : YES);
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

- (BOOL)indirectOptional { return [[[self actionDict] objectForKey:kActionIndirectOptional] boolValue]; }
- (void)setIndirectOptional:(BOOL)flag {
 	[[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionIndirectOptional];
}

- (BOOL)displaysResult {
    return [[[self actionDict] objectForKey:kActionDisplaysResult] boolValue];
}

- (void)setDisplaysResult:(BOOL)flag {
    [[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionDisplaysResult];
}

- (BOOL)validatesObject {
    NSNumber *validates = [[self actionDict] objectForKey:kActionValidatesObject];
    return (validates ? [validates boolValue] : YES);
}

- (void)setValidatesObject:(BOOL)flag {
    [[self actionDict] setObject:[NSNumber numberWithBool:flag] forKey:kActionValidatesObject];
}

- (NSBundle *)bundle { 
	NSBundle *bundle = [self objectForMeta:kSourceBundleMeta]; 
	if (!bundle){
		NSDictionary *dict = [self objectForType:QSActionType];
		id provider = [dict objectForKey:kActionProvider];
		bundle = [QSReg bundleForClassName:provider];
	}
	return bundle;
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

- (BOOL)canThread {
	return ![[[self actionDict] objectForKey:kActionRunsInMainThread] boolValue];
}

- (QSAction *)alternate {
	NSString *alternateID = [[self actionDict] objectForKey:kActionAlternate];
	
	return [QSExec actionForIdentifier:alternateID];	
}

- (NSArray *)directTypes { return [[self actionDict] objectForKey:kActionDirectTypes]; }
- (NSArray *)directFileTypes { return [[self actionDict] objectForKey:kActionDirectFileTypes]; }
- (NSArray *)indirectTypes { return [[self actionDict] objectForKey:kActionIndirectTypes]; }
- (NSArray *)resultTypes { return [[self actionDict] objectForKey:kActionResultTypes]; }

- (int)order { return [self rank]; }

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

- (QSBasicObject *)performOnDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject {
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
			id object;
			id result;
			//QSLog(@"split %@",objects);
			for (object in objects) {
				//	QSLog(@"split %@",object);
				result = [self performOnDirectObject:object indirectObject:iObject];
			}
			return nil;
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

- (NSString *)commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject{
	NSString *format = nil;
	
	//check class bundle
	format = [[(QSAction *)self bundle] safeLocalizedStringForKey:[self identifier] value:nil table:@"QSAction.commandFormat"];
	
	//Check the action dictionary
	if ([format isEqualToString:[self identifier]])
		format = [[self actionDict] objectForKey:@"commandFormat"];
    
	// Check the main bundle
	if ([format isEqualToString:[self identifier]])
		format = [[NSBundle mainBundle] safeLocalizedStringForKey:[self identifier] value:nil table:@"QSAction.commandFormat"];
	
	//Fallback format
    if (!format || [format isEqualToString:[self identifier]])
		format = [NSString stringWithFormat:@"%%@ (%@)%@", [self displayName], [self argumentCount] > 1 ? @" %@" : @""];	
	
    return [NSString stringWithFormat:format, [dObject displayName], iObject ? [iObject displayName] : @"<?>"];
}

//Accessors
- (void)setBundle:(NSBundle *)aBundle {
	[self setObject:aBundle forMeta:kSourceBundleMeta];
}

@end

