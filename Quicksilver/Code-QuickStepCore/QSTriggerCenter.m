#import "QSTriggerCenter.h"

#import "QSLibrarian.h"
#import "QSAction.h"

#import "QSRegistry.h"

#import "QSTrigger.h"
#import "QSObject.h"
#import "QSCommand.h"

@implementation QSTriggerCenter

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"triggers"]) {
        keyPaths = [keyPaths setByAddingObject:@"triggersDict"];
    }
    return keyPaths;
}

+ (id)sharedInstance {
	static QSTriggerCenter *_sharedInstance = nil;
	if (!_sharedInstance) {
		_sharedInstance = [[[self class] allocWithZone:nil] init];
	}
	return _sharedInstance;
}

- (id)init {
	if (self = [super init]) {

		triggers = [[NSMutableArray alloc] init];
		triggersDict = [[NSMutableDictionary alloc] init];
		
		[self loadTriggers];
		
		// Add observers to handle scopes
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(appChanged:)
				   name:QSActiveApplicationChanged
				 object:nil];
		
		/* tiennou: Those look unused. If they aren't, change them to extern NSStrings */
		[nc addObserver:self
			   selector:@selector(interfaceActivated)
				   name:@"InterfaceActivated"
				 object:nil];

		[nc addObserver:self
			   selector:@selector(interfaceDeactivated)
				   name:@"InterfaceDeactivated"
				 object:nil];
	}
	return self;
}

- (void)dealloc {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:QSActiveApplicationChanged object:nil];
	[nc removeObserver:self name:@"InterfaceActivated" object:nil];
	[nc removeObserver:self name:@"InterfaceDeactivated" object:nil];
	triggers = nil;
	triggersDict = nil;
}

- (void)loadTriggers {
    @try {
        triggersDict = [NSKeyedUnarchiver unarchiveObjectWithFile:pTriggerSettings];
    }
    @catch (NSException *exception) {
        // Old method
        NSDictionary *triggerStorageDict = [NSDictionary dictionaryWithContentsOfFile: [pTriggerSettings stringByStandardizingPath]];
        
        NSArray *triggerStorage = [triggerStorageDict objectForKey:@"triggers"];
        if ([triggerStorage count] != 0) {
            NSArray *ids = [triggerStorage valueForKey:kItemID];
            
            NSMutableArray *triggersWithInfo = [[NSMutableArray alloc] init];
            [triggerStorage enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [triggersWithInfo addObject:[QSTrigger triggerWithInfo:obj]];
            }];
            
            [triggers addObjectsFromArray:triggersWithInfo];
            triggersDict = [[NSMutableDictionary alloc] initWithObjects:triggers forKeys:ids];
        }
    }
}

// Method to set the scope when the QS UI is activated
- (void)interfaceActivated {
	NSArray *theTriggers = [triggersDict allValues];
	[theTriggers makeObjectsPerformSelector:@selector(rescope:) withObject:kQSBundleID];
}

