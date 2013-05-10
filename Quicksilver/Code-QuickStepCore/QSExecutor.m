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

//#define compGT(a, b) (a < b)

#define pQSActionsLocation QSApplicationSupportSubPath(@"Actions.plist", NO)

QSExecutor *QSExec = nil;

@interface QSObject (QSActionsHandlerProtocol)
- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
@end

@interface QSAction (QSPrivate)
- (void)_setRank:(NSInteger)newRank;
@end

@implementation QSExecutor
+ (id)sharedInstance {
	if (!QSExec) QSExec = [[[self class] allocWithZone:[self zone]] init];
	return QSExec;
}

- (id)init {
	if (self = [super init]) {
		actionSources = [[NSMutableDictionary alloc] initWithCapacity:1];
		actionIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:1];
		directObjectTypes = [[NSMutableDictionary alloc] initWithCapacity:1];
	 	directObjectFileTypes = [[NSMutableDictionary alloc] initWithCapacity:1];

		NSDictionary *actionsPrefs = [NSDictionary dictionaryWithContentsOfFile:pQSActionsLocation];
		actionPrecedence = [[actionsPrefs objectForKey:@"actionPrecedence"] mutableCopy];
		actionRanking = [[actionsPrefs objectForKey:@"actionRanking"] mutableCopy];
		// Actions that appear in the 'actions menu' (use 'show action menu' action to see it)
		actionMenuActivation = [[actionsPrefs objectForKey:@"actionMenuActivation"] mutableCopy];
		// Actions that show up in the 2nd pane
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
	NSArray *files = [rootPath performSelector:@selector(stringByAppendingPathComponent:) onObjectsInArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootPath error:nil]];
	for(id <QSFileActionProvider> creator in [[QSReg instancesForTable:@"QSFileActionCreators"] allValues]) {
		[self addActions:[creator fileActionsFromPaths:files]];
	}
}

- (NSArray *)actionsForTypes:(NSArray *)types {
	NSMutableSet *set = [NSMutableSet set];
    NSArray *keys = [directObjectTypes allKeys];
    NSIndexSet *ind = [keys indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(NSString* actionType, NSUInteger idx, BOOL *stop) {
        return [[types indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(NSString *dObjectType, NSUInteger idx, BOOL *stop) {
            return UTTypeConformsTo((CFStringRef)dObjectType, (CFStringRef)actionType) && (![actionType isEqualToString:(NSString *)kUTTypeItem] || [dObjectType isEqualToString:(NSString*)kUTTypeItem]);
        }] count];
    }];
    for (NSString *key in [keys objectsAtIndexes:ind]) {
        [set unionSet:[directObjectTypes objectForKey:key]];
    }
	[set unionSet:[directObjectTypes objectForKey:@"*"]];
	return [set allObjects];
}

- (NSMutableSet *)actionsArrayForType:(NSString *)type {
    return [self actionsArrayForType:type store:NO];
}

- (NSMutableSet *)actionsArrayForType:(NSString *)type store:(BOOL)store {
    NSMutableSet *set = [NSMutableSet set];
    NSArray *keys = [directObjectTypes allKeys];
    NSIndexSet *ind = [keys indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(NSString* actionType, NSUInteger idx, BOOL *stop) {
        return !store ? UTTypeConformsTo((CFStringRef)actionType, (CFStringRef)type) :UTTypeConformsTo((CFStringRef)type, (CFStringRef)actionType);
    }];
    for (NSString *key in [keys objectsAtIndexes:ind]) {
        [set unionSet:[directObjectTypes objectForKey:key]];
    }
    if (store) {
        [directObjectTypes setObject:set forKey:type];
    }
    return set;
}

- (void)addActions:(NSArray *)actions {
	for (QSAction * action in actions) {
		[self addAction:action];
	}
}

- (void)addAction:(QSAction *)action {
	NSString *ident = [action identifier];
	if (!ident) {
		return;
    }
    
	QSAction *dupAction = [actionIdentifiers objectForKey:ident];
	if (dupAction) {
        return;
	}

    NSString *altName = [actionNames objectForKey:ident];
	if (altName) [action setLabel:altName];
    
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

	NSInteger index = [actionRanking indexOfObject:ident];

	if (index == NSNotFound) {
		CGFloat prec = [action precedence];
		NSUInteger i;
		CGFloat otherPrec;
		for(i = 0; i < [actionRanking count]; i++) {
			otherPrec = [[actionPrecedence valueForKey:[actionRanking objectAtIndex:i]] doubleValue];
			if (otherPrec < prec) break;
		}
		[actionRanking insertObject:ident atIndex:i];
		[actionPrecedence setObject:[NSNumber numberWithDouble:prec] forKey:ident];
		[action setRank:i];
#ifdef DEBUG
		if (VERBOSE) NSLog(@"inserting action %@ at %lu (%f) ", action, (unsigned long)i, prec);
#endif
	} else {
		[action _setRank:index];
	}
	NSArray *directTypes = [action directTypes];
	if (![directTypes count]) {
        directTypes = [NSArray arrayWithObject:@"*"];
    }
	for (NSString *type in directTypes) {
        [[self actionsArrayForType:type store:YES] addObject:action];
    }
    if ([action bundle] && [[action bundle] bundleIdentifier]) {
        [[self makeArrayForSource:[[action bundle] bundleIdentifier]] addObject:action];	
    }
}

