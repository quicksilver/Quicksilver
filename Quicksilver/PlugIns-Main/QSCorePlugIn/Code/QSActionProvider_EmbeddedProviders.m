#import "NSPasteboard_BLTRExtensions.h"
#import "QSActionProvider_EmbeddedProviders.h"
#import "NSString+NDCarbonUtilities.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDAlias+AliasFile.h"
#import <Carbon/Carbon.h>

#import "QSController.h"
#import "NDAlias.h"
#import "QSRegistry.h"
#import "QSSimpleWebWindowController.h"

#import "QSLoginItemFunctions.h"
#import "QSFSBrowserMediator.h"
#import "QSNullObject.h"
#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSTaskController.h"

#import "NDAppleScriptObject.h"

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
# define kURLOpenWithAction @"URLOpenWithAction"
# define kURLJSAction @"URLJSAction"
# define kURLEmailAction @"URLEmailAction"

#import "NSPasteboard_BLTRExtensions.h"

#import "QSLSTools.h"

#import "QSInterfaceController.h"

@implementation URLActions
- (NSString *)defaultWebClient {
	NSURL *appURL = nil;
	OSStatus err = LSGetApplicationForURL((CFURLRef) [NSURL URLWithString: @"http:"], kLSRolesAll, NULL, (CFURLRef *)&appURL);
	if (err != noErr)
		NSLog(@"error %ld", err);
	return [appURL path];
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
	return [NSArray arrayWithObjects:kURLOpenAction, kURLOpenWithAction, nil];
}

- (QSObject *)doURLOpenAction:(QSObject *)dObject {
	NSMutableArray *urlArray = [NSMutableArray array];
	NSString *urlString;
	NSEnumerator *e = [[dObject arrayForType:QSURLType] objectEnumerator];
	while (urlString = [e nextObject]) {
		NSURL *url = [NSURL URLWithString:urlString];
		if ([urlString rangeOfString:QUERY_KEY].location != NSNotFound) {
			int pathLoc = [urlString rangeOfString:[url path]].location;
			if (pathLoc != NSNotFound)
				url = [NSURL URLWithString:[urlString substringWithRange:NSMakeRange(0, pathLoc)]];
		}
		url = [url URLByInjectingPasswordFromKeychain];
		if (url)
			[urlArray addObject:url];
		else
			NSLog(@"error with url: %@", urlString);
	}
	// TODO: Bring this back later
//	if (fALPHA && ![QSAction modifiersAreIgnored] && mOptionKeyIsDown) {
/*	if (mOptionKeyIsDown) {
		id cont = [[NSClassFromString(@"QSSimpleWebWindowController") alloc] initWithWindow:nil];
		[(QSSimpleWebWindowController *)cont openURL:[urlArray lastObject]];
		[[cont window] makeKeyAndOrderFront:nil];
	} else {*/
		[[NSWorkspace sharedWorkspace] openURLs:urlArray withAppBundleIdentifier:[dObject objectForMeta:@"QSPreferredApplication"] options:0 additionalEventParamDescriptor:nil launchIdentifiers:nil];
//	}
	return nil;
}