// Method to set the scope when the QS UI is deactivated
- (void)interfaceDeactivated {
	NSArray *theTriggers = [triggersDict allValues];
	[theTriggers makeObjectsPerformSelector:@selector(rescope:) withObject:
	 [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"]];
}

// Method that listens for app changes (other than QS) and notifies the trigger scope method
- (void)appChanged:(NSNotification *)notif {
	NSArray *theTriggers = [triggersDict allValues];
	NSString *ident = [[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
	[theTriggers makeObjectsPerformSelector:@selector(rescope:) withObject:ident];
}

- (void)activateTriggers {
	[[triggersDict allValues] makeObjectsPerformSelector:@selector(reactivate)];
}

- (BOOL)executeTriggerID:(NSString *)triggerID {
	return [self executeTrigger:[triggersDict objectForKey:triggerID]];}

- (QSTrigger *)triggerWithID:(NSString *)ident {
	return [triggersDict objectForKey:ident];
}

- (NSArray *)triggersWithIDs:(NSArray *)idents {
    if (!idents || ![idents count]) {
        return nil;
    }
    NSMutableArray *tempTriggers = [[NSMutableArray alloc] initWithCapacity:[idents count]];
    for (NSString *ident in idents) {
        QSTrigger *trigger = [self triggerWithID:ident];
        if (trigger) {
            [tempTriggers addObject:trigger];
        }
    }
    NSArray *returnTriggers = [NSArray arrayWithArray:tempTriggers];
    return returnTriggers;
}

- (NSArray *)triggersWithParentID:(NSString *)ident {
	NSMutableArray *array = [NSMutableArray array];
	foreachkey(key, trigger, triggersDict) {
		if ([[trigger parentID] isEqualToString:ident])
			[array addObject:trigger];
	}
	return array;
}

- (BOOL)executeTrigger:(QSTrigger *)trigger {
	/* tiennou: This short-circuits QSTrigger -execute */
	[[trigger command] executeIgnoringModifiers];
	return YES;
}

- (void)addTrigger:(QSTrigger *)trigger {
	[self willChangeValueForKey:@"triggersDict"];
	[triggersDict setObject:trigger forKey:[trigger objectForKey:kItemID]];
	/* tiennou: move all calls to writeTrigger in an observation context */
	[self didChangeValueForKey:@"triggersDict"];
	[self writeTriggers];
}

- (void)removeTrigger:(QSTrigger *)trigger {
	[self willChangeValueForKey:@"triggersDict"];
	[trigger setEnabled:NO];
	[triggersDict removeObjectForKey:[trigger identifier]];
	[self didChangeValueForKey:@"triggersDict"];
	[self writeTriggers];
}

- (void)triggerChanged:(QSTrigger *)trigger {
	[self writeTriggers];

    // Fix for issue 47
    // Handle case for when a keyboard assignment is added to
    // a trigger for the first time.  By default when a trigger is
    // added it does not have a key assignment.  This call ensures
    // that when a key is assigned the trigger is properly
    // setup.  Otherwise the user has to toggle the enable/disable
    // check box to get the trigger to work.
    [trigger setEnabledDoNotNotify:[trigger enabled]];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSTriggerChangedNotification object:trigger];
}

// When multiple 'writeTriggers' messages are sent in a short period of time, this method intends to reduce the work (creating .plists and writing)
// so it is only performed once.
- (void)writeTriggers {
    [self performSelector:@selector(writeTriggersNow) withObject:nil afterDelay:2.0 extend:YES];
}

- (void)writeTriggersNow {
#ifdef DEBUG
	NSLog(@"writing triggers");
#endif
    [NSKeyedArchiver archiveRootObject:[self triggersDict] toFile:pTriggerSettings];
}

- (NSMutableDictionary *)triggersDict {
	return triggersDict;
}

- (void)setTriggersDict:(NSMutableDictionary *)newTriggersDict {
	triggersDict = newTriggersDict;
}

- (NSArray *)triggers { return [triggersDict allValues]; }

- (NSDictionary *)triggerManagers {
	return [QSReg instancesForTable:@"QSTriggerManagers"];
}
@end

@implementation QSTriggerCenter (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	id matchEntry = nil;
	for(__strong NSDictionary * value in info) {
		NSString *iden = [value objectForKey:kItemID];
		//NSLog(@"info %@ %@", iden, value);
		if (matchEntry = [triggersDict objectForKey:iden]) {
			[[matchEntry info] addEntriesFromDictionary:value];
			[[matchEntry info] removeObjectForKey:@"defaults"];
		} else if (iden) {
			NSMutableDictionary *defaults = [[value objectForKey:@"defaults"] mutableCopy];
			if (defaults) {
				[defaults removeObjectsForKeys:[value allKeys]];
				value = [value mutableCopy];
				[(NSMutableDictionary *)value addEntriesFromDictionary:defaults];
			}
			//NSLog(@"create %@, %@", value, [QSTrigger triggerWithInfo:value]);
			[triggersDict setObject:[QSTrigger triggerWithDictionary:value] forKey:iden];
		}
		//NSLog(@"info %@ %@ %@", info, matchEntry, triggersDict);
	}
	return YES;
}
@end
