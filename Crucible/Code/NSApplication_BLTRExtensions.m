//
//  NSApplication_Extensions.m
//  Quicksilver
//
//  Created by Alcor on Thu May 01 2003.

//

#import "NSApplication_BLTRExtensions.h"
#import "NSFileManager_BLTRExtensions.h"
#import "NSString_BLTRExtensions.h"
#import <unistd.h>
#import "CPSPrivate.h"

#import "QSBuildOptions.h"
@implementation NSApplication (Info)
- (BOOL)wasLaunchedAtLogin {
	return [[[NSApp parentProcessInformation] objectForKey:@"CFBundleIdentifier"] isEqualToString:@"com.apple.loginwindow"];
}

- (NSString *)buildVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)versionString {
    NSDictionary *infoDict = [[NSBundle mainBundle]infoDictionary];
    
    NSString * shortVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString * prereleaseString = PRERELEASEVERSION ? @"PRERELEASE " : @"";
    
    NSString *version = [NSString stringWithFormat:@"%@ %@(%@)", shortVersionString, prereleaseString, [infoDict objectForKey:@"CFBundleVersion"]];
    return version;
}

- (int)featureLevel{return 0;}

- (NSDictionary *)processInformation {
	ProcessSerialNumber currPSN;
	OSStatus err = GetCurrentProcess (&currPSN);
	if (!err) {
		NSDictionary *currDict = (NSDictionary*)ProcessInformationCopyDictionary (&currPSN, kProcessDictionaryIncludeAllInformationMask);
		return [currDict autorelease];
	}
	return nil;
}

- (NSDictionary *)parentProcessInformation {
	// Get the PSN of the app that *launched* us.  Its not really the parent app, in the unix sense.
	long long temp = [[[self processInformation] objectForKey:@"ParentPSN"] longLongValue];
	ProcessSerialNumber   parentPSN = {(temp >> 32) & 0x00000000FFFFFFFFLL, (temp >> 0) & 0x00000000FFFFFFFFLL};
	
	// Get info on the launching process
	NSDictionary*    parentDict = (NSDictionary*)ProcessInformationCopyDictionary (&parentPSN,kProcessDictionaryIncludeAllInformationMask);
	return [parentDict autorelease];
}

- (NSString *)applicationSupportFolder {
    FSRef foundRef;
    unsigned char path[1024];
    
	FSFindFolder( kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, & foundRef );
	FSRefMakePath( & foundRef, path, sizeof(path) );
    
    NSString *applicationSupportFolder;
	applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
	applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString*)kCFBundleNameKey]];
    
    return applicationSupportFolder;
}
@end

@implementation NSApplication (Focus)
- (BOOL) stealKeyFocus {
    CPSProcessSerNum psn;
	
    if((CPSGetCurrentProcess(&psn) == noErr) && (CPSStealKeyFocus(&psn) == noErr))
		return YES;
    
    return NO;
}

- (BOOL) releaseKeyFocus {
    CPSProcessSerNum psn;
	
    if((CPSGetCurrentProcess(&psn) == noErr) && (CPSReleaseKeyFocus(&psn) == noErr))
		return YES;
    
    return NO;
}
@end

@implementation NSApplication (Relaunching)
- (void)requestRelaunch:(id)sender {
    if (NSRunAlertPanel(@"Relaunch required", @"Quicksilver needs to be relaunched for some changes to take effect", @"Relaunch", @"Later", nil))
        [self relaunch:self];
}


- (void)relaunchAfterMovingFromPath:(NSString *)newPath {
	[self relaunchAtPath:[[NSBundle mainBundle] bundlePath] movedFromPath:newPath];
}