- (QSObject *)doURLOpenAction:(QSObject *)dObject with:(QSObject *)iObject {
	NSURL *url = [[NSURL URLWithString:[dObject objectForType:QSURLType]] URLByInjectingPasswordFromKeychain];
	NSString *ident = nil;
	if ([iObject isApplication]){
		ident = [[NSBundle bundleWithPath:[iObject singleFilePath]] bundleIdentifier];
		if (ident)
			[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:ident options:0 additionalEventParamDescriptor:nil launchIdentifiers:nil];
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
	if ([[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:[[dObject singleFilePath] stringByStandardizingPath]])
		return [NSArray arrayWithObject:kDiskEjectAction];
	else
		return nil;
}

- (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject {
	NSString *firstFile = [dObject singleFilePath];
	if (![[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:firstFile]) {
		NSDictionary *errorDict;
		NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Finder\" to eject disk \"%@\"", [[NSFileManager defaultManager] displayNameAtPath:firstFile]]];
			[script executeAndReturnError:&errorDict];
			[script release];
		if (errorDict) NSBeep();
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

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	NSMutableArray *validIndirects = [NSMutableArray arrayWithCapacity:1];
	if ([action isEqualToString:kFileOpenWithAction]) {
		NSURL *fileURL = nil;
		if ([dObject singleFilePath])
			fileURL = [NSURL fileURLWithPath:[dObject singleFilePath]];
		NSURL *appURL = nil;

		if (fileURL) LSGetApplicationForURL((CFURLRef) fileURL, kLSRolesAll, NULL, (CFURLRef *)&appURL);

		NSMutableSet *set = [NSMutableSet set];

		[set addObjectsFromArray:[(NSArray *)LSCopyApplicationURLsForURL((CFURLRef)fileURL, kLSRolesAll) autorelease]];
		[set addObjectsFromArray:[self universalApps]];

		validIndirects = [QSLib scoredArrayForString:nil inSet:[QSObject fileObjectsWithURLArray:[set allObjects]]];

		id preferred = [QSObject fileObjectWithPath:[appURL path]];
		if (!preferred)
			preferred = [NSNull null];

		return [NSArray arrayWithObjects:preferred, validIndirects, nil];
	} else if ([action isEqualToString:kFileRenameAction]) {
		NSString *path = [dObject singleFilePath];
		if (path)
			return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:[path lastPathComponent]]];
	} else if ([action isEqualToString:@"QSNewFolderAction"]) {
		return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@"untitled folder"]];
	} else if ([action isEqualToString:kFileMoveToAction]) {
		NSArray *fileObjects = [QSLib arrayForType:QSFilePathType];
		int i;
		BOOL isDirectory;
		for(i = 0; i<[fileObjects count]; i++) {
			QSObject *thisObject = [fileObjects objectAtIndex:i];
			NSString *path = [thisObject singleFilePath];
			if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
				if (isDirectory && ![[path pathExtension] length])
					[validIndirects addObject:thisObject];
			}
		}
		return validIndirects;
	}
	return nil;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSMutableArray *newActions = [NSMutableArray arrayWithObject:kFileGetPathAction];
	if ([dObject validPaths]){
		[newActions addObject:kFileOpenAction];
		[newActions addObject:kFileOpenWithAction];
		[newActions addObject:kFileRevealAction];
		[newActions addObject:kFileMakeLinkInAction];
		[newActions addObject:kFileDeleteAction];
		[newActions addObject:kFileToTrashAction];
		[newActions addObject:kFileMoveToAction];
		[newActions addObject:kFileCopyToAction];
		[newActions addObject:kFileGetInfoAction];
	}
	if ([dObject validSingleFilePath])
		[newActions addObject:kFileRenameAction];
//	[newActions addObject:kFileGetPathAction];
	return newActions;
}

- (BOOL)filesExist:(NSArray *)paths {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSEnumerator *files = [paths objectEnumerator];
	NSString *thisFile;
	while(thisFile = [files nextObject])
		if (![manager fileExistsAtPath:thisFile])
			return NO;
	return YES;
}

