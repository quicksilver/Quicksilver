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
				   name:QSInterfaceActivatedNotification
				 object:nil];

		[nc addObserver:self
			   selector:@selector(interfaceDeactivated)
				   name:QSInterfaceDeactivatedNotification
				 object:nil];
	}
	return self;
}

- (void)dealloc {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:QSActiveApplicationChanged object:nil];
	[nc removeObserver:self name:QSInterfaceActivatedNotification object:nil];
	[nc removeObserver:self name:QSInterfaceDeactivatedNotification object:nil];
	triggers = nil;
	triggersDict = nil;
}

- (void)loadTriggers {
	NSDictionary *triggerStorageDict = [NSDictionary dictionaryWithContentsOfFile: [pTriggerSettings stringByStandardizingPath]];

	NSArray *triggerStorage = [triggerStorageDict objectForKey:@"triggers"];
	if ([triggerStorage count] != 0) {
		NSArray *ids = [triggerStorage valueForKey:kItemID];
        
        NSMutableArray *triggersWithInfo = [[NSMutableArray alloc] initWithCapacity:[ids count]];
        [triggerStorage enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [triggersWithInfo addObject:[QSTrigger triggerWithInfo:obj]];
        }];
        
		[triggers addObjectsFromArray:triggersWithInfo];
		triggersDict = [[NSMutableDictionary alloc] initWithObjects:triggers forKeys:ids];
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
	 [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier]];
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
    return [trigger execute];
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
	NSMutableArray *cleanedTriggerArray = [[NSMutableArray alloc] initWithCapacity:[triggersDict count]];
	for(QSTrigger *thisTrigger in [triggersDict allValues]) {
        NSDictionary * rep = [thisTrigger dictionaryRepresentation];
#ifdef DEBUG
            NSArray *plistTypes = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSPropertyListXMLFormat_v1_0],
                                                            [NSNumber numberWithUnsignedInt:NSPropertyListBinaryFormat_v1_0],
/*                                                          [NSNumber numberWithUnsignedInt:NSPropertyListOpenStepFormat],
 * Because it fails most writing */
                                                            nil];
            NSUInteger failCount = 0;
            for(NSNumber *num in plistTypes ) {
                int plistType = [num unsignedIntValue];
                BOOL valid = [NSPropertyListSerialization propertyList:rep isValidForFormat:plistType];
                if(!valid) {
                    NSLog(@"trigger representation %@ for format %@ : (%@)", ( valid ? @"valid" : @"invalid" ),
                          (plistType == NSPropertyListXMLFormat_v1_0 ? @"XML" :
                           (plistType == NSPropertyListBinaryFormat_v1_0 ? @"Binary" :
                            (plistType == NSPropertyListOpenStepFormat ? @"OpenStep" :
                             @"Unknown" ))),
                          rep);
                    failCount++;
                }
//            NSLog(@"types: %d, failed: %d", [plistTypes count], failCount);
                if(failCount == [plistTypes count]) {
                    NSLog(@"Utterly failed to output %@", rep);
                }
            }
#endif
		[cleanedTriggerArray addObject:rep];
	}

    NSError *error;
    NSDictionary * triggerDict = [[NSDictionary alloc] initWithObjectsAndKeys:cleanedTriggerArray, @"triggers", nil];
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:triggerDict
															  format:NSPropertyListXMLFormat_v1_0
															 options:0
															   error:&error];
    if(data == nil) {
        NSLog(@"Failed converting triggers: %@", error);
        return;
    }
    
	if (![data writeToFile:[pTriggerSettings stringByStandardizingPath] options:0 error:&error]) {
        NSLog(@"Failed writing triggers : %@", error );
        return;
    }
	
#ifdef DEBUG
    NSLog(@"Wrote %ld triggers", (long)[cleanedTriggerArray count]);
#endif
	
	// manual memory management (better for ARC)
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
	for (NSDictionary *triggerDict in info) {
		NSString *iden = triggerDict[kItemID];
        QSTrigger *matchEntry = self.triggersDict[iden];
		if (matchEntry) {
            /* We found that trigger.
             * Update the trigger's info dictionary with the new values
             * and remove its defaults.
             */
			[[matchEntry info] addEntriesFromDictionary:triggerDict];
			[[matchEntry info] removeObjectForKey:@"defaults"];
		} else if (iden) {
            /* No trigger known with that ID.
             * Make ourselves a copy, take the values under @"default" specified
             * in triggerDict, remove those values from the final dict, and add
             * them back at the root of the new trigger dict.
             */
#warning should the @"defaults" key be removed like the above did ?
            NSMutableDictionary *newTriggerDict = [triggerDict mutableCopy];
			NSMutableDictionary *defaults = newTriggerDict[@"defaults"];
			if (defaults) {
				[defaults removeObjectsForKeys:[newTriggerDict allKeys]];
				[newTriggerDict addEntriesFromDictionary:defaults];
			}
			[triggersDict setObject:[QSTrigger triggerWithDictionary:newTriggerDict] forKey:iden];
		}
	}
	return YES;
}
@end
