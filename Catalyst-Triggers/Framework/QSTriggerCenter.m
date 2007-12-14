

#import "QSTriggerCenter.h"

//#import "QSLibrarian.h"
//#import "QSAction.h"
//
//
//
#import "QSTrigger.h"

//#import "QSTriggersPrefPane.h"
#define pTriggerSettings	@"~/Library/Application Support/Quicksilver/Triggers.plist"

@implementation QSTriggerCenter

+ (id)sharedInstance{
    static QSTriggerCenter *_sharedInstance = nil;
    if (!_sharedInstance){
        _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    }
    return _sharedInstance;
}

- (id) init{
    if (self=[super init]){
		
        NSDictionary *triggerStorage=[NSDictionary dictionaryWithContentsOfFile: [pTriggerSettings stringByStandardizingPath]];
      NSLog(@"storage %@",triggerStorage);
        triggers=[triggerStorage objectForKey:@"triggers"];
		NSArray *ids=[triggers valueForKey:kItemID];
		triggers=[QSTrigger performSelector:@selector(triggerWithInfo:) onObjectsInArray:triggers returnValues:YES];
        triggersDict=[[NSMutableDictionary dictionaryWithObjects:triggers forKeys:ids]retain];
		
     NSMutableDictionary *triggerDict;
        NSEnumerator *triggerEnum=[triggers objectEnumerator];
        while (triggerDict=[triggerEnum nextObject]){
            [triggerDict setObject:[QSCommand commandWithDictionary:[triggerDict objectForKey:@"command"]] forKey:@"command"];
            
            [self enableTrigger:triggerDict];

        }
		if (!triggersDict) triggersDict=[[NSMutableDictionary dictionary]retain];
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(appChanged:)
													name:@"QSActiveApplicationChanged"
												  object:nil];
    }
    return self;
} 





- (void)appChanged:(NSNotificationCenter *)notif{
	//QSLog(@"app  %@",[[notif object] objectForKey:@"NSApplicationBundleIdentifier"]);	
	
	NSArray *triggers=[triggersDict allValues];	
	NSString *ident=[[notif object] objectForKey:@"NSApplicationBundleIdentifier"];
	[triggers makeObjectsPerformSelector:@selector(rescope:) withObject:ident];
}
- (void)activateTriggers{
	[[triggersDict allValues] makeObjectsPerformSelector:@selector(tryToActivate)];
}


- (void)disableInterfaceTriggers{
	
}

-(BOOL)executeTriggerID:(NSString *)triggerID{
	return [self executeTrigger:[triggersDict objectForKey:triggerID]];}

- (QSTrigger *)triggerWithID:(NSString *)ident{
	return [triggersDict objectForKey:ident];
}
- (NSArray *)triggersWithParentID:(NSString *)ident{
	NSMutableArray *array=[NSMutableArray array];
	foreachkey(key,trigger,triggersDict){
		if ([[trigger parentID]isEqualToString:ident])
			[array addObject:trigger];
	}
	return array;
}
-(BOOL)executeTrigger:(QSTrigger *)trigger{
	//  QSLog(@"Triggered Command:  %@",[self commandForTrigger:trigger]);
    [[trigger command]executeIgnoringModifiers];
    return YES;
}

- (void)addTrigger:(QSTrigger *)trigger{
    [triggersDict setObject:trigger forKey:[trigger objectForKey:kItemID]];
    [self writeTriggers];
	
	[[NSNotificationCenter defaultCenter]postNotificationName:QSTriggerChangedNotification object:trigger];
}

- (void)removeTrigger:(QSTrigger *)trigger{
    [trigger setEnabled:NO];
    [triggersDict removeObjectsForKeys:[triggersDict allKeysForObject:trigger]];
    [self writeTriggers];
	
	[[NSNotificationCenter defaultCenter]postNotificationName:QSTriggerChangedNotification object:trigger];
}
/*
 - (void)addTriggerForCommand:(QSCommand *)command{
	 [[[QSTriggerEditor sharedInstance]window]orderFront:nil];
	 [[QSTriggerEditor sharedInstance]addTrigger:nil];
	 return;
	 
	 [self enableCaptureMode];
	 // NSEvent *theEvent=
	 [NSApp nextEventMatchingMask:NSKeyDownMask|NSLeftMouseDownMask untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0] inMode:NSDefaultRunLoopMode dequeue:YES];
	 [self disableCaptureMode]; 
	 // QSLog(@"%@",theEvent);
	 
 }
 */
