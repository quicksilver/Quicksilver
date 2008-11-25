#import "QSKeys.h"
#import "QSExecutor.h"
#import "QSLibrarian.h"
#import "QSObject.h"
#import "QSTypes.h"

#import "QSRankedObject.h"
#import "QSProxyObject.h"
#import "QSMacros.h"

#import "QSObjectSource.h"

#import "QSController.h"

#import "NSObject+ReaperExtensions.h"
#import "QSObject_FileHandling.h"
#import "QSObject_PropertyList.h"

#import "NSBundle_BLTRExtensions.h"
#import "QSTaskController.h"

#import "QSMnemonics.h"

#import "QSAction.h"
#import "QSActionProvider.h"
#import "QSResourceManager.h"

#import "QSRegistry.h"

#import "QSNullObject.h"
#import "NSException_TraceExtensions.h"

//#define compGT(a, b) (a < b)

#define pQSActionsLocation QSApplicationSupportSubPath(@"Actions.plist", NO)

QSExecutor *QSExec;

/*@interface QSObject (QSActionsHandlerProtocol)
- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
@end*/

@interface QSAction (QSPrivate)
- (void)_setRank:(int)newRank;
@end

@implementation QSExecutor
+ (id)sharedInstance {
	if (!QSExec) QSExec = [[[self class] allocWithZone:[self zone]] init];
	return QSExec;
}

- (id)init {
	if (self = [super init]) {
		actionSources = [[NSMutableDictionary alloc] initWithCapacity:1];
		oldActionObjects = [[NSMutableArray alloc] initWithCapacity:1];
		actionIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:1];
		directObjectTypes = [[NSMutableDictionary alloc] initWithCapacity:1];
	 	directObjectFileTypes = [[NSMutableDictionary alloc] initWithCapacity:1];

		NSDictionary *actionsPrefs = [NSDictionary dictionaryWithContentsOfFile:pQSActionsLocation];
		actionPrecedence = [[actionsPrefs objectForKey:@"actionPrecedence"] mutableCopy];
		actionRanking = [[actionsPrefs objectForKey:@"actionRanking"] mutableCopy];
		actionMenuActivation = [[actionsPrefs objectForKey:@"actionMenuActivation"] mutableCopy];
		actionActivation = [[actionsPrefs objectForKey:@"actionActivation"] mutableCopy];
		actionIndirects = [[actionsPrefs objectForKey:@"actionIndirects"] mutableCopy];
		actionNames = [[actionsPrefs objectForKey:@"actionNames"] mutableCopy];

		if (!actionPrecedence)
			actionPrecedence = [[NSMutableDictionary alloc] init];
		if (!actionRanking)
			actionRanking = [[NSMutableArray alloc] init];
		if (!actionActivation)
			actionActivation = [[NSMutableDictionary alloc] init];
		if (!actionMenuActivation)
			actionMenuActivation = [[NSMutableDictionary alloc] init];
		if (!actionIndirects)
			actionIndirects = [[NSMutableDictionary alloc] init];
		if (!actionNames)
			actionNames = [[NSMutableDictionary alloc] init];

		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogEntryChanged object:nil];
#if 0
		[(NSImage *)[[[NSImage alloc] initWithSize:NSZeroSize] autorelease] setName:@"QSDirectProxyImage"];
		[(NSImage *)[[[NSImage alloc] initWithSize:NSZeroSize] autorelease] setName:@"QSDefaultAppProxyImage"];
		[(NSImage *)[[[NSImage alloc] initWithSize:NSZeroSize] autorelease] setName:@"QSIndirectProxyImage"];
#endif
	}
	return self;
}

- (void)dealloc {
	// [self writeCatalog:self];
	[oldActionObjects release];
	[actionIdentifiers release];
	[directObjectTypes release];
	[directObjectFileTypes release];
	[actionSources release];
	[actionRanking release];
	[actionPrecedence release];
	[actionActivation release];
	[actionMenuActivation release];
	[actionIndirects release];
	[actionNames release];	
	[super dealloc];
}

- (void)loadFileActions {
	NSString *rootPath = QSApplicationSupportSubPath(@"Actions/", NO);
	NSArray *files = [rootPath performSelector:@selector(stringByAppendingPathComponent:) onObjectsInArray:[[NSFileManager defaultManager] directoryContentsAtPath:rootPath]];
	NSEnumerator *e = [[QSReg instancesForTable:@"QSFileActionCreators"] objectEnumerator];
	id <QSFileActionProvider> creator;
	while(creator = [e nextObject]) {
		[self addActions:[creator fileActionsFromPaths:files]];
	}
}