- (void)updateRanks {
	NSUInteger i;
	for(i = 0; i < [actionRanking count]; i++) {
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


- (NSArray *)actions {
	return [actionIdentifiers allValues];
}

- (QSAction *)actionForIdentifier:(NSString *)identifier {
	return [actionIdentifiers objectForKey:identifier];
}

- (QSObject *)performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
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
    if (!dObject) {
        return nil;
    }
	NSArray *actions = nil;
	if ([[dObject handler] respondsToSelector:@selector(actionsForDirectObject:indirectObject:)])
		actions = (NSMutableArray *)[[dObject handler] actionsForDirectObject:dObject indirectObject:iObject];
    
	BOOL bypassValidation =
		(bypass && [dObject isProxyObject] && [(QSProxyObject *)dObject bypassValidation]);

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
	actions = [[QSLibrarian sharedInstance] scoredArrayForString:[NSString stringWithFormat:@"QSActionMnemonic:%@", [dObject primaryType]] inSet:actions mnemonicsOnly:YES];
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
	@try {
		actions = [aObject validActionsForDirectObject:dObject indirectObject:iObject];
	} @catch (NSException *localException) {
		NSLog(@"[Quicksilver %s]: localException = '%@'", __PRETTY_FUNCTION__, [localException description]);
	}
	return actions;
}

- (void)logActions {}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	if (!dObject) return nil;

    NSMutableArray *validActions = [NSMutableArray arrayWithCapacity:1];
	id aObject = nil;

	NSMutableDictionary *validatedActionsBySource = [NSMutableDictionary dictionary];
	NSArray *validSourceActions;

	NSArray *newActions = [self actionsForTypes:[dObject types]];
	BOOL isValid;
    
    for (QSAction *thisAction in newActions) {
        if (![thisAction enabled]) continue;
		validSourceActions = nil;
		NSDictionary *actionDict = [thisAction objectForType:QSActionType];
		isValid = ![[actionDict objectForKey:kActionValidatesObjects] boolValue];
                
		if (!isValid) {
			validSourceActions = [validatedActionsBySource objectForKey:[actionDict objectForKey:kActionClass]];
			if (!validSourceActions) {
                
				aObject = [thisAction provider];
				validSourceActions = [self validActionsForDirectObject:dObject indirectObject:iObject fromSource:aObject types:nil fileType:nil];
				NSString *className = NSStringFromClass([aObject class]);
				if (className)
					[validatedActionsBySource setObject:validSourceActions?validSourceActions:[NSArray array] forKey:className];
			}
            
			isValid = [validSourceActions containsObject:[thisAction identifier]];
		}
		//if ([validSourceActions count])
		//	NSLog(@"Actions for %@:%@", thisAction, validSourceActions);
        
		if (isValid) [validActions addObject:thisAction];
    }

	// NSLog(@"Actions for %@:%@", [dObject name] , validActions);
	if (![validActions count]) {
		NSLog(@"unable to find actions for %@", actionIdentifiers);
		NSLog(@"types %@", [dObject types]);
	}
	return [[validActions mutableCopy] autorelease];
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	QSActionProvider *actionObject = [[actionIdentifiers objectForKey:action] objectForKey:kActionClass];
	//  NSLog(@"actionobject %@", actionObject);
    QSObject *directObject = [dObject resolvedObject];
	return [actionObject validIndirectObjectsForAction:action directObject:directObject];
}

- (BOOL)actionIsEnabled:(QSAction*)action {
    id val = [actionActivation objectForKey:[action identifier]];
    return (val ? [val boolValue] : YES);
}
- (void)setAction:(QSAction *)action isEnabled:(BOOL)flag {
// 	if (VERBOSE) NSLog(@"set action %@ is enabled %d", action, flag);
	[actionActivation setObject:[NSNumber numberWithBool:flag] forKey:[action identifier]];
	[self writeActionsInfo];
}

- (BOOL)actionIsMenuEnabled:(QSAction*)action {
    id val = [actionMenuActivation objectForKey:[action identifier]];
    return (val ? [val boolValue] : YES);
}
- (void)setAction:(QSAction *)action isMenuEnabled:(BOOL)flag {
// 	if (VERBOSE) NSLog(@"set action %@ is menu enabled %d", action, flag);
	[actionMenuActivation setObject:[NSNumber numberWithBool:flag] forKey:[action identifier]];
	[self writeActionsInfo];
}

- (void)orderActions:(NSArray *)actions aboveActions:(NSArray *)lowerActions {
	NSInteger index = [[lowerActions valueForKeyPath:@"@min.rank"] integerValue];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Promote to %ld", (long)index);
#endif
	NSString *targetIdentifier = [actionRanking objectAtIndex:index];
	NSArray *identifiers = [actions valueForKey:@"identifier"];
	[actionRanking removeObjectsInArray:identifiers];
	index = [actionRanking indexOfObject:targetIdentifier];
	[actionRanking insertObjectsFromArray:identifiers atIndex:index];
	[self updateRanks];
}
- (void)orderActions:(NSArray *)actions belowActions:(NSArray *)higherActions {
	NSInteger index = [[higherActions valueForKeyPath:@"@max.rank"] integerValue];
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
	NSDictionary *tmpDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							 actionPrecedence, @"actionPrecedence",
							 actionRanking, @"actionRanking",
							 actionActivation, @"actionActivation",
							 actionMenuActivation, @"actionMenuActivation",
							 actionIndirects, @"actionIndirects",
							 actionNames, @"actionNames",
							 nil];
	[tmpDict writeToFile:pQSActionsLocation atomically:YES];
	[tmpDict release];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Wrote Actions Info");
#endif
}
@end

@implementation QSExecutor (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	if (info) {
        NSDictionary *actionDict;
        for (NSString *key in info) {
            actionDict = [info objectForKey:key];
            QSAction *action = [QSAction actionWithDictionary:actionDict identifier:key];
            [action setBundle:bundle];
            
            if ([[actionDict objectForKey:kActionInitialize] boolValue] && [[action provider] respondsToSelector:@selector(initializeAction:)])
                action = [[action provider] initializeAction:action];
            
            if (action) {
                [self addAction:action];
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
