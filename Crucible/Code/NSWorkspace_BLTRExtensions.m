//
//  NSWorkspace_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Fri May 09 2003.

//

#import "NSWorkspace_BLTRExtensions.h"
#import "NSApplication_BLTRExtensions.h"
//#import "QSApp.h"
#include <signal.h>
#include <unistd.h>

//#import "NSString+NDCarbonUtilities.h"

#import "Carbon/Carbon.h"
bool _LSCopyAllApplicationURLs(NSArray **array);
void cycleDock(){
    [[[[NSAppleScript alloc]initWithSource:@"tell application \"Dock\" to quit"]autorelease] executeAndReturnError:nil];
}

@implementation NSWorkspace (Misc)


- (NSString *)commentForFile:(NSString *)path;
{
	if (!path)return nil;
	if ([self applicationIsRunning:@"com.apple.finder"])
    {
        NSString* scriptText, *hfsPath;
        NSAppleScript *script;
        NSAppleEventDescriptor *aeDesc;
		
        CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
        hfsPath = (NSString *)CFURLCopyFileSystemPath(fileURL, kCFURLHFSPathStyle);
        CFRelease(fileURL);
		
        scriptText = [NSString stringWithFormat:@"tell application \"Finder\" to comment of item \"%@\"", hfsPath];
        script = [[[NSAppleScript alloc] initWithSource:scriptText] autorelease];
        aeDesc = [script executeAndReturnError:nil];
		//QSLog([aeDesc stringValue]);
		return [aeDesc stringValue];
    }else{
		NSBeep();
	}
    return nil;

}

- (BOOL)setComment:(NSString*)comment forFile:(NSString *)path;
{
    BOOL result = NO;
	
    // only call if Finder is running
   // finderProcess = [NTPM processWithName:@"Finder"];
    if ([self applicationIsRunning:@"com.apple.finder"])
    {
        NSString* scriptText, *hfsPath;
        NSAppleScript *script;
        NSAppleEventDescriptor *aeDesc;
		
        CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
        hfsPath = (NSString *)CFURLCopyFileSystemPath(fileURL, kCFURLHFSPathStyle);
        CFRelease(fileURL);
		
        scriptText = [NSString stringWithFormat:@"tell application \"Finder\" to set comment of item \"%@\" to \"%@\"", hfsPath, comment];
        script = [[[NSAppleScript alloc] initWithSource:scriptText] autorelease];
        aeDesc = [script executeAndReturnError:nil];
        result = (aeDesc != nil);
    }else{
		NSBeep();
	}
    return result;
}











- (NSArray *)allApplications{
    NSArray *appURLs = nil;
    //LSInit(1);
    _LSCopyAllApplicationURLs(&appURLs);
    NSMutableArray *apps=[NSMutableArray arrayWithCapacity:[appURLs count]];
    for (NSURL *url in appURLs){
        [apps addObject:[url path]];
		//[url release];
	}
	[appURLs release];
    return apps;
}

- (int)pidForApplication:(NSDictionary *)theApp{
    return [[theApp objectForKey: @"NSApplicationProcessIdentifier"]intValue];
}
- (BOOL)applicationIsRunning:(NSString *)pathOrID{
	if ([self dictForApplicationName:pathOrID]!=nil)return YES;
	if ([self dictForApplicationIdentifier:pathOrID]!=nil)return YES;
    return NO;   
}
- (NSDictionary *)dictForApplicationName:(NSString *)path{
	
	//QSLog(@"p%@",path);
    NSEnumerator *appEnumerator=[[self launchedApplications]objectEnumerator];
    NSDictionary *theApp;
    while((theApp=[appEnumerator nextObject])){
		//	QSLog(@"n%@",[theApp objectForKey:@"NSApplicationName"]);
        if ([[theApp objectForKey:@"NSApplicationPath"]isEqualToString:path]||[[theApp objectForKey:@"NSApplicationName"]isEqualToString:path])
            return theApp;
	}
    return nil;
}

