#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDProcess+QSMods.h"

#import "QSProcessMonitor.h"
#import "QSTypes.h"

#import "NSEvent+BLTRExtensions.h"

@implementation NSValue (ProcessSerialNumberExtension)

+ (id)valueWithProcessSerialNumber:(ProcessSerialNumber)psn {
	return [[self alloc] initWithProcessSerialNumber:psn];
}

- (id)initWithProcessSerialNumber:(ProcessSerialNumber)psn {
	self = [self initWithBytes:(const void *)&psn objCType:@encode(ProcessSerialNumber)];
	return self;
}

- (ProcessSerialNumber)processSerialNumberValue {
	ProcessSerialNumber psn;
	[self getValue:&psn];
	return psn;
}

@end

@interface QSProcessMonitor (QSInternal)
- (NSDictionary *)infoForPSN:(ProcessSerialNumber)processSerialNumber;
- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication;
- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication;
- (NSMutableDictionary *)processesDict;
@end

NSString *QSProcessMonitorFrontApplicationSwitched = @"QSProcessMonitorFrontApplicationSwitched";
NSString *QSProcessMonitorApplicationLaunched = @"QSProcessMonitorApplicationLaunched";
NSString *QSProcessMonitorApplicationTerminated = @"QSProcessMonitorApplicationTerminated";

OSStatus GetPSNForAppInfo(ProcessSerialNumber *psn, NSDictionary *theApp) {
	if (!theApp) return 1;
	psn->highLongOfPSN = [[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] intValue];
	psn->lowLongOfPSN = [[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] intValue];
	return noErr;
}

#pragma mark -
#pragma mark Carbon Process event handlers

OSStatus appChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ProcessSerialNumber psn;
    OSStatus result;
    result = GetEventParameter(theEvent,
                               kEventParamProcessID,
                               typeProcessSerialNumber, NULL,
                               sizeof(psn), NULL,
                               &psn);
    if( result == noErr ) {
        NSDictionary *dict = [(__bridge QSProcessMonitor*)userData infoForPSN:psn];
        QSGCDMainAsync(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorFrontApplicationSwitched object:(__bridge id)userData userInfo:dict];
        });
    } else {
        NSLog(@"Unable to get event parameter kEventParamProcessID");
    }
	return CallNextEventHandler(nextHandler, theEvent);
}

OSStatus appLaunched(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ProcessSerialNumber psn;
    OSStatus result;
    result = GetEventParameter(theEvent,
                               kEventParamProcessID,
                               typeProcessSerialNumber, NULL,
                               sizeof(psn), NULL,
                               &psn);

    if( result == noErr ) {
        NSDictionary *dict = [(__bridge QSProcessMonitor*)userData infoForPSN:psn];
        QSGCDMainAsync(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorApplicationLaunched object:(__bridge id)(userData) userInfo:dict];
        });
    } else {
        NSLog(@"Unable to get event parameter kEventParamProcessID");
    }
	return CallNextEventHandler(nextHandler, theEvent);
}

OSStatus appTerminated(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    ProcessSerialNumber psn;
    OSStatus result;
    result = GetEventParameter(theEvent,
                               kEventParamProcessID,
                               typeProcessSerialNumber, NULL,
                               sizeof(psn), NULL,
                               &psn);

    if( result == noErr ) {
        NSDictionary *dict = [(__bridge QSProcessMonitor*)userData infoForPSN:psn];
        QSGCDMainAsync(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorApplicationTerminated object:(__bridge id)(userData) userInfo:dict];
        });
    } else {
        NSLog(@"Unable to get event parameter kEventParamProcessID");
    }
	return CallNextEventHandler(nextHandler, theEvent);
}

@implementation QSProcessMonitor

+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[self allocWithZone:nil] init];
	return _sharedInstance;
}