- (NSArray *)actionsForFileTypes:(NSArray *)types {
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *e = [types objectEnumerator];
	NSString *type;
	while (type = [e nextObject]) {
		[set addObjectsFromArray:[directObjectFileTypes objectForKey:type]];
	}
	[set addObjectsFromArray:[directObjectFileTypes objectForKey:@"*"]];
	return [set allObjects];
}

- (NSArray *)actionsForTypes:(NSArray *)types fileTypes:(NSArray *)fileTypes {
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *e = [types objectEnumerator];
	NSString *type;
	while (type = [e nextObject]) {
		if ([type isEqualToString:QSFilePathType]) {
			[set addObjectsFromArray:[self actionsForFileTypes:fileTypes]];
		} else {
			[set addObjectsFromArray:[directObjectTypes objectForKey:type]];
		}
	}
	[set addObjectsFromArray:[directObjectTypes objectForKey:@"*"]];
	return [set allObjects];
}


- (NSMutableArray *)actionsArrayForType:(NSString *)type {
	NSMutableArray *array = [directObjectTypes objectForKey:type];
	if (!array)
		[directObjectTypes setObject:(array = [NSMutableArray array]) forKey:type];
	return array;
}

- (NSMutableArray *)actionsArrayForFileType:(NSString *)type {
	NSMutableArray *array = [directObjectFileTypes objectForKey:type];
	if (!array)
		[directObjectFileTypes setObject:(array = [NSMutableArray array]) forKey:type];
	return array;
}

- (void)addActions:(NSArray *)actions {
	foreach (action, actions) {
		[self addAction:action];
	}
}

- (void)addAction:(QSAction *)action {
	NSString *ident = [action identifier];
	if (!ident)
		return;
	NSString *altName = [actionNames objectForKey:ident];
	if (altName) [action setLabel:altName];
	QSAction *dupAction = [actionIdentifiers objectForKey:ident];
	if (dupAction) {
		[[directObjectTypes allValues] makeObjectsPerformSelector:@selector(removeObject:) withObject:dupAction];
		[[directObjectFileTypes allValues] makeObjectsPerformSelector:@selector(removeObject:) withObject:dupAction];
	}

	[actionIdentifiers setObject:action forKey:ident];

    
	BOOL activation = NO;
    NSNumber *act = nil;
    act = [actionActivation objectForKey:ident];
	if (act)
        activation = [act boolValue];
    else
        activation = [action defaultEnabled];
	[action setEnabled:activation];
    
    
    act = [actionMenuActivation objectForKey:ident];
	if (act)
        activation = [act boolValue];
    else
        activation = [action defaultEnabled];
	[action setMenuEnabled:activation];    

	int index = [actionRanking indexOfObject:ident];

	if (index == NSNotFound) {
		float prec = [action precedence];
		int i;
		float otherPrec;
		for(i = 0; i < [actionRanking count]; i++) {
			otherPrec = [[actionPrecedence valueForKey:[actionRanking objectAtIndex:i]] floatValue];
			if (otherPrec < prec) break;
		}
		[actionRanking insertObject:ident atIndex:i];
		[actionPrecedence setObject:[NSNumber numberWithFloat:prec] forKey:ident];
		[action setRank:i];

		if (VERBOSE) NSLog(@"inserting action %@ at %d (%f) ", action, i, prec);
	} else {
		[action _setRank:index];
	}
	NSDictionary *actionDict = [action objectForType:QSActionType];
	NSArray *directTypes = [actionDict objectForKey:@"directTypes"];
	if (![directTypes count]) directTypes = [NSArray arrayWithObject:@"*"];
	NSEnumerator *e = [directTypes objectEnumerator];
	NSString *type;
	while (type = [e nextObject])
		[[self actionsArrayForType:type] addObject:action];

	if ([directTypes containsObject:QSFilePathType]) {
		directTypes = [actionDict objectForKey:@"directFileTypes"];
		if (![directTypes count]) directTypes = [NSArray arrayWithObject:@"*"];
		e = [directTypes objectEnumerator];
		while (type = [e nextObject]) {
			[[self actionsArrayForFileType:type] addObject:action];
		}
	}
}

