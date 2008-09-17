#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDProcess.h"
#import "NDProcess+QSMods.h"

#import "QSProcessMonitor.h"
#import "QSTypes.h"

#import "NSEvent+BLTRExtensions.h"
@interface QSProcessMonitor (QSInternal)
- (NSDictionary *)infoForPSN:(ProcessSerialNumber)processSerialNumber;
@end

OSStatus GetPSNForAppInfo(ProcessSerialNumber *psn, NSDictionary *theApp) {
	if (!theApp) return 1;
	(*psn) .highLongOfPSN = [[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
	(*psn) .lowLongOfPSN = [[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
	return noErr;
}

OSStatus appChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ProcessSerialNumber psn;
    OSStatus result;
    result = GetEventParameter(theEvent,
                               kEventParamProcessID,
                               typeProcessSerialNumber, NULL,
                               sizeof(psn), NULL, 
                               &psn );
    if( result == noErr ) {
        NSDictionary *dict = [(QSProcessMonitor*)userData infoForPSN:psn];
        [[NSNotificationCenter defaultCenter] postNotificationName:QSActiveApplicationChanged object:userData userInfo:dict];
    } else {
        NSLog(@"Unable to get event parameter kEventParamProcessID");
    }
	return CallNextEventHandler(nextHandler, theEvent);
}

@implementation QSProcessMonitor
+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[self allocWithZone:[self zone]] init];
	return _sharedInstance;
}

+ (NSArray *)processes {
	NSMutableArray *resultsArray = [NSMutableArray array];
	OSErr resultCode = noErr;
	ProcessSerialNumber serialNumber;
	ProcessInfoRec			 procInfo;
	FSSpec			 appFSSpec;

	Str255							 procName;
	serialNumber.highLongOfPSN = kNoProcess;
	serialNumber.lowLongOfPSN = kNoProcess;

	procInfo.processInfoLength			 = sizeof(ProcessInfoRec);
	procInfo.processName					 = procName;
	procInfo.processAppSpec			 = &appFSSpec;
//	procInfo.processAppSpec			 = &appFSSpec;

	while (procNotFound != (resultCode = GetNextProcess(&serialNumber) )) {
		if (noErr == (resultCode = GetProcessInformation(&serialNumber, &procInfo) )) {
			if ('\0' == procName[1])
				procName[1] = '0';
            NSString *processName = (NSString*)CFStringCreateWithPascalString(NULL, procInfo.processName, kCFStringEncodingUTF8);
			[resultsArray addObject:processName];
            [processName release];
		}
	}
	return resultsArray;
}

- (void)registerForAppChangeNotifications {
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassApplication;
	eventType.eventKind = kEventAppFrontSwitched;
	EventHandlerUPP handlerFunction = NewEventHandlerUPP(appChanged);
	OSStatus err = InstallApplicationEventHandler(handlerFunction, 1, &eventType, self, &eventHandler);
	if (err)
        NSLog(@"gmod registration err %d", err);
}

- (id)init {
	if (self = [super init]) {
		[self registerForAppChangeNotifications];
		processes = [[NSMutableArray arrayWithCapacity:1] retain];

		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object: nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLaunched:) name:QSActiveApplicationChanged object: nil];
    }
	return self;
}

- (void)dealloc {
    OSStatus err = RemoveEventHandler(eventHandler);
    if(err)
        NSLog(@"error %d removing handler", err);
	[self setCurrentApplication:nil];
	[self setPreviousApplication:nil];
	[super dealloc];
}

- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn {
	NSEnumerator *processEnumerator = [processes objectEnumerator];
	QSObject *thisProcess;
	ProcessSerialNumber thisPSN;
	Boolean match;

	while(thisProcess = [processEnumerator nextObject]) {
		NSDictionary *info = [thisProcess objectForType:QSProcessType];
		GetPSNForAppInfo(&thisPSN, info);
		SameProcess(&psn, &thisPSN, &match);
		if (match) return thisProcess;
	}
	return nil;
}

