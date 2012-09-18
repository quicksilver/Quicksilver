#import "NSPasteboard_BLTRExtensions.h"
#import "QSActionProvider_EmbeddedProviders.h"
#import "NSString+NDCarbonUtilities.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDAlias+AliasFile.h"
#import <Carbon/Carbon.h>

#import "QSController.h"
#import "QSRegistry.h"
#import "QSSimpleWebWindowController.h"

#import "QSFSBrowserMediator.h"
#import "QSNullObject.h"
#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSTaskController.h"

#import "QSAlertManager.h"
#import "QSTypes.h"

#import "NSPasteboard_BLTRExtensions.h"
#import "QSFileConflictPanel.h"
#import "QSProcessSource.h"
#import "QSResourceManager.h"

#import "NSObject+ReaperExtensions.h"
#import <Carbon/Carbon.h>

#import "QSTextProxy.h"

#import "QSLibrarian.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#import "NSURL_BLTRExtensions.h"

# define kURLOpenAction @"URLOpenAction"
# define kURLOpenActionInBackground @"URLOpenActionInBackground"
# define kURLOpenWithAction @"URLOpenWithAction"
# define kURLJSAction @"URLJSAction"
# define kURLEmailAction @"URLEmailAction"

#import "NSPasteboard_BLTRExtensions.h"

#import "QSLSTools.h"

#import "QSInterfaceController.h"

#import <AudioToolbox/AudioServices.h>

#import "LaunchAtLoginController.h"

@implementation URLActions

- (NSString *)defaultWebClient {
	NSURL *appURL = nil;
	OSStatus err = LSGetApplicationForURL((CFURLRef) [NSURL URLWithString: @"http:"], kLSRolesAll, NULL, (CFURLRef *)&appURL);
	if (err != noErr)
		NSLog(@"error %ld", (long)err);
    NSString *clientPath = [appURL path];
    [appURL release];
	return clientPath;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSString *urlString = [dObject objectForType:QSURLType];
//	NSMutableArray *newActions = [NSMutableArray arrayWithCapacity:1];
	if (urlString) {
		if ([urlString hasPrefix:@"javascript:"]) return [NSArray arrayWithObject:kURLJSAction];
		else if ([urlString hasPrefix:@"mailto:"]) return [NSArray arrayWithObject:kURLEmailAction];
	}
/*	[newActions addObject:kURLOpenAction];
	[newActions addObject:kURLOpenWithAction];
	return newActions; */
	return [NSArray arrayWithObjects:kURLOpenAction, kURLOpenWithAction, kURLOpenActionInBackground, nil];
}

// Method to only show apps in the 3rd pane for the 'Open with...' action
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{

	// only for 'Open URL with...' action
	if ([action isEqualToString:@"URLOpenWithAction"]) {

		NSMutableSet *set = [NSMutableSet set];
		
		// Base the list of apps on the URL in dObject (1st object if multiple are selected)
		NSURL *url = [NSURL URLWithString:[[dObject arrayForType:QSURLType] objectAtIndex:0]];
		
		// If for some reason no URLs given (current web page proxy)
		if(!url) {
			url = [NSURL URLWithString:@"http://"];
		}
		
		// Get the default app for the url
		NSURL *appURL = nil;
		LSGetApplicationForURL((CFURLRef)url, kLSRolesAll, NULL, (CFURLRef *)&appURL);
		
		// Set the default app to be 1st in the returned list
		id preferred = [QSObject fileObjectWithPath:[appURL path]];
		if (!preferred) {
			preferred = [NSNull null];
		}
				
		[set addObjectsFromArray:[(NSArray *)LSCopyApplicationURLsForURL((CFURLRef)url, kLSRolesAll) autorelease]];
		NSMutableArray *validIndirects = [[QSLibrarian sharedInstance] scoredArrayForString:nil inSet:[QSObject fileObjectsWithURLArray:[set allObjects]]];
		
		return [NSArray arrayWithObjects:preferred, validIndirects, nil];
	}
	
	return nil;
}


