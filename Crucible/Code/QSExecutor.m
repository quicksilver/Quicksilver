
#define compGT(a, b) (a < b)

#define pQSActionsLocation		QSApplicationSupportSubPath(@"Actions.plist", NO)

QSExecutor *QSExec;

@interface QSObject (QSActionsHandlerProtocol)
- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
@end

@interface QSExecutor (Private)
- (void)loadActions;
@end

@implementation QSExecutor
+ (id) sharedInstance {
    if (!QSExec)
        QSExec = [[[self class] allocWithZone:[self zone]] init];
    return QSExec;
}

- (id) init {
    self = [super init];
    if( self ) {
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
		
        // Register for Notifications
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeCatalog:) name:QSCatalogEntryChanged object:nil];
		
        //Create proxy Images
        NSArray* imageNames = [[NSArray alloc] initWithObjects:
                               @"QSDirectProxyImage",
                               @"QSDefaultAppProxyImage",
                               @"QSIndirectProxyImage",
                               nil];
        for(NSString *imageName in imageNames ) {
            NSImage *image = [[NSImage alloc] initWithSize:NSZeroSize];
            [image setName:imageName];
        }
        [imageNames release];
        
		[self loadActions];
    }
    
    return self;
}

- (void) dealloc {
    [oldActionObjects release], oldActionObjects = nil;
    [actionIdentifiers release], actionIdentifiers = nil;
    [directObjectTypes release], directObjectTypes = nil;
    [directObjectFileTypes release], directObjectFileTypes = nil;
    
    [actionSources release], actionSources = nil;
    
    [actionRanking release], actionRanking = nil;
    [actionPrecedence release], actionPrecedence = nil;
    [actionActivation release], actionActivation = nil;
    [actionMenuActivation release], actionMenuActivation = nil;
    [actionIndirects release], actionIndirects = nil;
    [actionNames release], actionNames = nil;
    
	// [self writeCatalog:self];   
	[super dealloc];
}


- (void) loadActions {
	NSArray *elements = [QSReg elementsForPointID:@"com.blacktree.actions"];
    NSDictionary *actionDict;
	NSString *key;
	BElement *element;

    for (element in elements) { 
		NSBundle *bundle = [[element plugin] bundle];
		key = [element identifier];
		actionDict = [element plistContent];
		
		if ([[actionDict objectForKey:@"disabled"] boolValue])
            continue;
		
        //int feature=[[actionDict objectForKey:@"feature"] intValue];
		//if (feature > [NSApp featureLevel])
        //    continue;
		
		QSAction *action = [QSAction actionWithDictionary:actionDict identifier:key bundle:bundle];
		

		if ([[actionDict objectForKey:@"initialize"] boolValue] && [[action provider] respondsToSelector:@selector(initializeAction:)])
			action = [[action provider] initializeAction:action];
		
		if (action) {
			[self addAction:action];
			if (![bundle bundleIdentifier]) {
				QSLogError(@"could not find bundle for %@ %p %@", key, [element plugin], bundle);
			} else {
				[[self makeArrayForSource:[bundle bundleIdentifier]] addObject:action];
			}
		}
	}
	
	[self updateRanks];
}

//- (NSArray *) actionsForTypes:(NSArray *)types {
//	NSMutableSet *set = [NSMutableSet set];
//	NSEnumerator *e = [types objectEnumerator];
//	NSString *type;
//	while( ( type = [e nextObject] ) )
//		[set addObjectsFromArray:[directObjectTypes objectForKey:type]];
//	[set addObjectsFromArray:[directObjectTypes objectForKey:@"*"]];
//	return [set allObjects];
//}


- (void) loadFileActions {
	NSString *rootPath = QSApplicationSupportSubPath(@"Actions/", NO);
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *files = [manager directoryContentsAtPath:rootPath];
	
	//NSMutableArray *array = [NSMutableArray array];
	
	files = [rootPath performSelector:@selector(stringByAppendingPathComponent:) onObjectsInArray:files];
	
	//NSMutableArray *actions=[NSMutableArray array];
	NSEnumerator *e = [[QSReg loadedInstancesForPointID:@"QSFileActionCreators"] objectEnumerator];
	id <QSFileActionProvider> creator;

	while( ( creator = [e nextObject]) ) {
		[self addActions:[creator fileActionsFromPaths:files]];
	}
}