- (void)updateRanks {
	int i;
	for(i = 0; i<[actionRanking count]; i++) {
		[[actionIdentifiers objectForKey:[actionRanking objectAtIndex:i]] _setRank:i];
	}
	[self writeActionsInfo];
}

- (NSMutableArray *)getArrayForSource:(NSString *)sourceid {
	return [actionSources objectForKey:sourceid];
//	NSMutableArray *array = [actionSources objectForKey:sourceid];
//	return array;
}

- (NSMutableArray *)makeArrayForSource:(NSString *)sourceid {
	NSMutableArray *array = [actionSources objectForKey:sourceid];
	if (!array) [actionSources setObject:(array = [NSMutableArray array]) forKey:sourceid];
	return array;
}

//- (void)registerActions:(id)actionObject {
//	if (!actionObject) return;
//	[oldActionObjects addObject:actionObject];
//	[self performSelectorOnMainThread:@selector(loadActionsForObject:) withObject:actionObject waitUntilDone:YES];
//}

//- (void)loadActionsForObject:(id)actionObject {
//	NSEnumerator *actionEnumerator = [[actionObject actions] objectEnumerator];
//	id action;
//	while (action = [actionEnumerator nextObject]) {
//		if ([action identifier])
//			[actionIdentifiers setObject:action forKey:[action identifier]];
//	}
//}


- (NSArray *)actions {
	return [actionIdentifiers allValues];
}

- (QSAction *)actionForIdentifier:(NSString *)identifier {
	return [actionIdentifiers objectForKey:identifier];
}

- (QSObject *)performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	// NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	QSAction *actionObject = [actionIdentifiers objectForKey:action];
	if (actionObject)
		return [actionObject performOnDirectObject:dObject indirectObject:iObject];
	else
		NSLog(@"Action not found: %@", action);
	return nil;
}



- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	return [self rankedActionsForDirectObject:dObject indirectObject:iObject shouldBypass:NO];
}

- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject shouldBypass:(BOOL)bypass {
	NSArray *actions = nil;
    
	BOOL bypassValidation =
		(bypass && [dObject isKindOfClass:[QSProxyObject class]] && [(QSProxyObject *)dObject bypassValidation]);

	if (bypassValidation) {
		//NSLog(@"bypass? %@ %@", dObject, NSStringFromClass([dObject class]) );
		actions = [[[actionIdentifiers allValues] mutableCopy] autorelease];
	}
	if (!actions)
		actions = [self validActionsForDirectObject:dObject indirectObject:iObject];

	NSString *preferredActionID = [dObject objectForMeta:kQSObjectDefaultAction];

	id preferredAction = nil;
    if (preferredActionID)
		preferredAction = [self actionForIdentifier:preferredActionID];

	//	NSLog(@"prefer \"%@\"", preferredActionID);
	//	NSLog(@"actions %d", [actions count]);
#if 1
	NSSortDescriptor *rankDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES];
	actions = [actions sortedArrayUsingDescriptors:[NSArray arrayWithObject:rankDescriptor]];
	[rankDescriptor release];
#else
	actions = [QSLib scoredArrayForString:[NSString stringWithFormat:@"QSActionMnemonic:%@", [dObject primaryType]] inSet:actions mnemonicsOnly:YES];
#endif

	if (preferredAction)
		actions = [NSArray arrayWithObjects:preferredAction, actions, nil];
	return actions;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject fromSource:(id)aObject types:(NSSet *)dTypes fileType:(NSString *)fileType {
	if (dTypes) {
		NSMutableSet *aTypes = [NSMutableSet setWithArray:[aObject types]];

		if ([aTypes count]) {
			[aTypes intersectSet:dTypes];
			if (![aTypes count]) return nil;
			if ([aTypes containsObject:QSFilePathType] && [aObject fileTypes] && ([aTypes count] == 1 || [[dObject primaryType] isEqualToString:QSFilePathType]) ) {
				if (![[aObject fileTypes] containsObject:fileType]) return nil;
			}
		}
	}
	NSArray *actions = nil;
	NS_DURING
		actions = [aObject validActionsForDirectObject:dObject indirectObject:iObject];
	NS_HANDLER
		;
	NS_ENDHANDLER
	return actions;
}

