

#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSObject.h"

#import "QSTypes.h"



#import "QSResourceManager.h"
#import "NDAppleScriptObject.h"
#import "NSBundle_BLTRExtensions.h"

//#import "QSAppleScriptActions.h"
#import "QSExecutor.h"


NSMutableArray *masterActionRanking;
static NSDictionary *actionPrecedence;

@implementation QSAction
static BOOL gModifiersAreIgnored;
+ (void) setModifiersAreIgnored:(BOOL)flag{
	//QSLog(@"ignore %d",flag);
	gModifiersAreIgnored=flag;
}
+ (BOOL) modifiersAreIgnored{
	if (VERBOSE && gModifiersAreIgnored)
		QSLog(@"ignoring modifiers %d",gModifiersAreIgnored);
	return gModifiersAreIgnored;
}



+ (void) initialize{
    actionPrecedence=[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"ActionsPrecedence" ofType:@"plist"]]retain];
}
+ (id)actionWithIdentifier:(NSString *)newIdentifier{
    return [self actionWithIdentifier:newIdentifier bundle:[NSBundle mainBundle]];
}
+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle{
    return [[[QSAction alloc]initWithIdentifier:newIdentifier bundle:newBundle]autorelease];
}
- (NSString *)description{
	return [self name];	
}
- (id) init {
	self = [super init];
	if (self != nil) {
		rank=999999;
	}
	return self;
}

- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle{
    if ((self=[super init])){
		[self setObject:[NSMutableDictionary dictionary] forType:QSActionType];
        [self setIdentifier:newIdentifier];
        [self setName:[newBundle safeLocalizedStringForKey:newIdentifier value:newIdentifier table:@"QSAction-name"]];
		//NSString *newDetails=[newBundle safeLocalizedStringForKey:newIdentifier value:@"missing" table:@"ActionDescriptions"];
		//   if (![newDetails isEqualToString:@"missing"])
		//	[self setDetails:newDetails];
		NSNumber *mod=[actionPrecedence objectForKey:[self identifier]];
		if (mod) [self setRankModification:[mod floatValue]];
	//				QSLog(@"rank %@ %d",self,rank);
		[self setPrimaryType:QSActionType];
		//else rankModification=0.0;
		[self setDisplaysResult:YES];
		[self setArgumentCount:1];
		[self setBundle:newBundle];
	    //QSLog([[NSBundle mainBundle]localizedStringForKey:newIdentifier value:newIdentifier table:@"ActionDescriptions"]);
    }
    return self;
}

/*
 - (NSString *) commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject{
	 
	 
	 NSString *format=[[self bundle]safeLocalizedStringForKey:[self identifier] value:nil table:@"ActionCommandFormats"];
	 //	QSLog(@"format %@",format);
	 
	 if ([format isEqualToString:[self identifier]]) format=[[NSBundle mainBundle]safeLocalizedStringForKey:[self identifier] value:nil table:@"ActionCommandFormats"];
	 
	 if ([format isEqualToString:[self identifier]]) format= [NSString stringWithFormat:@"%%@ (%@)%@",[self displayName],[self argumentCount]>1?@" %@":@""];
	 
	 
	 return [NSString stringWithFormat:format,
		 [dObject displayName],
		 iObject?[iObject displayName]:@"<missing>"
		 ];    
 }
 */
/*
 - (QSObject *) performOnDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject{
	 if (![self action])
		 return [(QSActionProvider *)[self provider] performAction:self directObject:dObject indirectObject:iObject];
	 else if ([self argumentCount]==2)
		 return [[self provider] performSelector:[self action] withObject:([self reverse]?iObject:dObject) withObject:([self reverse]?dObject:iObject)];
	 else if ([self argumentCount]==1)
		 return [[self provider] performSelector:[self action] withObject:dObject];
	 else
		 return [[self provider] performSelector:[self action]];
 }
 */

//- (float)rankModification { return 0; }


- (float)precedence{
	NSNumber *num=[[self actionDict]objectForKey:kActionPrecedence];
	if (!num)num=[[self actionDict]objectForKey:@"rankModification"];
#warning remove
	return num?[num floatValue]:0.0;
}
- (float)rankModification{
	return [self precedence];
}

- (void)setRankModification:(float)aRankModification {
	QSLog(@"setRankModification: deprecated");
	//	rankModification = a RankModification;
//	[[self actionDict]setObject:[NSNumber numberWithFloat:aRankModification] forKey:kActionRankModification];
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
//	QSLog(dname);
	[self setLabel:dname];
	[QSExec noteNewName:dname forAction:self];
}


- (int)userRank{
	return rank+1;
}
- (void)setUserRank:(int)newRank{
	   rank = newRank-1;
	[QSExec updateRanks];
}


- (BOOL)menuEnabled {
    return menuEnabled;
}
- (void)_setMenuEnabled:(BOOL)flag{
    menuEnabled = flag;
}
- (void)setMenuEnabled:(BOOL)flag {
    menuEnabled = flag;
	[QSExec setAction:self  isMenuEnabled:flag];
}