- (NSArray *) actionsForFileTypes:(NSArray *)types {
	NSMutableSet *set = [NSMutableSet set];
	NSString *type;
	for (type in types) {
		[set addObjectsFromArray:[directObjectFileTypes objectForKey:type]];
	}
	[set addObjectsFromArray:[directObjectFileTypes objectForKey:@"*"]];
	return [set allObjects];
}

- (NSArray *) actionsForTypes:(NSArray *)types fileTypes:(NSArray *)fileTypes {
	//QSLog(@"types %@ %@ %@", types, fileTypes, nil);
	NSMutableSet *set = [NSMutableSet set];
	NSString *type;
	for (type in types) {
		if ([type isEqualToString:QSFilePathType]){
			[set addObjectsFromArray:[self actionsForFileTypes:fileTypes]];
		} else {
			[set addObjectsFromArray:[directObjectTypes objectForKey:type]];
		}
	}
	[set addObjectsFromArray:[directObjectTypes objectForKey:@"*"]];
	return [set allObjects];
}
- (NSMutableArray *) actionsArrayForType:(NSString *)type {
	NSMutableArray *array = [directObjectTypes objectForKey:type];
	if (!array)
		[directObjectTypes setObject:(array = [NSMutableArray array]) forKey:type];
	return array;
}

- (NSMutableArray *) actionsArrayForFileType:(NSString *)type {
	NSMutableArray *array = [directObjectFileTypes objectForKey:type];
	if (!array)
		[directObjectFileTypes setObject:(array = [NSMutableArray array]) forKey:type];
	return array;
}

- (void) addActions:(NSArray *)actions {
    foreach (action, actions) {
		[self addAction:action];
	}
}

- (void) addAction:(QSAction *)action {
	NSDictionary *actionDict = [action actionDict];
	NSString *ident = [action identifier];
	if (!ident) {
		//	QSLog(@"aciton %@",actionDict);
		return;
	}

	NSString *altName = [actionNames objectForKey:ident];
	if (altName) [action setLabel:altName];
	//QSLog(@"aciton %@ %@", ident, actionNames);
	QSAction *dupAction = [actionIdentifiers objectForKey:ident];
	if (dupAction) {
		//QSLog(@"dup! %@",dupAction);
		[[directObjectTypes allValues] makeObjectsPerformSelector:@selector(removeObject:) withObject:dupAction];
		[[directObjectFileTypes allValues] makeObjectsPerformSelector:@selector(removeObject:) withObject:dupAction];
	}
	
	[actionIdentifiers setObject:action forKey:ident];
	
	NSNumber *activation = [actionActivation objectForKey:ident];
	if (!activation)
		activation = [action defaultEnabled];
	[action _setEnabled:(activation ? [activation boolValue] : YES)];
	
	activation = [actionMenuActivation objectForKey:ident];
	if (!activation)
		activation = [action defaultEnabled];
	[action _setMenuEnabled:(activation ? [activation boolValue] : YES)];	
	
	int index = [actionRanking indexOfObject:ident];
	
	if (index == NSNotFound) {
		float prec = [action precedence];
		int i;
		float otherPrec;
        
		for(i = 0; i < [actionRanking count]; i++) {
			otherPrec = [[actionPrecedence valueForKey:[actionRanking objectAtIndex:i]] floatValue];
			if (otherPrec < prec)
                break;
		}
        
		[actionRanking insertObject:ident atIndex:i];	
		[actionPrecedence setObject:[NSNumber numberWithFloat:prec] forKey:ident];
		[action setRank:i];
		
		QSLogDebug(@"inserting action %@ at %d (%f)", action, i, prec);
	} else {
		[action _setRank:index];
	}
	
	NSArray *directTypes = [actionDict objectForKey:@"directTypes"];
	if (![directTypes count])
        directTypes = [NSArray arrayWithObject:@"*"];
	NSEnumerator *e = [directTypes objectEnumerator];
	NSString *type;
    
	while ((type = [e nextObject]))
		[[self actionsArrayForType:type] addObject:action];
	
	if ([directTypes containsObject:QSFilePathType]) {
		directTypes = [actionDict objectForKey:@"directFileTypes"];
		if (![directTypes count])
            directTypes = [NSArray arrayWithObject:@"*"];
		for (type in directTypes) {
			//QSLog(@"type %@", type);
			[[self actionsArrayForFileType:type] addObject:action];
		}

		//QSLog(@"act %@ %@",action,directTypes);
	}
}