- (QSObject *)doURLOpenAction:(QSObject *)dObject {
	NSMutableArray *urlArray = [NSMutableArray array];

	for (NSString *urlString in [dObject arrayForType:QSURLType]) {
		// Escape characters (but not # or %)
		NSURL *url = [NSURL URLWithString:[urlString URLEncoding]];
		// replace QUERY_KEY *** with nothing if we're just opening the URL
		if ([urlString rangeOfString:QUERY_KEY].location != NSNotFound) {
			NSInteger pathLoc = [urlString rangeOfString:[url path]].location;
			if (pathLoc != NSNotFound)
				url = [NSURL URLWithString:[[urlString substringWithRange:NSMakeRange(0, pathLoc)] URLEncoding]];
		}
		url = [url URLByInjectingPasswordFromKeychain];
		if (url) {
			[urlArray addObject:url];
		}
		else {
			NSLog(@"error with url: %@", urlString);
		}
	}
	// TODO: Bring this back later
//	if (![QSAction modifiersAreIgnored] && mOptionKeyIsDown) {
/*	if (mOptionKeyIsDown) {
		id cont = [[NSClassFromString(@"QSSimpleWebWindowController") alloc] initWithWindow:nil];
		[(QSSimpleWebWindowController *)cont openURL:[urlArray lastObject]];
		[[cont window] makeKeyAndOrderFront:nil];
	} else {*/
		[[NSWorkspace sharedWorkspace] openURLs:urlArray withAppBundleIdentifier:[dObject objectForMeta:@"QSPreferredApplication"] options:0 additionalEventParamDescriptor:nil launchIdentifiers:nil];
//	}
	return nil;
}

- (QSObject *)doURLOpenActionInBackground:(QSObject *)dObject {
	NSMutableArray *urlArray = [NSMutableArray array];

	for (NSString *urlString in [dObject arrayForType:QSURLType]) {
		NSURL *url = [NSURL URLWithString:[urlString URLEncoding]];
		if ([urlString rangeOfString:QUERY_KEY].location != NSNotFound) {
			NSInteger pathLoc = [urlString rangeOfString:[url path]].location;
			if (pathLoc != NSNotFound)
				url = [NSURL URLWithString:[[urlString substringWithRange:NSMakeRange(0, pathLoc)] URLEncoding]];
		}
		url = [url URLByInjectingPasswordFromKeychain];
		if (url) {
			[urlArray addObject:url];
		}
		else {
			NSLog(@"error with url: %@", urlString);
		}
	}
	// TODO: Bring this back later
	//	if (![QSAction modifiersAreIgnored] && mOptionKeyIsDown) {
	/*	if (mOptionKeyIsDown) {
	 id cont = [[NSClassFromString(@"QSSimpleWebWindowController") alloc] initWithWindow:nil];
	 [(QSSimpleWebWindowController *)cont openURL:[urlArray lastObject]];
	 [[cont window] makeKeyAndOrderFront:nil];
	 } else {*/
	[[NSWorkspace sharedWorkspace] openURLs:urlArray withAppBundleIdentifier:[dObject objectForMeta:@"QSPreferredApplication"] options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
	//	}
	return nil;
}


- (QSObject *)doURLOpenAction:(QSObject *)dObject with:(QSObject *)iObject {
	NSArray *splitObjects = [iObject splitObjects];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	// Enumerate through list of files in dObject and apps in iObject
	for(QSObject *individual in splitObjects) {
		for (NSString *urlString in [dObject arrayForType:QSURLType]) {
			if([individual isApplication]) {		
				NSURL *url = [[NSURL URLWithString:[urlString URLEncoding]] URLByInjectingPasswordFromKeychain];
				NSString *ident = [[NSBundle bundleWithPath:[individual singleFilePath]] bundleIdentifier];
				[ws openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:ident
																		   options:0
													additionalEventParamDescriptor:nil
																 launchIdentifiers:nil];
			}
			// iObject isn't an app
			else {
				NSBeep();
			}			
		}
	}
	return nil;
}

- (QSObject *)doURLJSAction:(QSObject *)dObject {
	// NSURL *url = [NSURL URLWithString:[dObject primaryObject]];
	[self performJavaScript:[[dObject objectForType:QSURLType] URLDecoding]];
	return nil;
}

- (void)performJavaScript:(NSString *)jScript {
	NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:@"QSWebBrowserMediators"];
	if (!key) key = QSApplicationIdentifierForURL(@"javascript:");
	if (!key) key = QSApplicationIdentifierForURL(@"http:");

	id instance = [QSReg instanceForKey:key inTable:@"QSWebBrowserMediators"];

	//	NSLog(@"instance: %@ %@", instance, key);
	if ([instance respondsToSelector:@selector(performJavaScript:)])
		[instance performJavaScript:jScript];
}