- (QSObject *)openFile:(QSObject *)dObject {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	LSItemInfoRecord infoRec;
	NSEnumerator *files = [[dObject validPaths] objectEnumerator];
	NSString *thisFile;
	while(thisFile = [files nextObject]) {
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:thisFile] , kLSRequestBasicFlagsOnly, &infoRec);
		if (!(infoRec.flags & kLSItemInfoIsContainer) || (infoRec.flags & kLSItemInfoIsPackage) || ![mQSFSBrowser openFile:thisFile]) {
			if (infoRec.flags & kLSItemInfoIsAliasFile) {
				NSString *aliasFile = [manager resolveAliasAtPathWithUI:thisFile];
				if (aliasFile && [manager fileExistsAtPath:aliasFile])
					thisFile = aliasFile;
			}
			NSString *fileHandler = [dObject objectForMeta:@"QSPreferredApplication"];
			if (fileHandler) {
				if (VERBOSE) NSLog(@"Using %@", fileHandler);
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

- (QSObject *)openFile:(QSObject *)dObject with:(QSObject *)iObject {
	if ([iObject isApplication]) {
		NSString *thisApp = [iObject singleFilePath];
		NSEnumerator *files = [[dObject validPaths] objectEnumerator];
		NSString *thisFile;
		while(thisFile = [files nextObject])
			[[NSWorkspace sharedWorkspace] openFile:thisFile withApplication:thisApp];
	} else {
		NSBeep();
	}
	return nil;
}

- (QSObject *)makeFolderIn:(QSObject *)dObject named:(QSObject *)iObject {
	NSString *theFolder = [dObject validSingleFilePath];
	NSString *newPath = [theFolder stringByAppendingPathComponent:[iObject stringValue]];
	[[NSFileManager defaultManager] createDirectoryAtPath:newPath attributes:nil];
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:theFolder];
	return [QSObject fileObjectWithPath:newPath];
}

- (QSObject *)revealFile:(QSObject *)dObject {
	NSEnumerator *files = [[dObject validPaths] objectEnumerator];
	// ***warning   * should resolve aliases
	NSString *thisFile;
	while(thisFile = [files nextObject])
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

	int choice = QSRunCriticalAlertSheet([(NSWindowController *)QSIC window], @"Delete File", [NSString stringWithFormat:@"Are you sure you want to PERMANENTLY delete:\r %@?", [selection componentsJoinedByString:@", "]], @"Delete", @"Cancel", nil);
	if (choice == 1) {
		NSEnumerator *files = [dObject enumeratorForType:QSFilePathType];
		NSString *thisFile;
		while(thisFile = [files nextObject]) {
			if ([[NSFileManager defaultManager] removeFileAtPath:thisFile handler:nil])
				[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[thisFile stringByDeletingLastPathComponent]];
			else
				NSLog(@"Could not delete file");
		}
	}
	return [QSObject nullObject];
}

- (QSBasicObject *)trashFile:(QSObject *)dObject {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSEnumerator *files = [[dObject arrayForType:QSFilePathType] objectEnumerator];
	NSString *thisFile;
	while(thisFile = [files nextObject]) {
		[ws performFileOperation:NSWorkspaceRecycleOperation source:[thisFile stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[thisFile lastPathComponent]] tag:nil];
		[ws noteFileSystemChanged:[thisFile stringByDeletingLastPathComponent]];
	}
	return [QSObject nullObject];
}

- (QSObject *)openItemAtLogin:(QSObject *)dObject {
	foreach(path, [dObject arrayForType:QSFilePathType]) {
		QSSetItemShouldLaunchAtLogin(path, YES, YES);
	}
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

	if ([[NSFileManager defaultManager] movePath:path toPath:destinationFile handler:nil])
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:container];
	else
		[[NSAlert alertWithMessageText:@"error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Error renaming File: %@ to %@", path, destinationFile] runModal];
	return [QSObject fileObjectWithPath:destinationFile];
}

- (QSObject *)duplicateFile:(QSObject *)dObject {
	// FIXME: Implement
	return nil;
}