- (void) updateRanks {
	//QSLog(@"Reranking all");
	int i;
	for(i = 0; i < [actionRanking count]; i++) {
		[[actionIdentifiers objectForKey:[actionRanking objectAtIndex:i]] _setRank:i];	
	}
	[self writeActionsInfo];
}

- (void) insertAction:(QSAction *)action {
	
}

- (void) addActionsFromDictionary:(NSDictionary *)actionsDictionary bundle:(NSBundle *)bundle {
	NSEnumerator *e = [actionsDictionary keyEnumerator];
    NSDictionary *actionDict;
	NSString *key;
    while ((key = [e nextObject])) {
		actionDict = [actionsDictionary objectForKey:key];
		
		if ([[actionDict objectForKey:@"disabled"] boolValue])
            continue;
		//QSLog(@"action %@",actionDict);
		
        //int feature = [[actionDict objectForKey:@"feature"] intValue];
		//if (feature > [NSApp featureLevel]) continue;
		
		QSAction *action = [QSAction actionWithDictionary:actionDict identifier:key bundle:bundle];
		
		if ([[actionDict objectForKey:@"initialize"] boolValue] && [[action provider] respondsToSelector:@selector(initializeAction:)])
			action = [[action provider] initializeAction:action];
		
		if (action) {
			[self addAction:action];
			[[self makeArrayForSource:[bundle bundleIdentifier]] addObject:action];
		}
	} 	
}

- (NSMutableArray *) getArrayForSource:(NSString *)sourceid {
	NSMutableArray *array = [actionSources objectForKey:sourceid];
	return array;
}

- (NSMutableArray *) makeArrayForSource:(NSString *)sourceid {
	NSMutableArray *array = [actionSources objectForKey:sourceid];
	if (!array)
        [actionSources setObject:(array = [NSMutableArray array]) forKey:sourceid];
	return array;
}

//- (void) registerActions:(id)actionObject {
//    if (!actionObject) return;
//    [oldActionObjects addObject:actionObject];
//	[self performSelectorOnMainThread:@selector(loadActionsForObject:) withObject:actionObject waitUntilDone:YES];
//}

//- (void) loadActionsForObject:(id)actionObject {
//	NSEnumerator *actionEnumerator = [[actionObject actions] objectEnumerator];
//    id action;
//    while ((action = [actionEnumerator nextObject])) {
//		if([action identifier])
//            [actionIdentifiers setObject:action forKey:[action identifier]];
//    } 	
//}

- (NSArray *) actions {
	return [actionIdentifiers allValues];
}

- (QSAction *) actionForIdentifier:(NSString *)identifier {
    return [actionIdentifiers objectForKey:identifier];   
}

- (QSObject *) performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
    QSAction *actionObject = [actionIdentifiers objectForKey:action];
    if (!actionObject) {
        QSLog(@"Action not found: %@",action);
        return nil;
    }
    return [actionObject performOnDirectObject:dObject indirectObject:iObject];
}

- (NSArray *) rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject shouldBypass:(BOOL)bypass {
    NSString *type = [NSString stringWithFormat:@"QSActionMnemonic:%@",[dObject primaryType]];
	NSMutableArray *actions = nil;
	if ([[dObject handler] respondsToSelector:@selector(actionsForDirectObject:indirectObject:)])
		actions = (NSMutableArray *)[[dObject handler] actionsForDirectObject:dObject indirectObject:iObject];
	
	if ([dObject isKindOfClass:[QSRankedObject class]]) {
		dObject = [(QSRankedObject*)dObject object];
	}
    
	BOOL bypassValidation = (bypass
                             && [dObject isKindOfClass:[QSProxyObject class]]
                             && [(QSProxyObject*)dObject bypassValidation]);
    
	if (bypassValidation) {
		//QSLog(@"bypass? %@ %@",dObject,NSStringFromClass([dObject class]));
		actions = [[[actionIdentifiers allValues]mutableCopy]autorelease];
	}	

	if (!actions)
		actions = (NSMutableArray *)[self validActionsForDirectObject:dObject indirectObject:iObject];
	
	
	NSString *preferredActionID = [dObject objectForMeta:kQSObjectDefaultAction];
	
	id preferredAction = nil;
	if ([preferredActionID isEqualToString:@""])
		preferredAction = [NSNull null];
	else if (preferredActionID)
		preferredAction = [self actionForIdentifier:preferredActionID];
	
	//QSLog(@"prefer \"%@\"", preferredActionID);
	//QSLog(@"actions %d", [actions count]);
	if (1) {
		NSSortDescriptor *rankDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES] autorelease];
		[actions sortUsingDescriptors:[NSArray arrayWithObject:rankDescriptor]];	
	} else {		
		actions = [QSLib scoredArrayForString:type inSet:actions mnemonicsOnly:YES];
	}

	if (preferredAction)
		actions = [NSArray arrayWithObjects:preferredAction, actions, nil];
	
	return actions;
}

