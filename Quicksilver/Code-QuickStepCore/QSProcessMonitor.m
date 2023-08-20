#import "QSObject.h"
#import "QSObject_FileHandling.h"

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

- (void)appChanged:(ProcessSerialNumber)psn;
- (void)appLaunched:(ProcessSerialNumber)psn;
- (void)appTerminated:(ProcessSerialNumber)psn;
@end

NSString *QSProcessMonitorFrontApplicationSwitched = @"QSProcessMonitorFrontApplicationSwitched";
NSString *QSProcessMonitorApplicationLaunched = @"QSProcessMonitorApplicationLaunched";
NSString *QSProcessMonitorApplicationTerminated = @"QSProcessMonitorApplicationTerminated";
dispatch_queue_t proc_thread;

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
		QSGCDQueueAsync(proc_thread, ^{
			[(__bridge QSProcessMonitor*)userData appChanged:psn];
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
		QSGCDQueueAsync(proc_thread, ^{
			[(__bridge QSProcessMonitor*)userData appLaunched:psn];
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
		QSGCDQueueAsync(proc_thread, ^{
			[(__bridge QSProcessMonitor*)userData appTerminated:psn];
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

- (id)init {
	if (self = [super init]) {
		isReloading = NO;
		proc_thread = dispatch_queue_create("proc", DISPATCH_QUEUE_SERIAL);

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
	processesSnapshot = nil;
}

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict {
	NSString *ident = [dict objectForKey:@"NSApplicationBundleIdentifier"];
    NSString *appPath = [dict objectForKey:@"NSApplicationPath"];
	NSBundle *bundle = [NSBundle bundleWithIdentifier:ident];
	QSObject *newObject = nil;
	if (bundle && [appPath isEqualToString:[bundle executablePath]]) {
		newObject = [QSObject fileObjectWithPath:[bundle bundlePath]];
		//	NSLog(@"%@ %@", bundlePath, newObject);
	}

	if (!newObject) {
        if (appPath) {
            newObject = [QSObject fileObjectWithPath:[dict objectForKey:@"NSApplicationPath"]];
        } else {
            // the process isn't an app
            newObject = [QSObject fileObjectWithPath:[dict objectForKey:@"CFBundleExecutable"]];
        }
		[newObject setLabel:[dict objectForKey:@"CFBundleName"]];
    }

	[newObject setObject:dict forType:QSProcessType];
	return newObject;
}

- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn {
	return [self processObjectWithPSN:psn fromSnapshot:NO];
}
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn fromSnapshot:(BOOL)snapshot {
	NSDictionary *dict = (snapshot ? processesSnapshot : [self processesDict]);
	__block QSObject *matchedProcess = nil;
	[dict enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, QSObject *thisProcess, BOOL * _Nonnull stop) {
		NSDictionary *info = [thisProcess objectForType:QSProcessType];
		Boolean match;
		ProcessSerialNumber thisPSN;
		GetPSNForAppInfo(&thisPSN, info);
		SameProcess(&psn, &thisPSN, &match);
		if (match) {
			*stop = YES;
			matchedProcess = thisProcess;
		}
	}];
	return matchedProcess ? matchedProcess : nil;
}

- (QSObject *)processObjectWithDict:(NSDictionary *)dict {
	ProcessSerialNumber psn;
	if (noErr == GetPSNForAppInfo(&psn, dict) )
		return [self processObjectWithPSN:psn];
	return nil;
}

- (NSDictionary *)infoForApp:(NSRunningApplication *)app {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	[dict setValue:[app localizedName] forKey:@"NSApplicationName"];
	[dict setValue:[[app bundleURL] path] forKey:@"NSApplicationPath"];
	[dict setValue:app.bundleIdentifier forKey:@"NSApplicationBundleIdentifier"];
	[dict setValue:[NSNumber numberWithInt:[app processIdentifier]] forKey:@"NSApplicationProcessIdentifier"];
	[dict setValue:[NSNumber numberWithBool:(app.activationPolicy == NSApplicationActivationPolicyProhibited)] forKey:@"LSBackgroundOnly"];
	[dict setValue:[NSNumber numberWithBool:(app.activationPolicy == NSApplicationActivationPolicyAccessory)] forKey:@"LSUIElement"];
	ProcessSerialNumber psn;
	GetProcessForPID(app.processIdentifier, &psn);
	[dict setValue:[NSNumber numberWithLong:psn.highLongOfPSN]
			forKey:@"NSApplicationProcessSerialNumberHigh"];

	[dict setValue:[NSNumber numberWithLong:psn.lowLongOfPSN]
			forKey:@"NSApplicationProcessSerialNumberLow"];
	dict = [dict copy];
	return dict;
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
			[self appLaunched:psn];
			break;
		} case NSProcessDidTerminateSubType: {
			[self appTerminated:psn];
			break;
		} case NSFrontProcessSwitched: {
			[self appChanged:psn];
			break;
		}
		default:
	 break;
	}
	return YES;
}

- (void)appLaunched:(ProcessSerialNumber)psn {
	NSDictionary *dict = [self infoForPSN:psn];

	// This notif is used for the Events plugin 'Application Launched' event trigger
	[self reloadProcesses];
	if (dict) {
		QSObject *procObject = [self imbuedFileProcessForDict:dict];
		QSGCDMainAsync(^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSApplicationLaunchEvent" userInfo:[NSDictionary dictionaryWithObject:procObject forKey:@"object"]];
			[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorApplicationLaunched object:self userInfo:dict];
		});
	}
}

- (void)appTerminated:(ProcessSerialNumber)psn {
	QSObject *processObject = [self processObjectWithPSN:psn];
	
	if (processObject) {
		NSDictionary *dict = [processObject objectForType:QSProcessType];
		
		[self reloadProcesses];
		
		QSGCDMainAsync(^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSApplicationQuitEvent" userInfo:[NSDictionary dictionaryWithObject:processObject forKey:@"object"]];
			[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorApplicationTerminated object:self userInfo:dict];
		});
	} else {
#ifdef DEBUG
		NSLog(@"No object found for process %u", (unsigned int)psn.highLongOfPSN);
#endif
	}
}

- (void)appChanged:(ProcessSerialNumber)psn {
	NSDictionary *dict = [[self processObjectWithPSN:psn] objectForType:QSProcessType];
	QSGCDMainAsync(^{
		[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorFrontApplicationSwitched object:self userInfo:dict];
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
	});
}

#pragma mark -
#pragma mark Utilities

- (NSArray *)processesWithHiddenState:(BOOL)hidden {
	NSArray *objs = [[self processesDict] allValues];
	NSIndexSet *i = [objs indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSDictionary *infoDict = [obj objectForType:QSProcessType];
		NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:[[infoDict objectForKey:@"NSApplicationProcessIdentifier"] intValue]];
		
		if (!app) {
			return NO;
		}
		BOOL isBackground = app.activationPolicy == NSApplicationActivationPolicyProhibited;
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

- (void)reloadProcesses {
	/* Mark us as reloading to prevent -addProcessWithPSN from sending one notification per found process, and handle KVO ourselves. */
	
	[self willChangeValueForKey:@"visibleProcesses"];
	[self willChangeValueForKey:@"backgroundProcesses"];
	[self willChangeValueForKey:@"allProcesses"];	
	
	if (processes != nil) {
		processesSnapshot = [processes copy];
	}
#ifdef DEBUG
	NSDate *date = [NSDate date];
#endif
	
	NSArray *tempProcesses = [[NSWorkspace sharedWorkspace] runningApplications];
	NSMutableDictionary *procs = [[NSMutableDictionary alloc] initWithCapacity:tempProcesses.count];
	for (NSRunningApplication *app in tempProcesses) {
		NSDictionary *info = [self infoForApp:app];
		QSObject *procObject = [self imbuedFileProcessForDict:info];
		NSNumber *pidValue = [NSNumber numberWithInt:app.processIdentifier];
		
		if (procObject) {
			[procs setObject:procObject forKey:pidValue];
		}
	}
	processes = [procs copy];
#ifdef DEBUG
	NSLog(@"Reload time: %f ms", [date timeIntervalSinceNow]*-1000);
#endif

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
