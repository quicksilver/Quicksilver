#import "QSTriggerCenter.h"

#import "QSLibrarian.h"
#import "QSAction.h"

#import "QSRegistry.h"

#import "QSTrigger.h"
#import "QSObject.h"
#import "QSCommand.h"

@implementation QSTriggerCenter

+ (id)sharedInstance {
	static QSTriggerCenter *_sharedInstance = nil;
	if (!_sharedInstance) {
		_sharedInstance = [[[self class] allocWithZone:[self zone]] init];
	}
	return _sharedInstance;
}

- (id)init {
	if (self = [super init]) {

		NSDictionary *triggerStorage = [NSDictionary dictionaryWithContentsOfFile: [pTriggerSettings stringByStandardizingPath]];

		triggers = [triggerStorage objectForKey:@"triggers"];
        if([triggers count] != 0 ) {
            NSArray *ids = [triggers valueForKey:kItemID];
            triggers = [QSTrigger performSelector:@selector(triggerWithInfo:) onObjectsInArray:triggers returnValues:YES];
            triggersDict = [[NSMutableDictionary dictionaryWithObjects:triggers forKeys:ids] retain];
        }

		if (!triggersDict) triggersDict = [[NSMutableDictionary dictionary] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(appChanged:)
													name:QSActiveApplicationChanged
												 object:nil];
	}
	return self;
}

- (void)appChanged:(NSNotification *)notif {
	//NSLog(@"app %@", [[notif object] objectForKey:@"NSApplicationBundleIdentifier"]);

	NSArray *theTriggers = [triggersDict allValues];
	NSString *ident = [[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
	[theTriggers makeObjectsPerformSelector:@selector(rescope:) withObject:ident];
}

- (void)activateTriggers {
	[[triggersDict allValues] makeObjectsPerformSelector:@selector(reactivate)];
}

#if 0
- (void)disableInterfaceTriggers {}
#endif

- (BOOL)executeTriggerID:(NSString *)triggerID {
	return [self executeTrigger:[triggersDict objectForKey:triggerID]];}

- (QSTrigger *)triggerWithID:(NSString *)ident {
	return [triggersDict objectForKey:ident];
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
	// NSLog(@"Triggered Command: %@", [self commandForTrigger:trigger]);
	[[trigger command] executeIgnoringModifiers];
	return YES;
}

- (void)addTrigger:(QSTrigger *)trigger {
	[triggersDict setObject:trigger forKey:[trigger objectForKey:kItemID]];
	[self writeTriggers];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSTriggerChangedNotification object:trigger];
}

- (void)removeTrigger:(QSTrigger *)trigger {
	[trigger setEnabled:NO];
	[triggersDict removeObjectsForKeys:[triggersDict allKeysForObject:trigger]];
	[self writeTriggers];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSTriggerChangedNotification object:trigger];
}
/*
 - (void)addTriggerForCommand:(QSCommand *)command {
	 [[[QSTriggerEditor sharedInstance] window] orderFront:nil];
	 [[QSTriggerEditor sharedInstance] addTrigger:nil];
	 return;

	 [self enableCaptureMode];
	 // NSEvent *theEvent=
	 [NSApp nextEventMatchingMask:NSKeyDownMask | NSLeftMouseDownMask untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0] inMode:NSDefaultRunLoopMode dequeue:YES];
	 [self disableCaptureMode];
	 // NSLog(@"%@", theEvent);

 }
 */
//- (id)managerForTrigger:(NSDictionary *)entry {
//	return [QSReg instanceForKey:[entry objectForKey:@"type"] inTable:QSTriggerManagers];
//}
//-(BOOL)enableTrigger:(NSDictionary *)entry {
//	if (![[entry objectForKey:@"enabled"] boolValue]) return NO;
//	return [[self managerForTrigger:entry] enableTrigger:entry];
//}
//-(BOOL)disableTrigger:(NSDictionary *)entry {
//	return [[self managerForTrigger:entry] disableTrigger:entry];
//}