- (NSDictionary *)infoForPSN:(ProcessSerialNumber)processSerialNumber {
    NSDictionary *dict = (NSDictionary *)ProcessInformationCopyDictionary(&processSerialNumber, kProcessDictionaryIncludeAllInformationMask);
    dict = [[[dict autorelease] mutableCopy] autorelease];
    
    [dict setValue:[dict objectForKey:@"CFBundleName"]
            forKey:@"NSApplicationName"];
    
    [dict setValue:[dict objectForKey:@"BundlePath"]
            forKey:@"NSApplicationPath"];
    
    [dict setValue:[dict objectForKey:@"CFBundleIdentifier"]
            forKey:@"NSApplicationBundleIdentifier"];
    
    [dict setValue:[dict objectForKey:@"pid"]
            forKey:@"NSApplicationProcessIdentifier"];
    
    [dict setValue:[NSNumber numberWithLong:processSerialNumber.highLongOfPSN]
            forKey:@"NSApplicationProcessSerialNumberHigh"];
    
    [dict setValue:[NSNumber numberWithLong:processSerialNumber.lowLongOfPSN]
            forKey:@"NSApplicationProcessSerialNumberLow"];
    
	return dict;
}

- (BOOL)handleProcessEvent:(NSEvent *)theEvent {
	ProcessSerialNumber psn;
	psn.highLongOfPSN = [theEvent data1];
	psn.lowLongOfPSN = [theEvent data2];

	NSDictionary *processInfo = [self infoForPSN:psn];

    switch ([theEvent subtype]) {
		case NSProcessDidLaunchSubType:
			if (![[NSUserDefaults standardUserDefaults] boolForKey:kQSShowBackgroundProcesses])
                return YES;
            BOOL background = [[processInfo objectForKey:@"LSUIElement"] boolValue] || [[processInfo objectForKey:@"LSBackgroundOnly"] boolValue];
			if (!background) return YES;
				[self addProcessWithDict: processInfo];
			break;
		case NSProcessDidTerminateSubType:
			[self removeProcessWithPSN:psn];
			break;
		case NSFrontProcessSwitched:
			[[NSNotificationCenter defaultCenter] postNotificationName:QSActiveApplicationChanged object: processInfo];
			[self appChanged:nil];
			break;
		default:
	 break;
	}
	return YES;
}

- (void)appChanged:(NSNotification *)aNotification {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSDictionary *newApp = [workspace activeApplication];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Hide Other Apps When Switching"]) {
		if (!(GetCurrentKeyModifiers() & shiftKey) ) {
			//if (VERBOSE) NSLog(@"Hide Other Apps");
			[workspace hideOtherApplications:[NSArray arrayWithObject:newApp]];
		}
	}

	[self setPreviousApplication:currentApplication];
	[self setCurrentApplication:newApp];
}

- (void)processTerminated:(QSObject *)thisProcess {
	//NSLog(@"Terminate:%@", thisProcess);
	[[thisProcess dataDictionary] removeObjectForKey:QSProcessType];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ObjectModified" object:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"processesChanged" object:nil];
	[processes removeObject:thisProcess];
}

- (void)removeProcessWithPSN:(ProcessSerialNumber)psn {
	QSObject *thisProcess = [self processObjectWithPSN:psn];
	//NSLog(@"psn %@", thisProcess);
	[self processTerminated:thisProcess];
}

- (QSObject *)processObjectWithDict:(NSDictionary *)dict {
	ProcessSerialNumber psn;
	if (noErr == GetPSNForAppInfo(&psn, dict) )
		return [self processObjectWithPSN:psn];
	return nil;
}

- (void)appTerminated:(NSNotification *)notif {
	[self processTerminated:[self processObjectWithDict:[notif userInfo]]];
}

- (void)appLaunched:(NSNotification *)notif {
	if (![processes count])
		[self reloadProcesses];
	else
		[self addProcessWithDict:[notif userInfo]];
	//	[self invalidateSelf];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSApplicationLaunchEvent" userInfo:[NSDictionary dictionaryWithObject:[self imbuedFileProcessForDict:[notif userInfo]] forKey:@"object"]];

}

- (void)addObserverForEvent:(NSString *)event trigger:(NSDictionary *)trigger {
	NSLog(@"Add %@", event);
}
- (void)removeObserverForEvent:(NSString *)event trigger:(NSDictionary *)trigger {
	NSLog(@"Remove %@", event);

}