- (void)logActions {}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	if (!dObject) return nil;
	NSMutableArray *actions = [NSMutableArray arrayWithCapacity:1];
	// unsigned i;
	id aObject = nil;
	NSSet *types = [NSSet setWithArray:[dObject types]];
	NSString *fileType = [dObject singleFileType];

	NSMutableDictionary *validatedActionsBySource = [NSMutableDictionary dictionary];
	NSArray *validSourceActions;

	//	for(i = 0; i<[oldActionObjects count]; i++) {
	//		aObject = [oldActionObjects objectAtIndex:i];
	//		validSourceActions = [self validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject fromSource:aObject types:(NSSet *)types fileType:(NSString *)fileType];
	//		if (validSourceActions) {
	//			//[validatedActionsBySource setObject:validSourceActions forKey:NSStringFromClass([aObject class])];
	//			[actions addObjectsFromArray:validSourceActions];
	//		}
	//	}
	//	NSLog(@"oldActionObjects %@", oldActionObjects);
	//
	//if (bypassValidation) NSLog(@"bypasssing validation");
	NSMutableArray *validActions = [[[actionIdentifiers objectsForKeys:actions notFoundMarker:[NSNull null]]mutableCopy] autorelease]; //
	[validActions removeObject:[NSNull null]];

	//NSArray *newActions = bypassValidation?validActions
	//									:
	NSArray *newActions = [self actionsForTypes:[dObject types] fileTypes:fileType?[NSArray arrayWithObject:fileType] :nil];
	NSEnumerator *newActionEnumerator = [newActions objectEnumerator];

	QSAction *thisAction;
	BOOL isValid;
	while(thisAction = [newActionEnumerator nextObject]) {
		if (![thisAction enabled]) continue;
		validSourceActions = nil;
		NSDictionary *actionDict = [thisAction objectForType:QSActionType];
		isValid = ![[actionDict objectForKey:kActionValidatesObjects] boolValue];

		//NSLog(@"thisact %@", thisAction);

		if (!isValid) {
			validSourceActions = [validatedActionsBySource objectForKey:[actionDict objectForKey:kActionClass]];
			if (!validSourceActions) {

				aObject = [thisAction provider];
				validSourceActions = [self validActionsForDirectObject:dObject indirectObject:iObject fromSource:aObject types:nil fileType:nil];
				NSString *className = NSStringFromClass([aObject class]);
				if (className)
					[validatedActionsBySource setObject:validSourceActions?validSourceActions:[NSArray array] forKey:className];

				if (validSourceActions) {
					[actions addObjectsFromArray:validSourceActions];
				}
			}

			isValid = [validSourceActions containsObject:[thisAction identifier]];
		}
		//if ([validSourceActions count])
		//	NSLog(@"Actions for %@:%@", thisAction, validSourceActions);

		if (isValid) [validActions addObject:thisAction];
	}


	// NSLog(@"Actions for %@:%@", [dObject name] , validActions);
	if (![validActions count]) {
		NSLog(@"unable to find actions %@\r%@", oldActionObjects, actionIdentifiers);
		NSLog(@"types %@ %@", types, fileType);
	}
	return [[validActions copy] autorelease];
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	QSActionProvider *actionObject = [[actionIdentifiers objectForKey:action] objectForKey:kActionClass];
	//  NSLog(@"actionobject %@", actionObject);
	return [actionObject validIndirectObjectsForAction:action directObject:dObject];
}

- (BOOL)actionIsEnabled:(QSAction*)action {
    id val = [actionActivation objectForKey:[action identifier]];
    return (val ? [val boolValue] : YES);
}
- (void)setAction:(QSAction *)action isEnabled:(BOOL)flag {
//	if (VERBOSE) NSLog(@"set action %@ is enabled %d", action, flag);
	[actionActivation setObject:[NSNumber numberWithBool:flag] forKey:[action identifier]];
	[self writeActionsInfo];
}

- (BOOL)actionIsMenuEnabled:(QSAction*)action {
    id val = [actionMenuActivation objectForKey:[action identifier]];
    return (val ? [val boolValue] : YES);
}
- (void)setAction:(QSAction *)action isMenuEnabled:(BOOL)flag {
//	if (VERBOSE) NSLog(@"set action %@ is menu enabled %d", action, flag);
	[actionMenuActivation setObject:[NSNumber numberWithBool:flag] forKey:[action identifier]];
	[self writeActionsInfo];
}