- (NSArray *) rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	return [self rankedActionsForDirectObject:dObject indirectObject:iObject shouldBypass:NO];
}

- (NSArray *) validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject fromSource:(id)aObject types:(NSSet *)dTypes fileType:(NSString *)fileType {
	if (dTypes) {
		NSMutableSet *aTypes = [NSMutableSet setWithArray:[aObject types]];
		
		if ([aTypes count]) {
			//QSLog(@"a, [%@]", aTypes);
			[aTypes intersectSet:dTypes];
            
			if (![aTypes count])
                return nil;
			if ([aTypes containsObject:QSFilePathType]
                && [aObject fileTypes]
                && ([aTypes count] == 1
                    || [[dObject primaryType]isEqualToString:QSFilePathType])) {
				if(![[aObject fileTypes] containsObject:fileType])
                    return nil; 
			}					
		}
	}
    
	NSArray *actions = nil;
	
	@try {
		actions = [aObject validActionsForDirectObject:dObject indirectObject:nil];
	}
    @catch (NSException *e) {
        NSLog(@"exception %@", e);  
    }
	
	return actions;
}

- (void)logActions {
	
}

- (NSArray *) validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	//QSLog(@"valid? %@", dObject);
    if (!dObject)
        return nil;
	
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:1];
	id aObject = nil;
	NSSet *types = [NSSet setWithArray:[dObject types]];
	NSString *fileType = [dObject singleFileType];
	
	NSMutableDictionary *validatedActionsBySource = [NSMutableDictionary dictionary];

	NSArray *validSourceActions;
	
	//for( i = 0; i < [oldActionObjects count]; i++ ) {
	//	aObject = [oldActionObjects objectAtIndex:i];
	//	validSourceActions = [self validActionsForDirectObject:dObject indirectObject:iObject fromSource:aObject types:types fileType:fileType];
	//	if (validSourceActions) {
	//		//[validatedActionsBySource setObject:validSourceActions forKey:NSStringFromClass([aObject class])];
	//		[actions addObjectsFromArray:validSourceActions];
	//	}
	//}
	//QSLog(@"oldActionObjects %@", oldActionObjects);

	//if (bypassValidation) QSLog(@"bypasssing validation");
    
	NSMutableArray *validActions = [[[actionIdentifiers objectsForKeys:actions notFoundMarker:[NSNull null]] mutableCopy] autorelease];
	[validActions removeObject:[NSNull null]];
	
	NSArray *newActions = [self actionsForTypes:[dObject types] fileTypes:(fileType ? [NSArray arrayWithObject:fileType] : nil)];
	
	QSAction *thisAction;
	BOOL isValid;
    
	for( thisAction in newActions) {
		if (![thisAction enabled]) continue;
		validSourceActions = nil;
		NSDictionary *actionDict = [thisAction actionDict];
		isValid = ![[actionDict objectForKey:@"validatesObjects"] boolValue];
		
		//QSLog(@"thisact %@", thisAction);
		
		if (!isValid) {
			validSourceActions = [validatedActionsBySource objectForKey:[actionDict objectForKey:@"actionClass"]];
			if (!validSourceActions) {
				aObject = [thisAction provider];
                
				validSourceActions = [self validActionsForDirectObject:dObject indirectObject:iObject fromSource:aObject types:nil fileType:nil];
				NSString *className = NSStringFromClass([aObject class]);

				if (className)
					[validatedActionsBySource setObject:(validSourceActions ? validSourceActions : [NSArray array]) forKey:className];
				
				if (validSourceActions) {
					[actions addObjectsFromArray:validSourceActions];
				}
			}
			
			isValid = [validSourceActions containsObject:[thisAction identifier]];
		}
		//if ([validSourceActions count])
		//	QSLog(@"Actions for %@:%@", thisAction, validSourceActions);
		
		
		if (isValid)
            [validActions addObject:thisAction];
	}
	
	//QSLog(@"Actions for %@:%@", [dObject name], validActions);
	if (![validActions count]) {
		QSLog(@"unable to find actions %@\r%@", oldActionObjects, actionIdentifiers);	
		QSLog(@"types %@ %@", types, fileType);
	}
	return validActions;
}