+ (NSArray *)processes {
	NSMutableArray *resultsArray = [NSMutableArray array];
	ProcessSerialNumber serialNumber;
	ProcessInfoRec		procInfo;
	Str255				procName;

	serialNumber.highLongOfPSN	= kNoProcess;
	serialNumber.lowLongOfPSN	= kNoProcess;

	procInfo.processInfoLength	= sizeof(ProcessInfoRec);
	procInfo.processName		= procName;

    #ifdef __LP64__
        FSRef appFSRef;
        procInfo.processAppRef = &appFSRef;
    #else
        FSSpec appFSSpec;
        procInfo.processAppSpec = &appFSSpec;
    #endif

	while (procNotFound != (GetNextProcess(&serialNumber) )) {
		if (noErr == (GetProcessInformation(&serialNumber, &procInfo) )) {
			if ('\0' == procName[1])
				procName[1] = '0';
            NSString *processName = (NSString*)CFBridgingRelease(CFStringCreateWithPascalString(NULL, procInfo.processName, kCFStringEncodingUTF8));
			[resultsArray addObject:processName];
		}
	}
	return resultsArray;
}

- (id)init {
	if (self = [super init]) {
		isReloading = NO;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTerminated:) name:QSProcessMonitorApplicationTerminated object: nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLaunched:) name:QSProcessMonitorApplicationLaunched object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) name:QSProcessMonitorFrontApplicationSwitched object: nil];

		EventTypeSpec eventType;
		EventHandlerUPP handlerFunction;
		OSStatus err;

		eventType.eventClass = kEventClassApplication;
		eventType.eventKind = kEventAppFrontSwitched;
		handlerFunction = NewEventHandlerUPP(appChanged);
		err = InstallApplicationEventHandler(handlerFunction, 1, &eventType, (__bridge void *) self, &changeHandler);
		if (err)
			NSLog(@"QSProcessMonitor Change registration err %ld", (long)err);

		eventType.eventClass = kEventClassApplication;
		eventType.eventKind = kEventAppLaunched;
		handlerFunction = NewEventHandlerUPP(appLaunched);
		err = InstallApplicationEventHandler(handlerFunction, 1, &eventType, (__bridge void *) self, &launchHandler);
		if (err)
			NSLog(@"QSProcessMonitor Launch registration err %ld", (long)err);

		eventType.eventClass = kEventClassApplication;
		eventType.eventKind = kEventAppTerminated;
		handlerFunction = NewEventHandlerUPP(appTerminated);
		err = InstallApplicationEventHandler(handlerFunction, 1, &eventType, (__bridge void *) self, &terminateHandler);
		if (err)
			NSLog(@"QSProcessMonitor Terminate registration err %ld", (long)err);
    }
	return self;
}

- (void)dealloc {
    OSStatus err;
	err = RemoveEventHandler(changeHandler);
    if(err)
        NSLog(@"error %ld removing change handler", (long)err);
    err = RemoveEventHandler(launchHandler);
    if(err)
        NSLog(@"error %ld removing launch handler", (long)err);
    err = RemoveEventHandler(terminateHandler);
    if(err)
        NSLog(@"error %ld removing terminate handler", (long)err);
	currentApplication = nil;
	previousApplication = nil;
	processes = nil;
}

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict {
    NSString *appPath = [dict objectForKey:@"NSApplicationPath"];
	NSString *bundlePath = [appPath stringByDeletingLastPathComponent];
	QSObject *newObject = nil;
	if ([[bundlePath lastPathComponent] isEqualToString:@"MacOS"]) {
		bundlePath = [bundlePath stringByDeletingLastPathComponent];
		// ***warning  * check that this is the executable specified by the info.plist
		if ([[bundlePath lastPathComponent] isEqualToString:@"Contents"]) {
			bundlePath = [bundlePath stringByDeletingLastPathComponent];
			newObject = [QSObject fileObjectWithPath:bundlePath];
			//	NSLog(@"%@ %@", bundlePath, newObject);
		}
	}

	if (!newObject) {
        if (appPath) {
            newObject = [QSObject fileObjectWithPath:[dict objectForKey:@"NSApplicationPath"]];
        } else {
            // the process isn't an app
            newObject = [QSObject fileObjectWithPath:[dict objectForKey:@"CFBundleExecutable"]];
        }
    }

	[newObject setObject:dict forType:QSProcessType];
	return newObject;
}

- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn {
	QSObject *thisProcess;
	ProcessSerialNumber thisPSN;
	Boolean match;
	NSValue *thisProcessPSN;

	for (thisProcessPSN in [self processesDict]) {
		thisProcess = [[self processesDict] objectForKey:thisProcessPSN];
		NSDictionary *info = [thisProcess objectForType:QSProcessType];
		GetPSNForAppInfo(&thisPSN, info);
		SameProcess(&psn, &thisPSN, &match);
		if (match) return thisProcess;
	}
	return nil;
}

- (QSObject *)processObjectWithDict:(NSDictionary *)dict {
	ProcessSerialNumber psn;
	if (noErr == GetPSNForAppInfo(&psn, dict) )
		return [self processObjectWithPSN:psn];
	return nil;
}

- (NSDictionary *)infoForPSN:(ProcessSerialNumber)processSerialNumber {
	NSNumber *psnNumber = [NSValue valueWithProcessSerialNumber:processSerialNumber];
    NSDictionary *dict = [[[self processesDict] objectForKey:psnNumber] objectForType:QSProcessType];

	if (!dict) {
		dict = (NSDictionary *)CFBridgingRelease(ProcessInformationCopyDictionary(&processSerialNumber, kProcessDictionaryIncludeAllInformationMask));
		dict = [dict mutableCopy];

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
	}
	return dict;
}

#pragma mark -
#pragma mark Process array manipulation