@end

# define kDiskEjectAction @"DiskEjectAction"
# define kDiskForceEjectAction @"DiskForceEjectAction"
@implementation FSDiskActions

- (NSArray *)actions {
	QSAction *action = [QSAction actionWithIdentifier:kDiskEjectAction];
	[action setIcon:[QSResourceManager imageNamed:@"EjectMediaIcon"]];
	[action setProvider:self];
	return [NSArray arrayWithObject:action];
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSArray *paths = [dObject arrayForType:QSFilePathType];
	BOOL valid = NO;
	if (paths)
	{
		valid = YES;
		for (NSString *path in paths) {
			if (![[path stringByStandardizingPath] hasPrefix:@"/Volumes/"]) {
				valid = NO;
				break;
			}
		}
	}
	if (valid)
		return [NSArray arrayWithObject:kDiskEjectAction];
	else {
		return nil;
	}
}

- (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	for (NSString *mountedVolume in [dObject arrayForType:QSFilePathType]) {
	if ([[ws mountedLocalVolumePaths] containsObject:[mountedVolume stringByStandardizingPath]]) {
		NSError *err = nil;
        if (![ws unmountAndEjectDeviceAtURL:[NSURL fileURLWithPath:mountedVolume] error:&err]) {
			NSLog(@"Error unmounting: %@\nTrying to use Finder (via Applescript)",err);
            NSDictionary *errorDict = nil;
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Finder\" to eject disk \"%@\"", [[NSFileManager defaultManager] displayNameAtPath:mountedVolume]]];
            [script executeAndReturnError:&errorDict];
            [script release];
            if (errorDict) {
				NSBeep();
				NSLog(@"Error: %@",errorDict);
			}
        }
	}
	}
	return nil;
}

@end

@implementation FSActions

- (NSArray *)universalApps {
	if (!universalApps) {
		QSTaskController *qstc = [QSTaskController sharedInstance];
		[qstc updateTask:@"Updating Application Database" status:@"Updating Applications" progress:-1];
		universalApps = (NSArray *)LSCopyApplicationURLsForURL((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"wildcard" ofType:@"*"]], kLSRolesAll);
		[qstc removeTask:@"Updating Application Database"];
	}
	[self performSelector:@selector(setUniversalApps:) withObject:nil afterDelay:10*MINUTES extend:YES];
	return universalApps;
}

- (void)setUniversalApps:(NSArray *)anUniversalApps {
	if (universalApps != anUniversalApps) {
		[universalApps release];
		universalApps = [anUniversalApps retain];
	}
}

- (void)dealloc {
	[universalApps release];
	[super dealloc];
}