- (BOOL)enabled {
    return enabled;
}
- (void)_setEnabled:(BOOL)flag{
    enabled = flag;
}
- (void)setEnabled:(BOOL)flag {
    enabled = flag;
	[QSExec setAction:self  isEnabled:flag];
}

- (NSNumber *)defaultEnabled{
	return [[self actionDict]objectForKey:kActionEnabled];
}

//- (SEL)action { return [self actionDict]; }
- (void)setAction:(SEL)newAction {
	if(newAction)
		[[self actionDict] setObject:NSStringFromSelector(newAction) forKey:kActionSelector];
	else
		[[self actionDict] removeObjectForKey:kActionSelector];
	
}


- (void)setArgumentCount:(int)newArgumentCount {
	//	[[self actionDict] setObject:[NSNumber numberWithInt:newArgumentCount] forKey:kActionArgumentCount];
	
}

//- (BOOL)reverse { return [[[self actionDict]objectForKey:kActionReverseArguments]boolValue]; }
- (void)setReverse:(BOOL)flag {
	[[self actionDict] setObject:[NSNumber numberWithBool:flag] forKey:kActionReverseArguments];
}



//- (NSImage *)icon {if (icon) return [[icon retain] autorelease]; return [NSImage imageNamed:@"defaultAction"];}