- (NSArray *) validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
    QSActionProvider *actionObject = [[actionIdentifiers objectForKey:action] objectForKey:kActionClass];
    //QSLog(@"actionobject %@", actionObject);
    return [actionObject validIndirectObjectsForAction:action directObject:dObject];
}

- (void) setAction:(QSAction *)action isEnabled:(BOOL)flag {
	if (VERBOSE) QSLog(@"set action %@ is enabled %d",action,flag);
	[actionActivation setObject:[NSNumber numberWithBool:flag] forKey:[action identifier]];
	[self writeActionsInfo];
}

- (void) setAction:(QSAction *)action isMenuEnabled:(BOOL)flag {
	if (VERBOSE) QSLog(@"set action %@ is menu enabled %d", action, flag);
	[actionMenuActivation setObject:[NSNumber numberWithBool:flag] forKey:[action identifier]];
	[self writeActionsInfo];
}

- (void) orderActions:(NSArray *)actions aboveActions:(NSArray *)lowerActions {
	int index = [[lowerActions valueForKeyPath:@"@min.rank"] intValue];
	if (VERBOSE) QSLog(@"Promote to %d",index);
	NSString *targetIdentifier = [actionRanking objectAtIndex:index];
	NSArray *identifiers = [actions valueForKey:@"identifier"];
    
	[actionRanking removeObjectsInArray:identifiers];
	index = [actionRanking indexOfObject:targetIdentifier];
	[actionRanking insertObjectsFromArray:identifiers atIndex:index];
    
	[self updateRanks];
}

- (void) orderActions:(NSArray *)actions belowActions:(NSArray *)higherActions {
	int index = [[higherActions valueForKeyPath:@"@max.rank"] intValue];
	//QSLog(@"demote to %d",index);
	NSString *targetIdentifier = [actionRanking objectAtIndex:index];
	NSArray *identifiers = [actions valueForKey:@"identifier"];
    
	[actionRanking removeObjectsInArray:identifiers];
	index = [actionRanking indexOfObject:targetIdentifier];
	[actionRanking insertObjectsFromArray:identifiers atIndex:index+1];
    
	[self updateRanks];
}

- (void) noteIndirect:(QSObject *)iObject forAction:(QSObject *)aObject {
	NSString *iIdent = [iObject identifier];
	if (!iIdent)
        return;
    
	NSString *aIdent = [aObject identifier];
	NSMutableArray *array;
    
	if (!(array =[actionIndirects objectForKey:aIdent]))
		[actionIndirects setObject:(array = [NSMutableArray array]) forKey:aIdent];
    
	[array removeObject:iIdent];
	[array insertObject:iIdent atIndex:0];
    
	if ([array count] > 15)
        [array removeObjectsInRange:NSMakeRange(15, [array count] - 15)];
	[self performSelector:@selector(writeActionsInfoNow) withObject:nil afterDelay:5.0 extend:YES];
}

- (void) noteNewName:(NSString *)name forAction:(QSObject *)aObject {
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
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:actionPrecedence forKey:@"actionPrecedence"];
	[dict setObject:actionRanking forKey:@"actionRanking"];
	[dict setObject:actionActivation forKey:@"actionActivation"];
	[dict setObject:actionMenuActivation forKey:@"actionMenuActivation"];
	
	[dict setObject:actionIndirects forKey:@"actionIndirects"];
	[dict setObject:actionNames forKey:@"actionNames"];
	
	[dict writeToFile:pQSActionsLocation atomically:YES];
	if (VERBOSE) QSLog(@"Wrote Actions Info");
}
@end

@implementation QSExecutor (QSPlugInInfo)
- (BOOL) handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	if (info) {
		[self addActionsFromDictionary:info bundle:bundle];
	} else {
		//		NSDictionary *providers=[[[plugin bundle] dictionaryForFileOrPlistKey:@"QSRegistration"]objectForKey:@"QSActionProviders"];
		//		if (providers){
		//				[self loadOldActionProviders:[providers allValues]];
		//		} 					   
	}
	return YES;
}
@end