- (void)removeProcessWithPSN:(ProcessSerialNumber)psn {
	NSDictionary *info = [self infoForPSN:psn];
    QSObject *procObject = [self imbuedFileProcessForDict:info];
	NSValue *psnValue = [NSValue valueWithProcessSerialNumber:psn];

	if (procObject) {
		if (!isReloading) {
			/* We're forced to send notifications for everything because we don't know anymore if the application was background or not */
			[self willChangeValueForKey:@"allProcesses"];
			[self willChangeValueForKey:@"backgroundProcesses"];
			[self willChangeValueForKey:@"visibleProcesses"];
		}
		[procObject setObject:nil forType:QSProcessType];
		[[self processesDict] removeObjectForKey:psnValue];
		if (!isReloading) {
			[self didChangeValueForKey:@"visibleProcesses"];
			[self didChangeValueForKey:@"backgroundProcesses"];
			[self didChangeValueForKey:@"allProcesses"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSApplicationQuitEvent" userInfo:[NSDictionary dictionaryWithObject:procObject forKey:@"object"]];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectModified object:procObject];
	}
}

- (void)addProcessWithPSN:(ProcessSerialNumber)psn {
	NDProcess *thisProcess = [NDProcess processWithProcessSerialNumber:psn];

	NSDictionary *info = [self infoForPSN:psn];
    QSObject *procObject = [self imbuedFileProcessForDict:info];
	NSValue *psnValue = [NSValue valueWithProcessSerialNumber:psn];

    if (procObject) {
		if (!isReloading) {
			[self willChangeValueForKey:@"allProcesses"];
			[self willChangeValueForKey:[thisProcess isBackground] ? @"backgroundProcesses" : @"visibleProcesses"];
		}
		[[self processesDict] setObject:procObject forKey:psnValue];
		if (!isReloading) {
			[self didChangeValueForKey:[thisProcess isBackground] ? @"backgroundProcesses" : @"visibleProcesses"];
			[self didChangeValueForKey:@"allProcesses"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSApplicationLaunchEvent" userInfo:[NSDictionary dictionaryWithObject:procObject forKey:@"object"]];
		}
	}
}

#pragma mark -
#pragma mark Process Notifications

- (BOOL)handleProcessEvent:(NSEvent *)theEvent {
	ProcessSerialNumber psn;
	psn.highLongOfPSN = (UInt32)[theEvent data1];
	psn.lowLongOfPSN = (UInt32)[theEvent data2];

	NSDictionary *processInfo;

    switch ([theEvent subtype]) {
		case NSProcessDidLaunchSubType:
			[self addProcessWithPSN:psn];
			break;
		case NSProcessDidTerminateSubType:
			[self removeProcessWithPSN:psn];
			break;
		case NSFrontProcessSwitched:
			processInfo = [self infoForPSN:psn];
			[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorFrontApplicationSwitched object: processInfo];
			break;
		default:
	 break;
	}
	return YES;
}

- (void)appLaunched:(NSNotification *)notif {
	ProcessSerialNumber psn;
	if (GetPSNForAppInfo(&psn, [notif userInfo]) != noErr)
		return;

	[self addProcessWithPSN:psn];
}

- (void)appTerminated:(NSNotification *)notif {
	ProcessSerialNumber psn;
	if (GetPSNForAppInfo(&psn, [notif userInfo]) != noErr)
		return;

	[self removeProcessWithPSN:psn];
}

- (void)appChanged:(NSNotification *)aNotification {
	/* TODO: tiennou This doesn't belong here */
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

#pragma mark -
#pragma mark Utilities

- (NSArray *)processesWithHiddenState:(BOOL)hidden {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];

	NDProcess *thisProcess;
	NSValue *thisProcessPSN;
	for (thisProcessPSN in [[self processesDict] allKeys]) {
		thisProcess = [NDProcess processWithProcessSerialNumber:[thisProcessPSN processSerialNumberValue]];

		if (!hidden && [thisProcess isBackground]) continue;
		else if (hidden && ![thisProcess isBackground]) continue;

		QSObject *newObject = [self imbuedFileProcessForDict:[self infoForPSN:[thisProcessPSN processSerialNumberValue]]];
		if (newObject)
			[objects addObject:newObject];
	}
	return objects;
}

- (void)reloadProcesses {
	/* Mark us as reloading to prevent -addProcessWithPSN from sending one notification per found process, and handle KVO ourselves. */
	isReloading = YES;
	[self willChangeValueForKey:@"visibleProcesses"];
	[self willChangeValueForKey:@"backgroundProcesses"];
	[self willChangeValueForKey:@"allProcesses"];

	[processes removeAllObjects];
	id thisProcess = nil;
	for (thisProcess in [NDProcess everyProcess]) {
		[self addProcessWithPSN:[thisProcess processSerialNumber]];
	}

	[self didChangeValueForKey:@"allProcesses"];
	[self didChangeValueForKey:@"backgroundProcesses"];
	[self didChangeValueForKey:@"visibleProcesses"];
	isReloading = NO;
}

#pragma mark -
#pragma mark Proxies

- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSCurrentApplicationProxy"]) {
		//	NSLog(@"return");
		return [self imbuedFileProcessForDict:[[NSWorkspace sharedWorkspace] activeApplication]];
	} else if ([[proxy identifier] isEqualToString:@"QSPreviousApplicationProxy"]) {
		return [self imbuedFileProcessForDict:previousApplication];
	}
	return nil;
}

- (NSTimeInterval) cacheTimeForProxy:(id)proxy {
	return 0.0f;
}

#pragma mark -
#pragma mark Accessors

- (NSMutableDictionary *)processesDict {
	if (!processes) {
		processes = [NSMutableDictionary dictionaryWithCapacity:1];
        isReloading = YES;
        for (id thisProcess in [NDProcess everyProcess]) {
            [self addProcessWithPSN:[thisProcess processSerialNumber]];
        }
        isReloading = NO;
	}
	return processes;
}

- (NSArray *)allProcesses {
	return [[self processesDict] allValues];
}

- (NSArray *)getAllProcesses {
	return [self allProcesses];
}

- (NSArray *)getVisibleProcesses {
	return [self processesWithHiddenState:NO];
}

- (NSArray *)visibleProcesses {
	return [self getVisibleProcesses];
}

- (NSArray *)backgroundProcesses {
	return [self processesWithHiddenState:YES];
}

- (NSDictionary *)currentApplication {
	return currentApplication;
}

- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication {
	if (currentApplication != newCurrentApplication) {
		currentApplication = [newCurrentApplication copy];
	}
}

- (NSDictionary *)previousApplication {
	return previousApplication;
}

- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication {
	if (previousApplication != newPreviousApplication) {
		previousApplication = [newPreviousApplication copy];
	}
}

@end