//- (BOOL)indirectOptional { return indirectOptional; }
- (void)setIndirectOptional:(BOOL)flag {
 	[[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionIndirectOptional];
}

//- (BOOL)displaysResult { return displaysResult; }
- (void)setDisplaysResult:(BOOL)flag{
	[[self actionDict] setObject:[NSNumber numberWithInt:flag] forKey:kActionDisplaysResult];
}


- (id)userData { return [self objectForMeta:kUserDataMeta]; }
- (void)setUserData:(id)someData{[self setObject:someData forMeta:kUserDataMeta];}

- (NSBundle *)bundle { 
	NSBundle *bundle=[self objectForMeta:kSourceBundleMeta]; 
	if (!bundle){
//		if (VERBOSE)QSLog(@"bundle not found %@");
		NSDictionary *dict=[self objectForType:QSActionType];
		id provider=[dict objectForKey:kActionProvider];
		bundle=[QSReg bundleForClassName:provider];
	}
	return bundle;
}

- (id)provider {
	NSDictionary *dict=[self objectForType:QSActionType];
	
	id provider=[dict objectForKey:kActionProvider];
	if (!provider){
		NSString *class=[dict objectForKey:kActionClass];
		provider=[QSReg instanceForPointID:kQSActionProviders withID:class];

	}
	return provider;
}

- (void)setProvider:(id)newProvider {
	//QSLog(@"provider %@",newProvider);
	[[self actionDict] setObject:NSStringFromClass([newProvider class]) forKey:kActionClass];
	[[self actionDict] setObject:newProvider forKey:kActionProvider];
}

- (BOOL)canThread{
	return ![[[self actionDict]objectForKey:kActionRunsInMainThread]boolValue];
}

- (QSAction *)alternate{
	NSDictionary *dict=[self objectForType:QSActionType];
	NSString *alternateID=[dict objectForKey:kActionAlternate];
	
	return [QSExec actionForIdentifier:alternateID];	
}




-(int)order{return [self rank];}
- (IBAction)editActions:(id)sender{
	   [NSApp activateIgnoringOtherApps:YES];
	[NSClassFromString(@"QSPreferencesController") performSelector:@selector(showPaneWithIdentifier:) withObject:@"QSActionsPrefPane"];
	
}

- (NSMenu *)rankMenuWithTarget:(NSView *)target{
    NSMenu *menu=[[[NSMenu alloc]initWithTitle:@"RankMenu"]autorelease];
	
    NSMenuItem *item;
	
	NSString *title=[NSString stringWithFormat:@"Rank: %d",[self rank]+1];
	
	item=(NSMenuItem *)[menu addItemWithTitle:title action:NULL keyEquivalent:@""];
	[item setTarget:nil];
	[menu addItem:[NSMenuItem separatorItem]];
	
	item=(NSMenuItem *)[menu addItemWithTitle:@"Make Default" action:@selector(promoteAction:) keyEquivalent:@""];
	[item setTarget:target];
	
	if (fALPHA){
		item=(NSMenuItem *)[menu addItemWithTitle:@"Edit Actions..." action:@selector(editActions:) keyEquivalent:@""];
		[item setTarget:self];
	}
	
	
	return menu;
}


@end



@implementation QSActionHandler
// Object Handler Methods

- (NSString *)identifierForObject:(id <QSObject>)object{
	return nil;
	return [object objectForType:QSActionType];
}

- (NSString *)detailsOfObject:(QSObject *)object{
	NSString *newDetails=[[(QSAction *)object bundle] safeLocalizedStringForKey:[object identifier] value:@"missing" table:@"QSAction-description"];
	if ([newDetails isEqualToString:@"missing"])
		newDetails=nil;
	if (!newDetails)
		newDetails=[[(QSAction *)object actionDict]objectForKey:@"description"];
	
	//[self setDetails:newDetails];
	
	return newDetails;
}

- (void)setQuickIconForObject:(QSObject *)object{
    [object setIcon:[NSImage imageNamed:@"defaultAction"]];
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped{
	return NO;
}

- (BOOL)loadIconForObject:(QSObject *)object{
	NSImage *icon=nil;
	NSString *name=[[(QSAction *)object actionDict]objectForKey:@"icon"];
	if (!icon){
		icon=[QSRez imageWithExactName:[object identifier]];
	}
	if (!icon && name)
		icon=[QSResourceManager imageNamed:name inBundle:[object bundle]];
	

	if (icon){
		[object setIcon:icon];
		return YES;
	}
	return NO;
}


@end



@implementation QSObject (ActionHandling)

+ (QSAction *)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle{
	return [[[self alloc]initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle]autorelease];
}


- (id)initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle{    
	//	QSLog(@"ident:%@",ident);
    if (!dict){
		[self release];
		return nil;
	}
	if ((self = [self init])){
		dict=[[dict mutableCopy]autorelease];
		//[self setName:[dict object];
		[self setObject:dict forType:QSActionType];
		[self setPrimaryType:QSActionType];
		//NSString *identifierString=[dict objectForKey:kActionIdentifier];
		if (ident)
			[self setIdentifier:ident];
		
		NSString *newName=[bundle safeLocalizedStringForKey:ident value:ident table:@"QSAction.name"];
		
		//				QSLog(@"newName:%@",newName);
		if ([newName isEqualToString:ident] || !newName)
			newName=[dict objectForKey:@"name"];	
		
		//		QSLog(@"newName:%@",newName);
		if (!newName)
			newName=ident;
		
        [self setName:newName];
		
		if (bundle)
			[self setObject:bundle forMeta:kSourceBundleMeta];
	}
    return self;
}
- (NSMutableDictionary *)actionDict{
	return [self objectForType:QSActionType];
}
- (int)argumentCount {return [[[[self actionDict]objectForKey:kActionSelector]componentsSeparatedByString:@":"]count]-1; }


- (QSObject *) performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	NSDictionary *dict=[self objectForType:QSActionType];
	
	NSString *class=[dict objectForKey:kActionClass];
	QSActionProvider *provider=[dict objectForKey:kActionProvider];
	//	QSLog(@"provider %@",self);
	if (class || provider){
		if (!provider)
			provider = [QSReg instanceForPointID:kQSActionProviders withID:class];
		
		
		BOOL reverseArgs=[[dict objectForKey:kActionReverseArguments]boolValue];
		
		BOOL splitPlural=[[dict objectForKey:kActionSplitPluralArguments]boolValue];
		
		if (splitPlural && [dObject count]>1){
			NSArray *objects=[dObject splitObjects];
			id object;
			id result;
			//QSLog(@"split %@",objects);
			for (object in objects){
				//	QSLog(@"split %@",object);
				result=[self performOnDirectObject:object indirectObject:iObject];
			}
			return nil;
		}
		
		SEL selector=NSSelectorFromString([dict objectForKey:kActionSelector]);
		if (!selector)
			return [provider performAction:(QSAction *)self directObject:dObject indirectObject:iObject];
		else if ([self argumentCount]==2)
			return [provider performSelector:selector withObject:(reverseArgs?iObject:dObject) withObject:(reverseArgs?dObject:iObject)];
		else if ([self argumentCount]==1)
			return [provider performSelector:selector withObject:dObject];
		else
			return [provider performSelector:selector];
	}else{
		
	}
	
	return nil;
}
- (NSString *) commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject{
	NSString *format=nil;
	
	//check class bundle
	format=[[(QSAction *)self bundle]safeLocalizedStringForKey:[self identifier] value:nil table:@"QSAction. commandFormat"];
	
	//Check the action dictionary
	if ([format isEqualToString:[self identifier]])
		format=[[self actionDict]objectForKey:@"commandFormat"];

//	
	// Check the main bundle
	if ([format isEqualToString:[self identifier]])
		format=[[NSBundle mainBundle]safeLocalizedStringForKey:[self identifier] value:nil table:@"QSAction.commandFormat"];	
	
	//Fallback format
    if (!format||[format isEqualToString:[self identifier]])
		format= [NSString stringWithFormat:@"%%@ (%@)%@",[self displayName],[self argumentCount]>1?@" %@":@""];
//	if (!format || [format isEqualToString:[self identifier]])return nil;
	
//	QSLog(@"format %@ %@",[(QSAction *)self bundle],format);
	
	
    return [NSString stringWithFormat:format,
        [dObject displayName],
        iObject?[iObject displayName]:@"<?>"
        ];    
}

//Accessors
- (NSBundle *)bundle { 
	NSBundle *bundle=[self objectForMeta:kSourceBundleMeta]; 
	return bundle;
}

- (void)setBundle:(NSBundle *)aBundle
{
	[self setObject:aBundle forMeta:kSourceBundleMeta];
}

@end