- (NSDictionary *)dictForApplicationIdentifier:(NSString *)ident{
    NSEnumerator *appEnumerator=[[self launchedApplications]objectEnumerator];
    NSDictionary *theApp;
    while((theApp=[appEnumerator nextObject])){
		if ([[theApp objectForKey:@"NSApplicationBundleIdentifier"]isEqualToString:ident])
            return theApp;
	}
    return nil;
}


- (void)killApplication:(NSString *)path{
    NSDictionary *theApp=[self dictForApplicationName:path];
    if (!theApp) return;
    pid_t pid=[[theApp objectForKey:@"NSApplicationProcessIdentifier"]intValue];
    kill(pid,SIGKILL);
}


- (BOOL)applicationIsHidden:(NSDictionary *)theApp{
    ProcessSerialNumber psn;
    if ([self PSN:&psn forApplication:theApp])
        return!(IsProcessVisible(&psn));
    return YES;
}
- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp{
    return [self pidForApplication:theApp]==[self pidForApplication:[self activeApplication]];
}

- (BOOL)PSN:(ProcessSerialNumber *)psn forApplication:(NSDictionary *)theApp{
    if (!theApp) return NO;
    (*psn).highLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
    (*psn).lowLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
    return YES;
}

- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly{
    ProcessSerialNumber psn;
    if ([self PSN:&psn forApplication:theApp])
        SetFrontProcessWithOptions (&psn, (frontOnly ? kSetFrontProcessFrontWindowOnly : 0) );
    else
        [self activateApplication:theApp];
}

- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp{
    ProcessSerialNumber psn;
    if ([self PSN:&psn forApplication:theApp])
        SetFrontProcessWithOptions (&psn,kSetFrontProcessFrontWindowOnly);
    else
        [self activateApplication:theApp];
}

- (void)hideApplication:(NSDictionary *)theApp{    
    ProcessSerialNumber psn;
    if ([self PSN:&psn forApplication:theApp])
        ShowHideProcess(&psn,FALSE);
}


- (void)hideOtherApplications:(NSArray *)theApps{ 
	NSDictionary *theApp=[theApps lastObject];
	int count=[theApps count];
	int i;
    ProcessSerialNumber psn[count];
	for (i=0;i<count;i++)
		[self PSN:psn+i forApplication:[theApps objectAtIndex:i]];
	[self switchToApplication:theApp frontWindowOnly:YES];

	ProcessSerialNumber thisPSN;
	thisPSN.highLongOfPSN = kNoProcess;
	thisPSN.lowLongOfPSN = 0;
	Boolean show;
	while(GetNextProcess ( &thisPSN ) == noErr){
		for (i=0;i<[theApps count];i++){
			SameProcess(&thisPSN,psn+i,&show);
			if (show) break;
		}
	//	QSLog(@"same %d",show);
		ShowHideProcess(&thisPSN,show);  
	}    
}

- (void)quitOtherApplications:(NSArray *)theApps{ 
	NSDictionary *theApp=[theApps lastObject];
	int count=[theApps count];
	int i;
    ProcessSerialNumber psn[count];
	for (i=0;i<count;i++)
		[self PSN:psn+i forApplication:[theApps objectAtIndex:i]];
	[self reopenApplication:theApp];
	ProcessSerialNumber thisPSN;
	thisPSN.highLongOfPSN = kNoProcess;
	thisPSN.lowLongOfPSN = 0;
	Boolean show=NO;
	ProcessSerialNumber myPSN;
	MacGetCurrentProcess(&myPSN);
	
	
	while(GetNextProcess ( &thisPSN ) == noErr){
		NSDictionary *dict=(NSDictionary *)ProcessInformationCopyDictionary(&thisPSN,kProcessDictionaryIncludeAllInformationMask);	

		BOOL background=[[dict objectForKey:@"LSUIElement"]boolValue]||[[dict objectForKey:@"LSBackgroundOnly"]boolValue];
		[dict autorelease];
		if (background)continue;
		NSString *name;
		CopyProcessName(&thisPSN,(CFStringRef *)&name);
		if ([[name autorelease] isEqualToString:@"Finder"])continue;
		
		SameProcess(&thisPSN,&myPSN,&show);
		if (show)continue;
		
		for (i=0;i<[theApps count];i++){
			SameProcess(&thisPSN,psn+i,&show);
			if (show) break;
		}
		if (!show)
			[self quitPSN:thisPSN];
		//		ShowHideProcess(&thisPSN,show);  
	}    
}

