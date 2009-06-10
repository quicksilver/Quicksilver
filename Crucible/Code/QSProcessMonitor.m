#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDProcess.h"
#import "NDProcess+QSMods.h"

#import "QSProcessMonitor.h"
#import "QSTypes.h"

#import "NSEvent+BLTRExtensions.h"
#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"
OSStatus GetPSNForAppInfo(ProcessSerialNumber *psn,NSDictionary *theApp){
    if (!theApp) return 1;
    (*psn).highLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
    (*psn).lowLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
    return noErr;
}
@implementation QSProcessMonitor
+ (id)sharedInstance{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[self allocWithZone:[self zone]] init];
    return _sharedInstance;
}

+ (NSArray *)processes
{
    NSMutableArray *resultsArray=[NSMutableArray array];
    OSErr resultCode=noErr;
    ProcessSerialNumber serialNumber;
    ProcessInfoRec             procInfo;
    FSSpec              appFSSpec;
    
    Str255                             procName;
    serialNumber.highLongOfPSN = kNoProcess;
    serialNumber.lowLongOfPSN  = kNoProcess;
    
    procInfo.processInfoLength              = sizeof(ProcessInfoRec);
    procInfo.processName                    = procName;
    procInfo.processAppSpec             = &appFSSpec;
    procInfo.processAppSpec             = &appFSSpec;
    
    
    while (procNotFound != (resultCode = GetNextProcess(&serialNumber)))
    {
        if (noErr == (resultCode = 
                      GetProcessInformation(&serialNumber, &procInfo)))
        {
            if ('\0' == procName[1])
                procName[1] = '0';
            [resultsArray addObject:(NSString 
                                     *)CFStringCreateWithPascalString(NULL,procInfo.processName,kCFStringEncodingMacRoman)
                ];
        }
    }
    return resultsArray;
    
    
}


OSStatus appChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	QSLog(@"app change event unhandled!\n");
	return CallNextEventHandler(nextHandler, theEvent);
}




- (void)regisiterForAppChangeNotifications{
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassApplication;
	eventType.eventKind = kEventAppFrontSwitched;
	EventHandlerUPP handlerFunction = NewEventHandlerUPP(appChanged);
	OSStatus err=InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, &eventType, NULL, NULL);
	if (err) QSLog(@"gmod registration err %d",err);
}

- (id) init{
    if ((self=[super init])){
		[self regisiterForAppChangeNotifications];
		processes=[[NSMutableArray arrayWithCapacity:1]retain];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object: nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object: nil];
		//[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) name:@"com.apple.HIToolbox.menuBarShownNotification" object:nil];
		
	   }
    return self;
}


- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn{
    QSObject *thisProcess;
	ProcessSerialNumber thisPSN;
	Boolean match;
	
    for(thisProcess in processes){
		NSDictionary *info=[thisProcess objectForType:QSProcessType];
		GetPSNForAppInfo(&thisPSN,info);
		SameProcess(&psn,&thisPSN,&match);
		if (match) return thisProcess;
	}
	return nil;
}

- (NSDictionary *)infoForPSN:(ProcessSerialNumber)processSerialNumber {
  NSDictionary *dict = (NSDictionary *)ProcessInformationCopyDictionary(&processSerialNumber,kProcessDictionaryIncludeAllInformationMask);	
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


- (BOOL)handleProcessEvent:(NSEvent *)theEvent{
//	QSLog(@"event %@",theEvent);
	ProcessSerialNumber psn;
	psn.highLongOfPSN=[theEvent data1];
	psn.lowLongOfPSN=[theEvent data2];
	
	NSDictionary *processInfo = [self infoForPSN:psn];
 
  switch ([theEvent subtype]){
		case NSProcessDidLaunchSubType:
			if (![[NSUserDefaults standardUserDefaults]boolForKey:kQSShowBackgroundProcesses]) return YES;
      BOOL background=[[processInfo objectForKey:@"LSUIElement"]boolValue]||[[processInfo objectForKey:@"LSBackgroundOnly"]boolValue];
			if (!background) return YES;
				[self addProcessWithDict: processInfo];
			break;
		case NSProcessDidTerminateSubType:
			[self removeProcessWithPSN:psn];
			break;
		case NSFrontProcessSwitched:
			[[NSNotificationCenter defaultCenter] postNotificationName:QSActiveApplicationChangedNotification object: processInfo];
			[self appChanged:nil];
			break;
    default:
			break;
	}
	return YES;
};

- (void)appChanged:(NSNotification *)aNotification{
	NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
	NSDictionary *newApp=[workspace activeApplication];
	if ([[NSUserDefaults standardUserDefaults]boolForKey:@"Hide Other Apps When Switching"]){
		if (!(GetCurrentKeyModifiers() & shiftKey)){
			//if (VERBOSE)QSLog(@"Hide Other Apps");
			[workspace hideOtherApplications:[NSArray arrayWithObject:newApp]];
		}
	}
	
	[self setPreviousApplication:currentApplication];
	[self setCurrentApplication:newApp];
	
}

- (void)processTerminated:(QSObject *)thisProcess{
	//QSLog(@"Terminate:%@",thisProcess);
	[[thisProcess dataDictionary]removeObjectForKey:QSProcessType];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectModifiedNotification object:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessesChangedNotification object:nil];
	[processes removeObject:thisProcess];
}

- (void)removeProcessWithPSN:(ProcessSerialNumber)psn{
	QSObject *thisProcess=[self processObjectWithPSN:psn];
	//QSLog(@"remove psn %@",thisProcess);
	[self processTerminated:thisProcess];
}

- (QSObject *)processObjectWithDict:(NSDictionary *)dict{
	ProcessSerialNumber psn;
    if (noErr==GetPSNForAppInfo(&psn,dict))
		return [self processObjectWithPSN:psn];
	return nil;
}

