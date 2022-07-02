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
- (NSDictionary *)processesDict;
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
		NSDictionary *dict = [[(__bridge QSProcessMonitor*)userData processObjectWithPSN:psn] objectForType:QSProcessType];
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
		NSDictionary *dict = [[(__bridge QSProcessMonitor*)userData processObjectWithPSN:psn] objectForType:QSProcessType];
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
		NSDictionary *dict = [[(__bridge QSProcessMonitor*)userData processObjectWithPSN:psn] objectForType:QSProcessType];
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
	NSString *ident = [dict objectForKey:@"NSApplicationBundleIdentifier"];
	if ([ident isEqualToString:@"com.apple.TextEdit"]) {
		NSLog(@"");
	}
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

	NSMutableDictionary *dict = [(NSDictionary *)CFBridgingRelease(ProcessInformationCopyDictionary(&processSerialNumber, kProcessDictionaryIncludeAllInformationMask)) mutableCopy];
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
		dict = [dict copy];
	return dict;
}

#pragma mark -
#pragma mark Process Notifications

- (BOOL)handleProcessEvent:(NSEvent *)theEvent {
	ProcessSerialNumber psn;
	psn.highLongOfPSN = (UInt32)[theEvent data1];
	psn.lowLongOfPSN = (UInt32)[theEvent data2];
	
    switch ([theEvent subtype]) {
		case NSProcessDidLaunchSubType: {
			[self reloadProcesses];
			break;
		} case NSProcessDidTerminateSubType: {
			[self removeProcess:psn];
			break;
		} case NSFrontProcessSwitched: {
			NSDictionary *processInfo = [self infoForPSN:psn];
			[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorFrontApplicationSwitched object: processInfo];
			break;
		}
		default:
	 break;
	}
	return YES;
}

- (void)appLaunched:(NSNotification *)notif {
	[self reloadProcesses];
}

- (void)appTerminated:(NSNotification *)notif {
	ProcessSerialNumber psn;
	if (GetPSNForAppInfo(&psn, [notif userInfo]) != noErr)
		return;
	[self removeProcess:psn];
}

- (void)appChanged:(NSNotification *)aNotification {
	/* TODO: tiennou This doesn't belong here */
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSDictionary *newApp = [workspace activeApplication];
	if ([[newApp objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.blacktree.Quicksilver"] && [[NSUserDefaults standardUserDefaults] boolForKey:kHideDockIcon]) {
		return;
	}
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
	NSArray *objs = [[self processesDict] allValues];
	NSIndexSet *i = [objs indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSDictionary *infoDict = [obj objectForType:QSProcessType];
		NDProcess *thisProcess = [NDProcess processWithProcessID:[[infoDict objectForKey:@"NSApplicationProcessIdentifier"] intValue]];
		
		if (!thisProcess) {
			return NO;
		}
		BOOL isBackground = [thisProcess isBackground];
		if (!hidden && isBackground) {
			return NO;
		}
		if (hidden && !isBackground) {
			return NO;
		}
		return YES;
	}];
	return [objs objectsAtIndexes:i];
}

- (void)removeProcess:(ProcessSerialNumber)psn {
	QSObject *obj = [self processObjectWithPSN:psn];
	if (obj) {
		[obj setObject:nil forType:QSProcessType];
	} else {
#ifdef DEBUG
		NSLog(@"No object found for process %u", (unsigned int)psn.highLongOfPSN);
#endif
	}
	[self reloadProcesses];
}

- (void)reloadProcesses {
	/* Mark us as reloading to prevent -addProcessWithPSN from sending one notification per found process, and handle KVO ourselves. */
	
	[self willChangeValueForKey:@"visibleProcesses"];
	[self willChangeValueForKey:@"backgroundProcesses"];
	[self willChangeValueForKey:@"allProcesses"];	
	
	NSDate *date = [NSDate date];
	NSArray *tempProcesses = [NDProcess everyProcess];
	NSMutableDictionary *procs = [[NSMutableDictionary alloc] initWithCapacity:processes.count];
	for (NDProcess *thisProcess in tempProcesses) {
		ProcessSerialNumber psn = [thisProcess processSerialNumber];
		NSDictionary *info = [self infoForPSN:psn];
		QSObject *procObject = [self imbuedFileProcessForDict:info];
		NSValue *psnValue = [NSValue valueWithProcessSerialNumber:psn];
		
		if (procObject) {
			[procs setObject:procObject forKey:psnValue];
		}
	}
	processes = [procs copy];
	NSLog(@"Reload time: %f ms", [date timeIntervalSinceNow]*-1000);

	[self didChangeValueForKey:@"allProcesses"];
	[self didChangeValueForKey:@"backgroundProcesses"];
	[self didChangeValueForKey:@"visibleProcesses"];
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

- (NSDictionary *)processesDict {
	if (!processes) {
		processes = [NSMutableDictionary dictionaryWithCapacity:1];
        isReloading = YES;
		[self reloadProcesses];
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
	return [self visibleProcesses];
}

- (NSArray *)visibleProcesses {
	return [self processesWithHiddenState:NO];
}

- (NSArray *)backgroundProcesses {
	return [self processesWithHiddenState:YES];
}

- (NSDictionary *)currentApplication {
	return currentApplication;
}

- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication {
	if (currentApplication != newCurrentApplication) {
		currentApplication = newCurrentApplication;
	}
}

- (NSDictionary *)previousApplication {
	return previousApplication;
}

- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication {
	if (previousApplication != newPreviousApplication) {
		previousApplication = newPreviousApplication;
	}
}

@end