// This method validates the 3rd pane for the core plugin actions
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	// Only return an array if the dObject is a file
	if(![dObject validPaths]) {
		return nil;
	}
	NSMutableArray *validIndirects = [NSMutableArray arrayWithCapacity:1];
	if ([action isEqualToString:kFileOpenWithAction]) {
		NSURL *fileURL = nil;
		// comma trick - get a list of apps based on the 1st selected file
		fileURL = [NSURL  fileURLWithPath:[[dObject validPaths] objectAtIndex:0]];

		NSURL *appURL = nil;

		if (fileURL) LSGetApplicationForURL((CFURLRef) fileURL, kLSRolesAll, NULL, (CFURLRef *)&appURL);

		NSMutableSet *set = [NSMutableSet set];

		[set addObjectsFromArray:[(NSArray *)LSCopyApplicationURLsForURL((CFURLRef)fileURL, kLSRolesAll) autorelease]];
		[set addObjectsFromArray:[self universalApps]];

		validIndirects = [[QSLibrarian sharedInstance] scoredArrayForString:nil inSet:[QSObject fileObjectsWithURLArray:[set allObjects]]];

		id preferred = [QSObject fileObjectWithPath:[appURL path]];
		if (!preferred)
			preferred = [NSNull null];

        [appURL release];
		return [NSArray arrayWithObjects:preferred, validIndirects, nil];
	} else if ([action isEqualToString:kFileRenameAction]) {
		// return a text object (empty text box) to rename a file
		NSString *path = [dObject singleFilePath];
		if (path)
			return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:[path lastPathComponent]]];
	} else if ([action isEqualToString:@"QSNewFolderAction"]) {
		return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@"untitled folder"]];
	} else if ([action isEqualToString:kFileMoveToAction] || [action isEqualToString:kFileCopyToAction]) {
		// We only want folders for the move to / copy to actions (can't move to anything else)
        NSMutableArray *fileObjects = [[[QSLibrarian sharedInstance] arrayForType:QSFilePathType] mutableCopy];
		BOOL isDirectory;
        NSString *currentFolderPath = [[[[dObject splitObjects] lastObject] singleFilePath] stringByDeletingLastPathComponent];
        // if it wasn't in the catalog, create it from scratch
        if (currentFolderPath) {
            QSObject *currentFolderObject = [QSObject fileObjectWithPath:currentFolderPath];
            [fileObjects removeObject:currentFolderObject];
            [fileObjects insertObject:currentFolderObject atIndex:0];
        }
        NSWorkspace *ws = [[NSWorkspace sharedWorkspace] retain];
        NSFileManager *fm = [[NSFileManager alloc] init];
		for(QSObject *thisObject in fileObjects) {
			NSString *path = [thisObject singleFilePath];
			if ([fm fileExistsAtPath:path isDirectory:&isDirectory]) {
				if (isDirectory && ![ws isFilePackageAtPath:path])
					[validIndirects addObject:thisObject];
			}
		}
        [fileObjects release];
        [ws release];
        [fm release];
		return validIndirects;
	}
	return nil;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSMutableArray *newActions = [NSMutableArray arrayWithObject:kFileGetPathAction];
	if ([dObject validPaths]) {
		[newActions addObject:kFileOpenAction];
		[newActions addObject:kFileOpenWithAction];
		[newActions addObject:kFileRevealAction];
		[newActions addObject:kFileMakeLinkInAction];
		[newActions addObject:kFileDeleteAction];
		[newActions addObject:kFileToTrashAction];
		[newActions addObject:kFileMoveToAction];
		[newActions addObject:kFileCopyToAction];
		[newActions addObject:kFileGetInfoAction];
      // !!! Andre Berg 20091112: shouldn't the following also be added?
      [newActions addObject:kFileAlwaysOpenWithAction];
	}
	if ([dObject validSingleFilePath])
		[newActions addObject:kFileRenameAction];
	return newActions;
}

- (BOOL)filesExist:(NSArray *)paths {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *thisFile;
	for(thisFile in paths)
		if (![manager fileExistsAtPath:thisFile])
			return NO;
	return YES;
}

- (QSObject *)openFile:(QSObject *)dObject {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	LSItemInfoRecord infoRec;
	for(NSString *thisFile in [dObject validPaths]) {
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:thisFile] , kLSRequestBasicFlagsOnly, &infoRec);
		if (!(infoRec.flags & kLSItemInfoIsContainer) || (infoRec.flags & kLSItemInfoIsPackage) || ![mQSFSBrowser openFile:thisFile]) {
			if (infoRec.flags & kLSItemInfoIsAliasFile) {
				NSString *aliasFile = [manager resolveAliasAtPathWithUI:thisFile];
				if (aliasFile && [manager fileExistsAtPath:aliasFile])
					thisFile = aliasFile;
			}
			NSString *fileHandler = [dObject objectForMeta:@"QSPreferredApplication"];
			if (fileHandler) {
#ifdef DEBUG
				if (VERBOSE) NSLog(@"Using %@", fileHandler);
#endif
				[ws openFile:thisFile withApplication:[ws absolutePathForAppBundleWithIdentifier:fileHandler]];
			} else {
//				if (![QSAction modifiersAreIgnored] && (GetCurrentKeyModifiers() & shiftKey)) { // Open in background
//					NSLog(@"Launching in Background");
//					[ws openFileInBackground:thisFile];
//				} else {
					[ws openFile:thisFile];
//				}
			}
		}
	}
	return nil;
}