- (void)appTerminated:(NSNotification *)notif{
	[self processTerminated:[self processObjectWithDict:[notif userInfo]]];	
}

- (void)appLaunched:(NSNotification *)notif{
	if (![processes count])
		[self reloadProcesses];
	else
		[self addProcessWithDict:[notif userInfo]];
	//    [self invalidateSelf];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSEventNotification
                                                        object:QSApplicationLaunchEvent
                                                      userInfo:[NSDictionary dictionaryWithObject:[self imbuedFileProcessForDict:[notif userInfo]] forKey:@"object"]];
}

- (void)addObserverForEvent:(NSString *)event trigger:(NSDictionary *)trigger{
	QSLog(@"Add %@",event);
}
- (void)removeObserverForEvent:(NSString *)event trigger:(NSDictionary *)trigger{	
	QSLog(@"Remove %@",event);
	
}

- (void)addProcessWithDict:(NSDictionary *)info{
	if ([self processObjectWithDict:info])return;
	
	
//	QSLog(@"addProcess %@",[info objectForKey:@"NSApplicationName"]);
	QSObject *thisProcess=[self imbuedFileProcessForDict:info];
//	QSLog(@"process %@",thisProcess);
	[processes addObject:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectModifiedNotification object:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessesChangedNotification object:nil];
}

- (NSArray *) getAllProcesses{
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses=[NDProcess everyProcess];
	
	NDProcess *thisProcess;
	pid_t pid=-1;
	//ProcessSerialNumber psn;
	for(thisProcess in newProcesses){
		newObject=nil;
		if ((newObject=[self imbuedFileProcessForDict:[thisProcess processInfo]]))
			[objects addObject:newObject];
		else
			QSLog(@"ignoring process id %d",pid); 
	}
	return objects;
	
	return nil;
}
- (NSArray *) getVisibleProcesses{
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses=[[NSWorkspace sharedWorkspace]launchedApplications]; //[NDProcess everyProcess];
	
	NSDictionary *thisProcess;
	for(thisProcess in newProcesses){
		
		if ((newObject=[self imbuedFileProcessForDict:thisProcess]))
			[objects addObject:newObject];
		// else
		//   QSLog(@"ignoring process id %d",pid); 
		
	}
	return objects;
	
	return nil;
}

- (NSArray *)processesWithHiddenState:(BOOL)hidden{
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses=[NDProcess everyProcess];
	
	NDProcess *thisProcess;
//	pid_t pid=-1;
	//ProcessSerialNumber psn;
	for(thisProcess in newProcesses){
		newObject=nil;
		if (hidden && [thisProcess isVisible])continue;
		else if ([thisProcess isBackground])continue;
			
		if ((newObject=[self imbuedFileProcessForDict:[thisProcess processInfo]]))
			[objects addObject:newObject];
	}
	
	
	return objects;
	
	return nil;
	
}

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict{
	NSString *bundlePath=[[dict objectForKey:@"NSApplicationPath"]stringByDeletingLastPathComponent];
	QSObject *newObject=nil;
	if ([[bundlePath lastPathComponent]isEqualToString:@"MacOS"] || [[bundlePath lastPathComponent]isEqualToString:@"MacOSClassic"]){
		bundlePath=[bundlePath stringByDeletingLastPathComponent];
		// ***warning   * check that this is the executable specified by the info.plist
		if ([[bundlePath lastPathComponent]isEqualToString:@"Contents"]){
			bundlePath=[bundlePath stringByDeletingLastPathComponent];
			newObject=[QSObject fileObjectWithPath:bundlePath];
			
			
		}
	}
	
	if (!newObject)
		newObject=[QSObject fileObjectWithPath:[dict objectForKey:@"NSApplicationPath"]]; 
	
	[newObject setObject:dict forType:QSProcessType];
	return newObject;
}

- (void)reloadProcesses{ 
	//QSLog(@"Reloading Processes");
	if ([[NSUserDefaults standardUserDefaults]boolForKey:kQSShowBackgroundProcesses])
		[processes setArray:[self getAllProcesses]];
	else
		[processes setArray:[self getVisibleProcesses]];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessesChangedNotification object:nil];
	
	//[self invalidateSelf];
}


-(NSArray *)visibleProcesses{
	return [self allProcesses];
	
}
-(NSArray *)allProcesses{
	if (![processes count])
		[self reloadProcesses];
//	QSLog(@"proc %@",processes);
	return processes;   
}
- (NSDictionary *)previousApplication{
	return previousApplication;	
}

-(id)resolveProxyObject:(id)proxy{
	if ([[proxy identifier]isEqualToString:@"QSCurrentApplicationProxy"]){
		//	QSLog(@"return");
		return [self imbuedFileProcessForDict:[[NSWorkspace sharedWorkspace]activeApplication]];
	}else if ([[proxy identifier] isEqualToString:@"QSPreviousApplicationProxy"]){
		return [self imbuedFileProcessForDict:previousApplication];
	}else if ([[proxy identifier] isEqualToString:@"QSHiddenApplicationsProxy"]){
		return [QSCollection collectionWithArray:[self processesWithHiddenState:YES]];
	}else if ([[proxy identifier] isEqualToString:@"QSVisibleApplicationsProxy"]){
		return [QSCollection collectionWithArray:[self processesWithHiddenState:NO]];
	}
	return nil;
}

- (NSTimeInterval)cacheTimeForProxy:(id)proxy{
	return 0.0f;	
}






- (NSDictionary *)currentApplication {
    return [[currentApplication retain] autorelease]; 
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



- (void)dealloc {
    [self setCurrentApplication:nil];
    [self setPreviousApplication:nil];
    [super dealloc];
}


@end