- (void)triggerChanged:(QSTrigger *)trigger {
	[self writeTriggers];

    // !!!:paulkohut:20100311
    // Fix for issue 47
    // Handle case for when a keyboard assignment is added to
    // a trigger for the first time.  By default when a trigger is
    // added it does not have a key assignment.  This call ensures
    // the when a key is assigned the trigger is properly
    // setup.  Otherwise the user has to toggle the enable/disable
    // check box to get the trigger to work.
    [trigger setEnabledDoNotNotify:[trigger enabled]];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSTriggerChangedNotification object:trigger];
}
//+ (NSString *)nameForTrigger:(NSDictionary *)trigger {
//	NSString *name = [trigger objectForKey:@"name"];
//	if (!name) {
//		QSCommand *command = [QSTriggerCenter commandForTrigger:trigger];
//		name = [command description];
//	}
//	return name;
//}

//
//- (NSString *)nameForTrigger:(NSDictionary *)trigger {
//	return [QSTriggerCenter nameForTrigger:trigger];
//}

//
//- (void)setName:(NSString *)name forTrigger:(NSMutableDictionary *)trigger {
//if (name)
//	[trigger setObject:name forKey:@"name"];
//	else
//		[trigger removeObjectForKey:@"name"];
//}

- (void)writeTriggers {
    [self performSelector:@selector(writeTriggersNow) withObject:nil afterDelay:10.0 extend:YES];
}

- (void)writeTriggersNow {
	NSMutableArray *cleanedTriggerArray = [NSMutableArray arrayWithCapacity:[triggersDict count]];
	for(QSTrigger *thisTrigger in [triggersDict allValues]) {
        NSDictionary * rep = [thisTrigger dictionaryRepresentation];
#ifdef DEBUG
            NSArray *plistTypes = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSPropertyListXMLFormat_v1_0],
                                                            [NSNumber numberWithUnsignedInt:NSPropertyListBinaryFormat_v1_0],
/*                                                          [NSNumber numberWithUnsignedInt:NSPropertyListOpenStepFormat],
 * Because it fails most writing */
                                                            nil];
            int failCount = 0;
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
    NSString *errorStr;
    NSError *error;
    NSMutableDictionary * triggerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:cleanedTriggerArray, @"triggers", nil];
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:triggerDict
                                                              format:NSPropertyListXMLFormat_v1_0
                                                    errorDescription:&errorStr];
    if(data == nil ) {
        NSLog(@"Failed converting triggers: %@", errorStr);
        return;
    }
    if([data writeToFile:[pTriggerSettings stringByStandardizingPath]
                 options:0
                   error:&error] == NO ) {
        NSLog(@"Failed writing triggers : %@", error );
        return;
    }
#ifdef DEBUG
    if (VERBOSE) NSLog(@"Wrote %d triggers", [cleanedTriggerArray count]);
#endif
}

- (NSMutableDictionary *)triggersDict {
	return triggersDict;
}

- (void)setTriggersDict:(NSMutableDictionary *)newTriggersDict {
	[triggersDict release];
	triggersDict = [newTriggersDict retain];
}

- (NSMutableArray *)triggers { return [[[triggersDict allValues] mutableCopy] autorelease];  }

	//@end

	//@implementation QSTriggerCenter (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	id matchEntry = nil;
	for(NSDictionary * value in info) {
		NSString *iden = [value objectForKey:kItemID];
		//NSLog(@"info %@ %@", iden, value);
		if (matchEntry = [triggersDict objectForKey:iden]) {
			[[matchEntry info] addEntriesFromDictionary:value];
			[[matchEntry info] removeObjectForKey:@"defaults"];
		} else if (iden) {
			NSMutableDictionary *defaults = [[[value objectForKey:@"defaults"] mutableCopy] autorelease];
			if (defaults) {
				[defaults removeObjectsForKeys:[value allKeys]];
				value = [[value mutableCopy] autorelease];
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