- (void)addProcessWithDict:(NSDictionary *)info {
	if ([self processObjectWithDict:info]) return;

//	NSLog(@"addProcess %@", [info objectForKey:@"NSApplicationName"]);
	QSObject *thisProcess = [self imbuedFileProcessForDict:info];
//	NSLog(@"process %@", thisProcess);
	[processes addObject:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ObjectModified" object:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"processesChanged" object:nil];
}

- (NSArray *)getAllProcesses {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses = [NDProcess everyProcess];

	NDProcess *thisProcess;
	pid_t pid = -1;
	//ProcessSerialNumber psn;
	NSEnumerator *processEnumerator = [newProcesses objectEnumerator];
	while(thisProcess = [processEnumerator nextObject]) {
		newObject = nil;
		if (newObject = [self imbuedFileProcessForDict:[thisProcess processInfo]])
			[objects addObject:newObject];
		else
			NSLog(@"ignoring process id %d", pid);
	}
	return objects;

	return nil;
}
- (NSArray *)getVisibleProcesses {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses = [[NSWorkspace sharedWorkspace] launchedApplications]; //[NDProcess everyProcess];

	NSDictionary *thisProcess;
	NSEnumerator *processEnumerator = [newProcesses objectEnumerator];
	while(thisProcess = [processEnumerator nextObject]) {

		if (newObject = [self imbuedFileProcessForDict:thisProcess])
			[objects addObject:newObject];
		// else
		//  NSLog(@"ignoring process id %d", pid);

	}
	return objects;

	return nil;
}

- (NSArray *)processesWithHiddenState:(BOOL)hidden {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses = [NDProcess everyProcess];

	NDProcess *thisProcess;
//	pid_t pid = -1;
	//ProcessSerialNumber psn;
	NSEnumerator *processEnumerator = [newProcesses objectEnumerator];
	while(thisProcess = [processEnumerator nextObject]) {
		newObject = nil;
		if (hidden && [thisProcess isVisible]) continue;
		else if ([thisProcess isBackground]) continue;

		if (newObject = [self imbuedFileProcessForDict:[thisProcess processInfo]])
			[objects addObject:newObject];
	}

	return objects;

	return nil;

}

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict {
	NSString *bundlePath = [[dict objectForKey:@"NSApplicationPath"] stringByDeletingLastPathComponent];
	QSObject *newObject = nil;
	if ([[bundlePath lastPathComponent] isEqualToString:@"MacOS"] || [[bundlePath lastPathComponent] isEqualToString:@"MacOSClassic"]) {
		bundlePath = [bundlePath stringByDeletingLastPathComponent];
		// ***warning  * check that this is the executable specified by the info.plist
		if ([[bundlePath lastPathComponent] isEqualToString:@"Contents"]) {
			bundlePath = [bundlePath stringByDeletingLastPathComponent];
			newObject = [QSObject fileObjectWithPath:bundlePath];
			//	NSLog(@"%@ %@", bundlePath, newObject);

		}
	}

	if (!newObject)
		newObject = [QSObject fileObjectWithPath:[dict objectForKey:@"NSApplicationPath"]];

	[newObject setObject:dict forType:QSProcessType];
	return newObject;
}

- (void)reloadProcesses {
	//NSLog(@"Reloading Processes");
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kQSShowBackgroundProcesses])
		[processes setArray:[self getAllProcesses]];
	else
		[processes setArray:[self getVisibleProcesses]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"processesChanged" object:nil];

	//[self invalidateSelf];
}

- (NSArray *)visibleProcesses {
	return [self allProcesses];

}
- (NSArray *)allProcesses {
	if (![processes count])
		[self reloadProcesses];
//	NSLog(@"proc %@", processes);
	return processes;
}
- (NSDictionary *)previousApplication {
	return previousApplication;
}

- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSCurrentApplicationProxy"]) {
		//	NSLog(@"return");
		return [self imbuedFileProcessForDict:[[NSWorkspace sharedWorkspace] activeApplication]];
	} else if ([[proxy identifier] isEqualToString:@"QSPreviousApplicationProxy"]) {
		return [self imbuedFileProcessForDict:previousApplication];
	} else if ([[proxy identifier] isEqualToString:@"QSHiddenApplicationsProxy"]) {
		return [QSObject objectByMergingObjects:[self processesWithHiddenState:YES]];
	} else if ([[proxy identifier] isEqualToString:@"QSVisibleApplicationsProxy"]) {
		return [QSObject objectByMergingObjects:[self processesWithHiddenState:NO]];
	}
	return nil;
}

- (NSTimeInterval) cacheTimeForProxy:(id)proxy {
	return 0.0f;
}

- (NSDictionary *)currentApplication {
	return currentApplication;
}
- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication {
	if (currentApplication != newCurrentApplication) {
		[currentApplication release];
		currentApplication = [newCurrentApplication copy];
	}
}

- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication {
	if (previousApplication != newPreviousApplication) {
		[previousApplication release];
		previousApplication = [newPreviousApplication copy];
	}
}

@end