- (QSObject *)alwaysOpenFile:(QSObject *)dObject with:(QSObject *)iObject {
	FSRef ref;
	[[dObject singleFilePath] getFSRef:&ref];
	CFStringRef type;
	LSCopyItemAttribute(&ref, kLSRolesNone, kLSItemContentType, (CFTypeRef *)&type);
	LSSetDefaultRoleHandlerForContentType(type, kLSRolesAll, (CFStringRef) [[NSBundle bundleWithPath:[iObject singleFilePath]] bundleIdentifier]);
	CFRelease(type);
	return nil;
}

// FileOpenWithAction
- (QSObject *)openFile:(QSObject *)dObject with:(QSObject *)iObject {
	NSArray *splitObjects = [iObject splitObjects];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	// Enumerate through list of files in dObject and apps in iObject
	for(QSObject *individual in splitObjects) {
		for(NSString *thisFile in [dObject validPaths]) {
			// If there's only a single value in iObject
			if([individual isApplication]) {
				[ws openFile:thisFile withApplication:[individual singleFilePath]];
			}
			else {
				NSBeep();
			}
		}
	}	
	return nil;
}

- (QSObject *)makeFolderIn:(QSObject *)dObject named:(QSObject *)iObject {
	NSString *theFolder = [dObject validSingleFilePath];
	NSString *newPath = [theFolder stringByAppendingPathComponent:[iObject stringValue]];
	[[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:NO attributes:nil error:nil];
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:theFolder];
	return [QSObject fileObjectWithPath:newPath];
}

- (QSObject *)revealFile:(QSObject *)dObject {
	// ***warning   * should resolve aliases
	for(NSString *thisFile in [dObject validPaths])
		[mQSFSBrowser revealFile:thisFile];
	return nil;
}

- (QSObject *)getInfo:(QSObject *)dObject {
	[[QSReg getMediator:kQSFSBrowserMediators] getInfoForFiles:[dObject validPaths]];
	return nil;
}

- (QSBasicObject *)deleteFile:(QSObject *)dObject {
	NSArray *selection = [[dObject arrayForType:QSFilePathType] valueForKey:@"lastPathComponent"];

	// ***warning   * activate before showing
	id QSIC = [[NSApp delegate] interfaceController];
	[QSIC showMainWindow:nil];
	[QSIC setHiding:YES];

	NSInteger choice = QSRunCriticalAlertSheet([(NSWindowController *)QSIC window], @"Delete File", [NSString stringWithFormat:@"Are you sure you want to PERMANENTLY delete:\r %@?", [selection componentsJoinedByString:@", "]], @"Delete", @"Cancel", nil);
	[QSIC setHiding:NO];
	if (choice == 1) {
		NSString *lastDeletedFile = nil;
		for(NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
			if ([[NSFileManager defaultManager] removeItemAtPath:thisFile error:nil]) {
				[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[thisFile stringByDeletingLastPathComponent]];
				lastDeletedFile = thisFile;
			} else {
				NSLog(@"Could not delete file");
			}
		}
		// get settings for playing sound
		Boolean isSet;
		CFIndex val = CFPreferencesGetAppIntegerValue(CFSTR("com.apple.sound.uiaudio.enabled"),
													   CFSTR("com.apple.systemsound"),
													   &isSet);
		if (val == 1 || !isSet) {
			// play trash sound
			CFURLRef soundURL = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"dragToTrash" ofType:@"aif"]];
			SystemSoundID soundId;
			AudioServicesCreateSystemSoundID(soundURL, &soundId);
			AudioServicesPlaySystemSound(soundId);
		}

		// return folder that contained the last file that was deleted
		return [QSObject fileObjectWithPath:[lastDeletedFile stringByDeletingLastPathComponent]];;
	}
	
	// permanent delete was canceled, so leave files in first pane again
	return nil;
}