- (int)moveToPath:(NSString *)launchPath fromPath:(NSString *)newPath {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *tempPath = [[launchPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Quicksilver.old.app"];
	//QSLog(@"temp %@ new %@",tempPath,newPath);
	BOOL status;
	//[manager movePathWithAuthentication:launchPath toPath:newPath];
	status = [manager movePath:launchPath toPath:tempPath handler:nil];
	if (VERBOSE) QSLog(@"Move Old %d",status);
	status = [manager movePath:newPath toPath:launchPath handler:nil];
	if (VERBOSE) QSLog(@"Copy New %d",status);
	status = [manager movePathToTrash:tempPath];
	if (VERBOSE) QSLog(@"Trash Old %d",status);
	return status;
}

- (void)replaceWithUpdateFromPath:(NSString *)newPath {
	[self moveToPath:[[NSBundle mainBundle] bundlePath] fromPath:newPath];
}

- (void)relaunchAtPath:(NSString *)launchPath movedFromPath:(NSString *)newPath {
	[self moveToPath:launchPath fromPath:newPath];
	[self relaunchFromPath:launchPath];
	return;
//	
//	NSString *relauncherPath=[[NSBundle mainBundle]pathForResource:@"Relauncher" ofType:@""];
//	NSArray *arguments=[NSArray arrayWithObjects:
//		[NSString stringWithFormat:@"%d",[[NSProcessInfo processInfo]processIdentifier]],
//		launchPath,
//		newPath,
//		nil];
//	[NSTask launchedTaskWithLaunchPath:relauncherPath arguments:arguments];
//	
//	[self terminate:self];
//	
//	
}

- (void)relaunchFromPath:(NSString *)path {
	if (!path)
		path = [[NSBundle mainBundle] executablePath];
	else 
		path = [[NSBundle bundleWithPath:path] executablePath];
	QSLog(@"Relaunch from path %@",path);
	char pidstr[10]; 
	sprintf(pidstr,"%d",getpid());
	setenv("relaunchFromPid",pidstr,YES);
	[[NSNotificationCenter defaultCenter] postNotificationName:QSApplicationWillRelaunchNotification object:self userInfo:nil];
	[NSTask launchedTaskWithLaunchPath:path arguments:[NSArray array]];
	
	[self terminate:self];
}

- (IBAction)relaunch:(id)sender {
	[self relaunchFromPath:nil];
}

@end

@implementation NSApplication (LSUIElementManipulation)

- (BOOL)shouldBeUIElement {
	return [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"LSUIElement"] boolValue];
}

- (BOOL)setShouldBeUIElement:(BOOL)hidden {
	NSString * plistPath = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
	if( ( plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"] ) ) {
		if( [manager isWritableFileAtPath:plistPath] ) {
			NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
			[infoDict setObject:[NSNumber numberWithInt:hidden] forKey:@"LSUIElement"];
			[infoDict writeToFile:plistPath atomically:NO];
			[manager changeFileAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate]
                                   atPath:[[NSBundle mainBundle] bundlePath]];
			return YES;
		}
	}
	return NO;
}

@end


@implementation NSApplication (LaunchStatus)
- (QSApplicationLaunchStatusFlags)checkLaunchStatus {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastLocation = [defaults objectForKey:kLastUsedLocation];
    
	NSString *lastVersionString = [defaults objectForKey:kLastUsedVersion];
	NSString *thisVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];	
	
	if (!lastLocation && !lastVersionString) return QSApplicationFirstLaunch;

	int lastVersion = [lastVersionString respondsToSelector:@selector(hexIntValue)] ? [lastVersionString hexIntValue] : 0;
	int thisVersion = [thisVersionString hexIntValue];
	
	if( thisVersion > lastVersion ) return QSApplicationUpgradedLaunch;
	if( thisVersion < lastVersion ) return QSApplicationDowngradedLaunch;
	return QSApplicationNormalLaunch;
}

- (void)updateLaunchStatusInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *bundlePath = [[NSBundle mainBundle]bundlePath];
	NSString *thisVersionString = [[[NSBundle mainBundle]infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];	
	[defaults setObject:thisVersionString forKey:kLastUsedVersion];
	[defaults setObject:[bundlePath stringByAbbreviatingWithTildeInPath] forKey:kLastUsedLocation];
	[defaults synchronize];
}

@end