- (void)showApplication:(NSDictionary *)theApp{
    ProcessSerialNumber psn;
    if ([self PSN:&psn forApplication:theApp])
        ShowHideProcess(&psn,TRUE);
}

- (void)activateApplication:(NSDictionary *)theApp{
    ProcessSerialNumber psn; //psn of target app, it's your business to get it.
    
    if (![self PSN:&psn forApplication:theApp]) return;
    AppleEvent event={typeNull,0};
    AEBuildError error;
    
    OSStatus err = AEBuildAppleEvent('misc', 'actv', typeProcessSerialNumber,
                                     &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID,
                                     &event, &error, "");
    
    if (err) QSLog(@"%d:%d at \"%@\"",error.fError,error.fErrorPos,@"");
    else
    {
        AppleEvent reply;
        err=AESend(&event,&reply,kAEWaitReply,kAENormalPriority,100,NULL,NULL);
        AEDisposeDesc(&event); // we must dispose of this and the reply.
    }
}

- (void)reopenApplication:(NSDictionary *)theApp{
    [self launchApplication:[theApp objectForKey:@"NSApplicationPath"]]; 
	// ***warning   * should learn to use reopen aevnt
    
    return;
    ProcessSerialNumber psn;
    if (![self PSN:&psn forApplication:theApp]) return;
    AppleEvent event={typeNull,0};
    AEBuildError error;
    
    OSStatus err = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber,
                                     &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID,
                                     &event, &error, "");
    
    
    if (err) QSLog(@"%d:%d at \"%@\"",error.fError,error.fErrorPos, @"");
    else{
        err=AESend(&event,NULL,kAENoReply,kAENormalPriority,kAEDefaultTimeout,NULL,NULL);
        AEDisposeDesc(&event); // we must dispose of this and the reply.
    }
    
    if (err) QSLog(@"error");
}

- (void)quitApplication:(NSDictionary *)theApp{
    ProcessSerialNumber psn;
    if (![self PSN:&psn forApplication:theApp]) return;
	[self quitPSN:psn];
}

- (void)quitPSN:(ProcessSerialNumber)psn{
	AppleEvent event={typeNull,0};
    AEBuildError error;
    
    OSStatus err = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber,
                                     &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID,
                                     &event, &error, "");
    
    if (err) QSLog(@"%d:%d at \"%@\"",error.fError,error.fErrorPos, @"");
    else{
        err=AESend(&event,NULL,kAENoReply,kAENormalPriority,kAEDefaultTimeout,NULL,NULL);
        AEDisposeDesc(&event); // we must dispose of this and the reply.
    }
    
    if (err) QSLog(@"error");
	
}


- (BOOL)quitApplicationAndWait:(NSDictionary *)theApp{
    ProcessSerialNumber psn;
    if (![self PSN:&psn forApplication:theApp]) return NO;
    AppleEvent event={typeNull,0};
    AEBuildError error;
    
    OSStatus err = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber,
                                     &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID,
                                     &event, &error, "");
    
    
    if (err) QSLog(@"%d:%d at \"%@\"",error.fError,error.fErrorPos, @"");
    else{
        err=AESend(&event,NULL,kAEWaitReply,kAENormalPriority,kAEDefaultTimeout,NULL,NULL);
        AEDisposeDesc(&event); // we must dispose of this and the reply.
    }
   
    if (err) QSLog(@"error");
	return err;
}