- (QSBasicObject *)trashFile:(QSObject *)dObject {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *lastDeletedFile = nil;
	for(NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
		[ws performFileOperation:NSWorkspaceRecycleOperation source:[thisFile stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[thisFile lastPathComponent]] tag:nil];
		[ws noteFileSystemChanged:[thisFile stringByDeletingLastPathComponent]];
		lastDeletedFile = thisFile;
	}
	
	// get settings for playing sound
	Boolean isSet;
	CFIndex val = CFPreferencesGetAppIntegerValue(CFSTR("com.apple.sound.uiaudio.enabled"),
												   CFSTR("com.apple.systemsound"),
												   &isSet);
	if (val == 1 || !isSet) {
		// play trash sound
		CFURLRef soundURL = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"dragToTrash" ofType:@"aif"]];
		SystemSoundID soundId;
		AudioServicesCreateSystemSoundID(soundURL, &soundId);
		AudioServicesPlaySystemSound(soundId);
	}

	// return folder that contained the last file that was deleted
	return [QSObject fileObjectWithPath:[lastDeletedFile stringByDeletingLastPathComponent]];;
}

- (QSObject *)openItemAtLogin:(QSObject *)dObject {
	LaunchAtLoginController *launch = [[LaunchAtLoginController alloc] init];
	for (NSString * path in [dObject arrayForType:QSFilePathType]) {
		[launch setLaunchAtLogin:YES forURL:[NSURL fileURLWithPath:path]];
	}
	[launch release];
	return nil;
}

- (QSObject *)doNotOpenItemAtLogin:(QSObject *)dObject {
	LaunchAtLoginController *launch = [[LaunchAtLoginController alloc] init];
	for (NSString *path in [dObject arrayForType:QSFilePathType]) {
		[launch setLaunchAtLogin:NO forURL:[NSURL fileURLWithPath:path]];
	}
	[launch release];
	return nil;
}

- (QSObject *)renameFile:(QSObject *)dObject withName:(QSObject *)iObject {
	NSString *path = [dObject singleFilePath];

	NSString *container = [path stringByDeletingLastPathComponent];
	NSString *newName = [iObject objectForType:QSTextType];

	if ([newName rangeOfString:@":"].location != NSNotFound)
		newName = nil;

	// ***warning   * check the filesystem
	if (![[newName pathExtension] length] && [[path pathExtension] length])
		newName = [newName stringByAppendingPathExtension:[path pathExtension]];
	if (!newName) {
		NSBeep();
		return nil;
	}
	newName = [newName stringByReplacing:@"/" with:@":"];

	NSString *destinationFile = [container stringByAppendingPathComponent:newName];

	if ([[NSFileManager defaultManager] moveItemAtPath:path toPath:destinationFile error:nil]) {
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:container];
		QSObject *renamed = [QSObject fileObjectWithPath:destinationFile];
		if ([[renamed displayName] isEqualToString:[dObject displayName]]) {
			/* label is preferred over name. They should be the same here,
			   but since label comes from Spotlight metadata, there can be
			   a delay causing the original filename to appear. If that
			   happens, ignore (wipe out) the invalid label, allowing the
			   new name to appear.
			*/
			[renamed setLabel:nil];
		}
		return renamed;
	} else {
		NSString *errorMessage = [NSString stringWithFormat:@"Error renaming File: %@ to %@", path, destinationFile];
		QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"QSRenameFileFailed", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, @"Quicksilver File Rename", QSNotifierTitle, errorMessage, QSNotifierText, nil]);
	}
	return nil;
}

- (QSObject *)duplicateFile:(QSObject *)dObject {
	// FIXME: Implement
	return nil;
}

- (QSObject *)moveFiles:(QSObject *)dObject toFolder:(QSObject *)iObject {return [self moveFiles:dObject toFolder:iObject shouldCopy:NO];}

- (QSObject *)copyFiles:(QSObject *)dObject toFolder:(QSObject *)iObject 
{

	if (dObject == iObject) {
		NSLog(@"Can't copy file to same destination as original file!");
	}
	return [self moveFiles:dObject toFolder:iObject shouldCopy:YES];
}