//- (id)managerForTrigger:(NSDictionary *)entry{
//	return [QSReg instanceForKey:[entry objectForKey:@"type"] inTable:QSTriggerManagers];
//}
//-(BOOL)enableTrigger:(NSDictionary *)entry{
//    if (![[entry objectForKey:@"enabled"]boolValue])return NO;
//	return [[self managerForTrigger:entry] enableTrigger:entry];
//}
//-(BOOL)disableTrigger:(NSDictionary *)entry{
//	return [[self managerForTrigger:entry] disableTrigger:entry];
//}


- (void)triggerChanged:(QSTrigger *)trigger{
    [trigger reactivate];
    [self writeTriggers];    
	[[NSNotificationCenter defaultCenter]postNotificationName:QSTriggerChangedNotification object:trigger];
}
//+ (NSString *)nameForTrigger:(NSDictionary *)trigger{
//	NSString *name=[trigger objectForKey:@"name"];
//	if (!name){
//		QSCommand *command=[QSTriggerCenter commandForTrigger:trigger];
//		name=[command description];
//	}
//	return name;	
//}

//
//- (NSString *)nameForTrigger:(NSDictionary *)trigger{
//	return [QSTriggerCenter nameForTrigger:trigger];
//}

//
//- (void)setName:(NSString *)name forTrigger:(NSMutableDictionary *)trigger{
//if (name)
//	[trigger setObject:name forKey:@"name"];
//	else
//		[trigger removeObjectForKey:@"name"];
//}


- (void)writeTriggers{

    //  NSArray alloc]initWithArray:copyItems:YES]
    NSMutableArray *cleanedTriggerArray=[NSMutableArray arrayWithCapacity:[triggersDict count]];
    NSEnumerator *triggerEnum;
    QSTrigger *thisTrigger;
    triggerEnum=[[triggersDict allValues]objectEnumerator];
    while(thisTrigger=[triggerEnum nextObject]){
		//if ([thisTrigger objectForKey:@"command"])
		// [thisTrigger setObject:[[thisTrigger objectForKey:@"command"]dictionaryRepresentation]forKey:@"command"];
        [cleanedTriggerArray addObject:[thisTrigger dictionaryRepresentation]];
    }
    //  QSLog(@"%@---%@",errorStr,data);    
    //  [[triggersDict allValues]descriptionForLocale:nil];
    [[NSDictionary dictionaryWithObjectsAndKeys:cleanedTriggerArray,@"triggers",nil]
writeToFile:[pTriggerSettings stringByStandardizingPath] atomically:YES];
	if (VERBOSE)QSLog(@"Writing %d triggers",[cleanedTriggerArray count]);
	//   QSLog(@"savedTriggers");
    
}


- (NSMutableDictionary *)triggersDict {
	//	QSLog(@"dict %@",triggersDict);
	return triggersDict;
}

- (void)setTriggersDict:(NSMutableDictionary *)newTriggersDict {
    [triggersDict release];
    triggersDict = [newTriggersDict retain];
}


- (NSMutableArray *)triggers { return [[[triggersDict allValues]mutableCopy]autorelease]; }

	//@end

	//@implementation QSTriggerCenter (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle{
	id matchEntry=nil;
	foreach(value,info){
		NSString *iden=[value objectForKey:kItemID];
		//QSLog(@"info %@ %@",iden,value);
		if (matchEntry=[triggersDict objectForKey:iden]){
			[[matchEntry info]addEntriesFromDictionary:value];
			[[matchEntry info]removeObjectForKey:@"defaults"];
		}else if (iden){
			NSMutableDictionary *defaults=[[[value objectForKey:@"defaults"]mutableCopy]autorelease];
			if (defaults){
				[defaults removeObjectsForKeys:[value allKeys]];
				value=[[value mutableCopy]autorelease];
				[(NSMutableDictionary *)value addEntriesFromDictionary:defaults];
			}
			//QSLog(@"create %@, %@",value,[QSTrigger triggerWithInfo:value]);
			[triggersDict setObject:[QSTrigger triggerWithInfo:value] forKey:iden];
		}		
		//QSLog(@"info %@ %@ %@",info,matchEntry,triggersDict);
	}
	return YES;
}
@end