- (QSObject *)moveFiles:(QSObject *)dObject toFolder:(QSObject *)iObject {return [self moveFiles:dObject toFolder:iObject shouldCopy:NO];}
- (QSObject *)copyFiles:(QSObject *)dObject toFolder:(QSObject *)iObject {return [self moveFiles:dObject toFolder:iObject shouldCopy:YES];}
- (QSObject *)moveFiles:(QSObject *)dObject toFolder:(QSObject *)iObject shouldCopy:(BOOL)copy {

	NSString *destination = [iObject singleFilePath];
	NSArray *filePaths = [dObject validPaths];
	if (!filePaths)
		return nil;

	NSFileManager *manager = [NSFileManager defaultManager];
	NSDictionary *conflicts = [manager conflictsForFiles:filePaths inDestination:destination]; //originals:keys destin:values
	NSArray *resultPaths = nil;

	if (conflicts) {
		NSMutableArray *otherFiles;
		NSLog(@"Conflicts: %@", conflicts);
		id panel = [QSFileConflictPanel conflictPanel];
		[panel setConflictNames:[conflicts allValues]];
		id QSIC = [[NSApp delegate] interfaceController];
//		[QSIC showMainWindow:nil];
		int copyMethod = [panel runModalAsSheetOnWindow:[QSIC window]];

		switch (copyMethod) {
			case QSCancelReplaceResolution:
				return nil;
			case QSReplaceFilesResolution: {
				NSString *file;
				NSEnumerator *enumerator = [[conflicts allValues] objectEnumerator];
				while(file = [enumerator nextObject]) {
					NSLog(file);
					[manager removeFileAtPath:file handler:nil];
				}
				break;
			}
			case QSDontReplaceFilesResolution:
				otherFiles = [[filePaths mutableCopy] autorelease];
				[otherFiles removeObjectsInArray:[conflicts allKeys]];
//				if (DEBUG) NSLog(@"Only moving %@", otherFiles);
					filePaths = otherFiles;
				break;
			case QSSmartReplaceFilesResolution: {
				NSTask *rsync = [NSTask taskWithLaunchPath:@"/usr/bin/rsync" arguments:[[[NSArray arrayWithObject:@"-auzEq"] arrayByAddingObjectsFromArray:filePaths] arrayByAddingObject:destination]];
				[rsync launch]; [rsync waitUntilExit]; [rsync release];
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
            int i;
            for(i = 0; i<[filePaths count]; i++) {
                NSString *thisFile = [filePaths objectAtIndex:i];
                NSString *destinationFile = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
                if (copy && [[NSFileManager defaultManager] copyPath:thisFile toPath:destinationFile handler:nil]) {
                    [newPaths addObject:destinationFile];
                } else if (!copy && [[NSFileManager defaultManager] movePath:thisFile toPath:destinationFile handler:nil]) {
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
	NSEnumerator *files = [dObject enumeratorForType:QSFilePathType];
	NSString *thisFile, *destinationFile;
	while(thisFile = [files nextObject]) {
		destinationFile = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
		if ([(NDAlias *)[NDAlias aliasWithPath:thisFile] writeToFile:destinationFile])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)makeLinkTo:(QSObject *)dObject inFolder:(QSObject *)iObject {
	NSString *destination = [iObject singleFilePath];
	NSEnumerator *files = [dObject enumeratorForType:QSFilePathType];
	NSString *thisFile, *destinationFile;
	while(thisFile = [files nextObject]) {
		destinationFile = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
		if ([[NSFileManager defaultManager] createSymbolicLinkAtPath:destinationFile pathContent:thisFile])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)makeHardLinkTo:(QSObject *)dObject inFolder:(QSObject *)iObject {
	NSString *thisFile, *destination = [iObject singleFilePath];
	NSEnumerator *files = [dObject enumeratorForType:QSFilePathType];
	while(thisFile = [files nextObject]) {
		if ([[NSFileManager defaultManager] linkPath:[destination stringByAppendingPathComponent:[thisFile lastPathComponent]] toPath:thisFile handler:nil])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)getFilePaths:(QSObject *)dObject { return [QSObject objectWithString:[[dObject arrayForType:QSFilePathType] componentsJoinedByString:@"\n"]];  }

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
# define kPasteboardExpandAction @"PasteboardExpandAction"

@implementation ClipboardActions
- (QSObject *)copyObject:(QSObject *)dObject {
	[dObject putOnPasteboard:[NSPasteboard generalPasteboard]];
	return nil;
}
- (QSObject *)pasteObject:(QSObject *)dObject {
	if ([dObject putOnPasteboard:[NSPasteboard generalPasteboard]]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
		[[NSApp keyWindow] orderOut:self];
		QSForcePaste();
	} else NSBeep();
	return nil;
}
@end