- (QSObject *)moveFiles:(QSObject *)dObject toFolder:(QSObject *)iObject shouldCopy:(BOOL)copy {

	NSString *destination = [iObject singleFilePath];
	NSArray *filePaths = [dObject validPaths];
	if (!filePaths)
		return nil;

	NSFileManager *manager = [NSFileManager defaultManager];
	NSDictionary *conflicts = [manager conflictsForFiles:filePaths inDestination:destination];
	NSArray *resultPaths = nil;

	if (conflicts) {
		NSMutableArray *otherFiles;
		NSLog(@"Conflicts: %@", conflicts);
		id panel = [QSFileConflictPanel conflictPanel];
		[panel setConflictNames:[conflicts allValues]];
		id QSIC = [[NSApp delegate] interfaceController];
		[QSIC showMainWindow:nil];
		[QSIC setHiding:YES];
		QSFileConflictResolutionMethod copyMethod = [panel runModalAsSheetOnWindow:[QSIC window]];
		[QSIC setHiding:NO];

		switch (copyMethod) {
			case QSCancelReplaceResolution:
				return nil;
			case QSReplaceFilesResolution: {
            for (NSString *file in [conflicts allValues])
            {
					NSLog(@"%@", file);
               if ([file hasPrefix:destination]) {
                  NSLog(@"File %@ already exists in %@", file, destination);
                  continue;
               }
               [manager removeItemAtPath:file error:nil];
            }
				break;
			}
			case QSDontReplaceFilesResolution:
				otherFiles = [[filePaths mutableCopy] autorelease];
				[otherFiles removeObjectsInArray:[conflicts allKeys]];
#ifdef DEBUG
				NSLog(@"Only moving %@", otherFiles);
#endif
            filePaths = otherFiles;
				break;
			case QSSmartReplaceFilesResolution: {
				NSTask *rsync = [NSTask taskWithLaunchPath:@"/usr/bin/rsync" arguments:[[[NSArray arrayWithObject:@"-auzEq"] arrayByAddingObjectsFromArray:filePaths] arrayByAddingObject:destination]];
				[rsync launch]; [rsync waitUntilExit];
				return nil;
				break;
			}
		}
	}
    
    if( [filePaths count] == 0 ) {
        NSLog(@"No file left to move");
        return nil;
    } else {
        resultPaths = (copy) ? [mQSFSBrowser copyFiles:filePaths toFolder:destination] : [mQSFSBrowser moveFiles:filePaths toFolder:destination];
        
        if (resultPaths) {
            if ([resultPaths count] <[filePaths count])
                NSLog(@"Finder-based move may not return all paths");
            return [QSObject fileObjectWithArray:resultPaths];
        } else {
            NSLog(@"Finder move failed");
        }
        
        if (!resultPaths) {
            //		if (DEBUG) NSLog(@"Using NSFileManager");
            NSMutableArray *newPaths = [NSMutableArray arrayWithCapacity:[filePaths count]];
            for(NSString *thisFile in filePaths) {
                NSString *destinationFile = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
                if (copy && [[NSFileManager defaultManager] copyItemAtPath:thisFile toPath:destinationFile error:nil]) {
                    [newPaths addObject:destinationFile];
                } else if (!copy && [[NSFileManager defaultManager] moveItemAtPath:thisFile toPath:destinationFile error:nil]) {
                    [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[thisFile stringByDeletingLastPathComponent]];
                    [newPaths addObject:destinationFile];
                } else {
                    [[NSAlert alertWithMessageText:@"Move Error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Error Moving File: %@ to %@", thisFile, destination] runModal];
                }
            }
            [[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
            return [QSObject fileObjectWithArray:newPaths];
        }
	}
	return nil;
}

- (QSObject *)makeAliasTo:(QSObject *)dObject inFolder:(QSObject *)iObject {
	NSString *destination = [iObject singleFilePath];
	NSString *destinationFile;
	for(NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
		destinationFile = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
		if ([(NDAlias *)[NDAlias aliasWithPath:thisFile] writeToFile:destinationFile])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)makeLinkTo:(QSObject *)dObject inFolder:(QSObject *)iObject {
	NSString *destination = [iObject singleFilePath];
	for(NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
		if ([[NSFileManager defaultManager] createSymbolicLinkAtPath:[destination stringByAppendingPathComponent:[thisFile lastPathComponent]] withDestinationPath:thisFile error:nil])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)makeHardLinkTo:(QSObject *)dObject inFolder:(QSObject *)iObject {
	NSString *destination = [iObject singleFilePath];
	for(NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
		if ([[NSFileManager defaultManager] linkItemAtPath:thisFile toPath:[destination stringByAppendingPathComponent:[thisFile lastPathComponent]] error:nil])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)getFilePaths:(QSObject *)dObject withTilde:(BOOL)withTilde
{
    // get an array of paths from files in the first pane
    NSArray *paths = nil;
    if (withTilde)
    {
        paths = [[dObject arrayForType:QSFilePathType] arrayByPerformingSelector:@selector(stringByAbbreviatingWithTildeInPath)];
    } else {
        paths = [dObject arrayForType:QSFilePathType];
    }
    // the name/label should be a one-line string
    QSObject *pathResult = [QSObject objectWithName:[paths componentsJoinedByString:@", "]];
    // use something other than the path to prevent this from clobbering the existing file (if it's in the catalog)
    [pathResult setIdentifier:@"GetPathActionResult"];
    // store all paths separated by newlines
    // allow it to be used as text (Large Type, Paste, etc.)
    [pathResult setObject:[paths componentsJoinedByString:@"\n"] forType:QSTextType];
    [pathResult setPrimaryType:QSTextType];
    return pathResult;
}

- (QSObject *)getFilePaths:(QSObject *)dObject
{
    return [self getFilePaths:dObject withTilde:YES];
}

- (QSObject *)getAbsoluteFilePaths:(QSObject *)dObject
{
    return [self getFilePaths:dObject withTilde:NO];
}

- (QSObject *)getFileURLs:(QSObject *)dObject {
	return [QSObject objectWithString:[[NSURL performSelector:@selector(fileURLWithPath:) onObjectsInArray:[dObject arrayForType:QSFilePathType] returnValues:YES] componentsJoinedByString:@"\n"]];
}
- (QSObject *)getFileLocations:(QSObject *)dObject {
	return [QSObject objectWithString:[[[dObject arrayForType:QSFilePathType] arrayByPerformingSelector:@selector(fileSystemPathHFSStyle)] componentsJoinedByString:@"\n"]];
}

@end

# define kAppLaunchAction @"AppLaunchAction"
# define kAppRootLaunchAction @"AppRootLaunchAction"
# define kAppLaunchAgainAction @"AppLaunchAgainAction"

@implementation AppActions
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
/*	NSMutableArray *newActions = [NSMutableArray arrayWithCapacity:1];
	if (![dObject objectForType:QSProcessType])
		[newActions addObject:kAppLaunchAction];
	return newActions;*/
	return [dObject objectForType:QSProcessType] ? nil : [NSArray arrayWithObject:kAppLaunchAction];
}
@end

# define kPasteboardPasteAction @"PasteboardPasteAction"

@implementation ClipboardActions
- (QSObject *)copyObject:(QSObject *)dObject {
	[dObject putOnPasteboard:[NSPasteboard generalPasteboard]];
	return nil;
}
- (QSObject *)pasteObject:(QSObject *)dObject {
	
	[self pasteObject:dObject asPlainText:NO];
	return nil;
}
- (QSObject *)pasteObjectAsPlainText:(QSObject *)dObject {

	[self pasteObject:dObject asPlainText:YES];
	return nil;
}
- (QSObject *)pasteObject:(QSObject *)dObject asPlainText:(BOOL)plainText {
	
	BOOL success;
	if(plainText) {
		success = [dObject putOnPasteboardAsPlainTextOnly:[NSPasteboard generalPasteboard]];
	}
	else {
		success = [dObject putOnPasteboard:[NSPasteboard generalPasteboard]];
	}
	if(success) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
		[[NSApp keyWindow] orderOut:self];
		QSForcePaste();
	} else NSBeep();
	return nil;
}
@end