- (void)launchACopyOfApplication:(NSDictionary *)theApp{
	NSURL *url=[NSURL fileURLWithPath:[theApp objectForKey:@"NSApplicationPath"]];
	
	
	OSStatus            err;
	LSLaunchURLSpec     spec;
	spec.appURL=(CFURLRef)url;
	spec.itemURLs = NULL;
	
	spec.passThruParams = NULL;
	spec.launchFlags    = kLSLaunchNewInstance;
	spec.asyncRefCon    = NULL;
	
	err = LSOpenFromURLSpec( &spec, NULL );
	QSLog(@"err %d",err);
	//CFRelease( spec.appURL );
}
- (BOOL)openFileInBackground:(NSString *)fullPath{
	struct LSLaunchURLSpec launchSpec = {
		.appURL = NULL,
		.itemURLs = (CFArrayRef)[NSArray arrayWithObject:[NSURL fileURLWithPath:fullPath]],
		.passThruParams = NULL,
		.launchFlags = kLSLaunchAsync | kLSLaunchDontSwitch | kLSLaunchNoParams,
		.asyncRefCon = NULL,
	};
	return !LSOpenFromURLSpec(&launchSpec,  NULL);
}
- (void)relaunchApplication:(NSDictionary *)theApp{
	if ([[theApp objectForKey:@"NSApplicationProcessIdentifier"]intValue]==[[NSProcessInfo processInfo]processIdentifier]){
		[NSApp relaunch:nil];
	}
	
	ProcessSerialNumber psn;
    if (![self PSN:&psn forApplication:theApp]) return;

	
	[self quitApplicationAndWait:theApp];	
	
	
	int pid;
	//NSDate *date=[NSDate date];
	
	NSString *bundlePath=[[theApp objectForKey:@"NSApplicationPath"]stringByDeletingLastPathComponent];
	if ([[bundlePath lastPathComponent]isEqualToString:@"MacOS"] || [[bundlePath lastPathComponent]isEqualToString:@"MacOSClassic"]){
		bundlePath=[bundlePath stringByDeletingLastPathComponent];
		if ([[bundlePath lastPathComponent]isEqualToString:@"Contents"])
			bundlePath=[bundlePath stringByDeletingLastPathComponent];
		
	}else{
		bundlePath=[theApp objectForKey:@"NSApplicationPath"];
	}
	
	while(1){
		int status=GetProcessPID(&psn,&pid);
		QSLog(@"waiting for %@ to quit %d %d",bundlePath,status,pid);
		usleep(250000);
		if (status==0 || status==-600)break;
	}
	usleep(500000);	
	[self openFile:bundlePath];
	return;
}


/*
 - (BOOL)PSN:(ProcessSerialNumber *)psn forPID:(int)pid{
	 if (!theApp) return NO;
	 
	 (*psn).highLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
	 (*psn).lowLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
	 return YES;
 }
 */

//- (NSString *)nameForPSN:(psn)psn{
//	GetProcessForPID([self ownerPid], &psn)
//	CopyProcessName(&psn, &strProcessName)



- (NSString *)nameForPID:(int)pid{
	ProcessSerialNumber psn;
    if (!GetProcessForPID(pid,&psn)){
		NSString *name=nil;
		if (!CopyProcessName(&psn, (CFStringRef *)&name))
			return [name autorelease];
	}
	return nil;
}

- (NSString *)pathForPID:(int)pid{
	ProcessSerialNumber psn;
	FSRef ref;
    if (!GetProcessForPID(pid,&psn)){
		//NSString *name=nil;
		if (!GetProcessBundleLocation(&psn, &ref))
			return [NSString stringWithFSRef:&ref];
	}
	return nil;
}







@end