- (void)orderActions:(NSArray *)actions aboveActions:(NSArray *)lowerActions {
	int index = [[lowerActions valueForKeyPath:@"@min.rank"] intValue];
	if (VERBOSE) NSLog(@"Promote to %d", index);
	NSString *targetIdentifier = [actionRanking objectAtIndex:index];
	NSArray *identifiers = [actions valueForKey:@"identifier"];
	[actionRanking removeObjectsInArray:identifiers];
	index = [actionRanking indexOfObject:targetIdentifier];
	[actionRanking insertObjectsFromArray:identifiers atIndex:index];
	[self updateRanks];
}
- (void)orderActions:(NSArray *)actions belowActions:(NSArray *)higherActions {
	int index = [[higherActions valueForKeyPath:@"@max.rank"] intValue];
	//NSLog(@"demote to %d", index);
	NSString *targetIdentifier = [actionRanking objectAtIndex:index];
	NSArray *identifiers = [actions valueForKey:@"identifier"];
	[actionRanking removeObjectsInArray:identifiers];
	index = [actionRanking indexOfObject:targetIdentifier];
	[actionRanking insertObjectsFromArray:identifiers atIndex:index+1];
	[self updateRanks];
}
- (void)noteIndirect:(QSObject *)iObject forAction:(QSObject *)aObject {
	NSString *iIdent = [iObject identifier];
	if (!iIdent) return;
	NSString *aIdent = [aObject identifier];
	NSMutableArray *array;
	if (!(array = [actionIndirects objectForKey:aIdent]) )
		[actionIndirects setObject:(array = [NSMutableArray array]) forKey:aIdent];
	[array removeObject:iIdent];
	[array insertObject:iIdent atIndex:0];
	if ([array count] >15) [array removeObjectsInRange:NSMakeRange(15, [array count] -15)];
	[self performSelector:@selector(writeActionsInfoNow) withObject:nil afterDelay:5.0 extend:YES];
}

- (void)noteNewName:(NSString *)name forAction:(QSObject *)aObject {
	NSString *aIdent = [aObject identifier];
	if (!name)
		[actionNames removeObjectForKey:aIdent];
	else
		[actionNames setObject:name forKey:aIdent];
	[self performSelector:@selector(writeActionsInfoNow) withObject:nil afterDelay:5.0 extend:YES];
}

- (void)writeActionsInfo {
	[self performSelector:@selector(writeActionsInfoNow) withObject:nil afterDelay:3.0 extend:YES];
}
- (void)writeActionsInfoNow {
#if 1
	[[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:actionPrecedence, actionRanking, actionActivation, actionMenuActivation, actionIndirects, actionNames, nil] forKeys:[NSArray arrayWithObjects:@"actionPrecedence", @"actionRanking", @"actionActivation", @"actionMenuActivation", @"actionIndirects", @"actionNames", nil]] writeToFile:pQSActionsLocation atomically:YES];
#else
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:actionPrecedence forKey:@"actionPrecedence"];
	[dict setObject:actionRanking forKey:@"actionRanking"];
	[dict setObject:actionActivation forKey:@"actionActivation"];
	[dict setObject:actionMenuActivation forKey:@"actionMenuActivation"];
	[dict setObject:actionIndirects forKey:@"actionIndirects"];
	[dict setObject:actionNames forKey:@"actionNames"];
	[dict writeToFile:pQSActionsLocation atomically:YES];
#endif
	if (VERBOSE) NSLog(@"Wrote Actions Info");
}
@end


@implementation QSExecutor (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	if (info) {
        NSEnumerator *e = [info keyEnumerator];
        NSDictionary *actionDict;
        NSString *key;
        while (key = [e nextObject]) {
            actionDict = [info objectForKey:key];
            
            if ([[actionDict objectForKey:kItemFeatureLevel] intValue] > [NSApp featureLevel]) {
                NSLog(@"Prevented load of action %@", [actionDict objectForKey:kItemID]);
                continue;
            }
            
            QSAction *action = [QSAction actionWithDictionary:actionDict identifier:key];
            [action setBundle:bundle];
            
            if ([[actionDict objectForKey:kActionInitialize] boolValue] && [[action provider] respondsToSelector:@selector(initializeAction:)])
                action = [[action provider] initializeAction:action];
            
            if (action) {
                [self addAction:action];
                [[self makeArrayForSource:[bundle bundleIdentifier]] addObject:action];
            }
        }
	} else {
		//		NSDictionary *providers = [[[plugin bundle] dictionaryForFileOrPlistKey:@"QSRegistration"] objectForKey:@"QSActionProviders"];
		//		if (providers) {
		//				[self loadOldActionProviders:[providers allValues]];
		//		}
	}
	return YES;
}
@end

