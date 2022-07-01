#import "NSPasteboard_BLTRExtensions.h"
#import "QSActionProvider_EmbeddedProviders.h"
#import "NSString+NDCarbonUtilities.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDAlias+AliasFile.h"

#import "QSController.h"
#import "QSRegistry.h"
#import "QSSimpleWebWindowController.h"

#import "QSFSBrowserMediator.h"
#import "QSNullObject.h"
#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSTaskController.h"

#import "NSAlert_QSExtensions.h"
#import "QSTypes.h"

#import "NSPasteboard_BLTRExtensions.h"
#import "QSFileConflictPanel.h"
#import "QSProcessSource.h"
#import "QSResourceManager.h"

#import "NSObject+ReaperExtensions.h"

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

- (id)resolveProxyObject:(id)proxy {
    QSObject *fileObject = [self defaultBrowserQSObjectForURL:[self URLForString:nil]];
    if (!fileObject) {
        QSShowAppNotifWithAttributes(@"QSURLProxy", NSLocalizedStringForThisBundle(@"Resolving Proxy failed", @"Error title shown when no a proxy object cannot be resolved"), NSLocalizedStringForThisBundle(@"Unable to find default browser", @"Error message for when the default browser proxy cannot be found"));
    }
    return fileObject;
}

- (NSString *)defaultWebClient {
    CFURLRef urlRef = NULL;
	OSStatus err = LSGetApplicationForURL((__bridge CFURLRef) [NSURL URLWithString: @"http:"], kLSRolesAll, NULL, &urlRef);
	if (err != noErr)
		NSLog(@"error %ld", (long)err);
    NSString *clientPath = [((__bridge NSURL *)urlRef) path];
    CFRelease(urlRef);
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

- (NSURL *)URLForString:(NSString *)urlString {
    
    NSURL *url = [NSURL URLWithString:urlString];

    // No URL given (current web page proxy), use default http://
    if(!url) {
        url = [NSURL URLWithString:@"http://"];
    }
    return url;
}

- (QSObject *)defaultBrowserQSObjectForURL:(NSURL *)url {
    
    // Get the default app for the url
    CFURLRef urlRef = NULL;
    LSGetApplicationForURL((__bridge CFURLRef)url, kLSRolesAll, NULL, &urlRef);
    NSURL *appURL = (__bridge_transfer NSURL *)urlRef;
    
    return [QSObject fileObjectWithPath:[appURL path]];
}

// Method to only show apps in the 3rd pane for the 'Open with...' action
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
    
	// 'Open URL with...' action
	if ([action isEqualToString:@"URLOpenWithAction"]) {
        
        // Get the default app to set it 1st in the returned list
        NSURL *url = [self URLForString:[[dObject arrayForType:QSURLType] objectAtIndex:0]];
		id preferred = [self defaultBrowserQSObjectForURL:url];
        
		if (!preferred) {
			preferred = [NSNull null];
		}
        
		NSArray *allApps = [QSObject fileObjectsWithURLArray:(__bridge_transfer NSArray *)LSCopyApplicationURLsForURL((__bridge CFURLRef)url, kLSRolesAll)];
		NSMutableArray *validIndirects = [[QSLibrarian sharedInstance] scoredArrayForString:nil inSet:allApps];
		
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
		if ([dObject containsType:QSSearchURLType]) {
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
		if ([dObject containsType:QSSearchURLType]) {
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

// This method validates the 3rd pane for the core plugin actions
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	// Only return an array if the dObject is a file
	if(![dObject validPaths]) {
		return nil;
	}
	if ([action isEqualToString:kFileOpenWithAction]) {
		NSURL *fileURL = nil;
		// comma trick - get a list of apps based on the 1st selected file
		fileURL = [NSURL fileURLWithPath:[[dObject validPaths] objectAtIndex:0]];

        NSURL *preferredAppURL = nil;
        if (fileURL) {
            CFURLRef urlRef = NULL;
            LSGetApplicationForURL((__bridge CFURLRef) fileURL, kLSRolesAll, NULL, &urlRef);
            if (urlRef) {
                preferredAppURL = (__bridge_transfer NSURL*)urlRef;
            }
        }

        NSArray *fileObjects = [QSLib arrayForType:QSFilePathType];
        
		id preferred = [QSObject fileObjectWithPath:[preferredAppURL path]];
        
        NSIndexSet *applicationIndexes = [fileObjects indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *thisObject, NSUInteger i, BOOL *stop) {
            QSObject *resolved = [thisObject resolvedAliasObject];
            return ([resolved isApplication] && thisObject != preferred);
        }];
        if (!preferred) {
            // no default app, leave the 1st pane blank
            preferred = [NSNull null];
        }
        return [[NSArray arrayWithObject:preferred] arrayByAddingObjectsFromArray:[fileObjects objectsAtIndexes:applicationIndexes]];
	} else if ([action isEqualToString:kFileRenameAction]) {
		// return a text object (empty text box) to rename a file
		NSString *path = [dObject singleFilePath];
		if (path)
			return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:[path lastPathComponent]]];
	} else if ([action isEqualToString:@"QSNewFolderAction"]) {
		return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@"untitled folder"]];
	} else if ([action isEqualToString:kFileMoveToAction] || [action isEqualToString:kFileCopyToAction]) {
        // We only want folders for the move to / copy to actions (can't move to anything else)
        NSArray *fileObjects = [[QSLibrarian sharedInstance] arrayForType:QSFilePathType];
        NSString *currentFolderPath = [[[dObject validPaths] lastObject] stringByDeletingLastPathComponent];

        // if the parent directory was found, put it first - otherwise, leave the pane blank
        id currentFolderObject = currentFolderPath ? [QSObject fileObjectWithPath:currentFolderPath] : [NSNull null];
        
        NSIndexSet *folderIndexes = [fileObjects indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *thisObject, NSUInteger i, BOOL *stop) {
            QSObject *resolved = [thisObject resolvedAliasObject];
            return ([resolved isFolder] && (thisObject != currentFolderObject));
        }];
        
        return [[NSArray arrayWithObject:currentFolderObject] arrayByAddingObjectsFromArray:[fileObjects objectsAtIndexes:folderIndexes]];
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
        // can all files be trashed?
        for (QSObject *file in [dObject splitObjects]) {
            if (![[file resolvedAliasObject] isOnLocalVolume]) {
                [newActions removeObject:kFileToTrashAction];
                break;
            }
        }
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


- (BOOL)openURLs:(NSArray *)urls withApp:(NSString *)bundleID {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];

	BOOL success = [ws openURLs:urls withAppBundleIdentifier:bundleID options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifiers:nil];
	if ((!success)) {
		NSLog(@"Error opening files %@ with %@", urls, bundleID);
		NSBeep();
	}
	return success;
}

- (QSObject *)openFile:(QSObject *)dObject {
	
	// First, deal with opening files with the QS preferred app (usually happens after → into an app to open 'Recent Files'
	NSArray *preferredAppObjects = [[dObject splitObjects] arrayByEnumeratingArrayUsingBlock:^id(QSObject *obj) {
		if ([obj objectForMeta:@"QSPreferredApplication"]) {
			return obj;
		}
		return nil;
	}];
	if ([preferredAppObjects count]) {
		NSMutableDictionary *appsWithFiles = [NSMutableDictionary dictionary];
		for (QSObject *obj in preferredAppObjects) {
			NSString *identifier = [obj objectForMeta:@"QSPreferredApplication"];
			if (![appsWithFiles objectForKey:identifier]) {
				[appsWithFiles setObject:[NSMutableArray array] forKey:identifier];
			}
			[(NSMutableArray *)[appsWithFiles objectForKey:identifier] addObject:[NSURL fileURLWithPath:[obj singleFilePath]]];
		}
		for (NSString *bundleID in appsWithFiles) {
			NSArray *URLs = [appsWithFiles objectForKey:bundleID];
#ifdef DEBUG
			if (VERBOSE) NSLog(@"Using %@ to open %@", bundleID, URLs);
#endif
			[self openURLs:URLs withApp:bundleID];
		}
	}
	
	// Second, deal with opening any other files with their default app
	NSArray *defaultAppURLs = [[dObject splitObjects] arrayByEnumeratingArrayUsingBlock:^id(QSObject *obj) {
		if (![preferredAppObjects containsObject:obj]) {
			return [NSURL fileURLWithPath:[obj singleFilePath]];
		}
		return nil;
	}];
	if ([defaultAppURLs count]) {
		[self openURLs:defaultAppURLs withApp:nil];
	}
	
	return nil;
}

- (QSObject *)alwaysOpenFile:(QSObject *)dObject with:(QSObject *)iObject {
	FSRef ref;
	[[dObject singleFilePath] getFSRef:&ref];
	CFStringRef type;
	LSCopyItemAttribute(&ref, kLSRolesNone, kLSItemContentType, (CFTypeRef *)&type);
	LSSetDefaultRoleHandlerForContentType(type, kLSRolesAll, (__bridge CFStringRef) [[NSBundle bundleWithPath:[iObject singleFilePath]] bundleIdentifier]);
	CFRelease(type);
	return nil;
}

// FileOpenWithAction
- (QSObject *)openFile:(QSObject *)dObject with:(QSObject *)iObject {
	NSArray *splitObjects = [iObject splitObjects];
	NSArray *urls = [[dObject validPaths] arrayByEnumeratingArrayUsingBlock:^id(NSString *obj) {
		return [NSURL fileURLWithPath:obj];
	}];
	for(QSObject *individual in splitObjects) {
		if ([individual isApplication]) {
			NSString *identifier = [[NSBundle bundleWithPath:[individual singleFilePath]] bundleIdentifier];
			[self openURLs:urls withApp:identifier];
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
    if ([mQSFSBrowser respondsToSelector:@selector(revealFiles:)]) {
        [mQSFSBrowser revealFiles:[dObject validPaths]];
    } else {
        for(NSString *thisFile in [dObject validPaths]) {
            [mQSFSBrowser revealFile:thisFile];
        }
    }
	return nil;
}

- (QSObject *)getInfo:(QSObject *)dObject {
	[[QSReg getMediator:kQSFSBrowserMediators] getInfoForFiles:[dObject validPaths]];
	return nil;
}

- (QSBasicObject *)deleteFile:(QSObject *)dObject {
	NSArray *selection = [[dObject arrayForType:QSFilePathType] valueForKey:@"lastPathComponent"];

	// ***warning   * activate before showing
	QSInterfaceController *QSIC = [(QSController *)[NSApp delegate] interfaceController];
	[QSIC showMainWindow:nil];
	[QSIC setHiding:YES];

	NSAlert *alert = [[NSAlert alloc] init];
	alert.alertStyle = NSAlertStyleCritical;
	alert.messageText = NSLocalizedString(@"Delete file", @"Delete file action alert - title");
	NSString *message = NSLocalizedString(@"Are you sure you want to PERMANENTLY delete the following files ?", @"Delete file action alert - message");
	message = [message stringByAppendingFormat:@"\n%@", [selection componentsJoinedByString:@", "]];
	alert.informativeText = message;
	[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete file action - default button")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Delete file action - cancel button")];

	QSAlertResponse response = [alert runModalSheetForWindow:[QSIC window]];
	[QSIC setHiding:NO];
	if (response == QSAlertResponseOK) {
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
			CFURLRef soundURL = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"dragToTrash" ofType:@"aif"]];
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
	NSString *lastDeletedFile = nil;
    BOOL trashed = NO;
    NSMutableSet *failed = [[NSMutableSet alloc] init];
	for(NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
        // if at least one file was trashed
        if ([[NSFileManager defaultManager] movePathToTrash:thisFile]) {
            trashed = YES;
            lastDeletedFile = thisFile;
        } else {
            [failed addObject:[thisFile lastPathComponent]];
        }
	}
	
    if (trashed) {
        // get settings for playing sound
        Boolean isSet;
        CFIndex val = CFPreferencesGetAppIntegerValue(CFSTR("com.apple.sound.uiaudio.enabled"),
                                                      CFSTR("com.apple.systemsound"),
                                                      &isSet);
        if (val == 1 || !isSet) {
            // play trash sound
            CFURLRef soundURL = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"dragToTrash" ofType:@"aif"]];
            SystemSoundID soundId;
            AudioServicesCreateSystemSoundID(soundURL, &soundId);
            AudioServicesPlaySystemSound(soundId);
        }
    }
    if ([failed count]) {
        //NSLog(@"unable to trash: %@", failed);
		NSString *localizedErrorFormat = NSLocalizedStringFromTableInBundle(@"Unable to Trash:\n%@", nil, [NSBundle bundleForClass:[self class]], nil);
        NSString *localizedTitle = NSLocalizedStringFromTableInBundle(@"Quicksilver Move to Trash", nil, [NSBundle bundleForClass:[self class]], nil);
		NSString *errorMessage = [NSString stringWithFormat:localizedErrorFormat, [[failed allObjects] componentsJoinedByString:@", "]];
		QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"QSTrashFileFailed", QSNotifierType, [QSResourceManager imageNamed:@"AlertCautionIcon"], QSNotifierIcon, localizedTitle, QSNotifierTitle, errorMessage, QSNotifierText, nil]);
    }

	// return folder that contained the last file that was deleted
    if (lastDeletedFile) {
        return [QSObject fileObjectWithPath:[lastDeletedFile stringByDeletingLastPathComponent]];;
    }
    return nil;
}

- (QSObject *)openItemAtLogin:(QSObject *)dObject {
	LaunchAtLoginController *launch = [[LaunchAtLoginController alloc] init];
	for (NSString * path in [dObject arrayForType:QSFilePathType]) {
		[launch setLaunchAtLogin:YES forURL:[NSURL fileURLWithPath:path]];
	}
	return nil;
}

- (QSObject *)doNotOpenItemAtLogin:(QSObject *)dObject {
	LaunchAtLoginController *launch = [[LaunchAtLoginController alloc] init];
	for (NSString *path in [dObject arrayForType:QSFilePathType]) {
		[launch setLaunchAtLogin:NO forURL:[NSURL fileURLWithPath:path]];
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
	if (![[newName pathExtension] length] && [[path pathExtension] length] && ![dObject isDirectory])
		newName = [newName stringByAppendingPathExtension:[path pathExtension]];
	if (!newName) {
		NSBeep();
		return nil;
	}
	newName = [newName stringByReplacingOccurrencesOfString:@"/" withString:@":"];

	NSError *err = nil;

	NSString *destinationFile = [container stringByAppendingPathComponent:newName];
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSString *tmpFile = nil;
	BOOL success = NO;
	// Check for case changing of files/folders
	if ([[destinationFile lowercaseString] isEqualToString:[path lowercaseString]] && ![destinationFile isEqualToString:path]) {
		// case is different
		tmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
		success = [fm moveItemAtPath:path toPath:tmpFile error:&err];
		if (!success) {
			NSLog(@"Case-changing rename: temporary move failed: %@", err);
			return nil;
		}
		success = [fm moveItemAtPath:tmpFile toPath:destinationFile error:&err];
		if (!success) {
			// Revert the mess we made
			[fm moveItemAtPath:tmpFile toPath:path error:NULL];

			NSLog(@"Case-changing rename: temporary move failed: %@", err);
			return dObject;
		}

		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:container];
		return [QSObject fileObjectWithPath:destinationFile];
	}

	// This is a "real" rename
	success = [fm moveItemAtPath:path toPath:destinationFile error:&err];
	if (success) {
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:container];
		QSObject *renamed = [QSObject fileObjectWithPath:destinationFile];
		return renamed;
	} else if (!success && err.code == 516) {
		// There's already a file with that name, ask the user
		__block QSFileConflictResolutionMethod copyMethod = QSDontReplaceFilesResolution;
		QSGCDMainSync(^{
            QSFileConflictPanel *panel = [QSFileConflictPanel conflictPanel];
            [panel setConflictNames:@[destinationFile]];
            [panel setAllowsRenames:YES];
			id QSIC = [(QSController *)[NSApp delegate] interfaceController];
			[QSIC showMainWindow:nil];
			[QSIC setHiding:YES];
			copyMethod = [panel runModalAsSheetOnWindow:[QSIC window]];
			[QSIC setHiding:NO];
		});

		switch (copyMethod) {
			case QSCancelReplaceResolution:
			case QSDontReplaceFilesResolution:
				return dObject;
			case QSSmartReplaceFilesResolution:
			case QSReplaceFilesResolution: {
				[fm movePathToTrash:destinationFile];
				success = [fm moveItemAtPath:path toPath:destinationFile error:&err];
				if (success) {
					[[NSWorkspace sharedWorkspace] noteFileSystemChanged:container];
					return [QSObject fileObjectWithPath:destinationFile];
				}
				break;
			}
		}
	}

	// If we get here, we failed to rename anything

	NSString *localizedErrorFormat = NSLocalizedStringFromTableInBundle(@"Error renaming File: %@ to %@", nil, [NSBundle bundleForClass:[self class]], nil);
	NSString *localizedTitle = NSLocalizedStringFromTableInBundle(@"Quicksilver File Rename", nil, [NSBundle bundleForClass:[self class]], nil);
	NSString *errorMessage = [NSString stringWithFormat:localizedErrorFormat, path, destinationFile];
	QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"QSRenameFileFailed", QSNotifierType, [QSResourceManager imageNamed:@"AlertStopIcon"], QSNotifierIcon, localizedTitle, QSNotifierTitle, errorMessage, QSNotifierText, nil]);
	NSLog(@"%@\nError:%@", errorMessage, err);

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

		NSString *localizedTitle = NSLocalizedStringFromTableInBundle(@"Quicksilver File Copy", nil, [NSBundle bundleForClass:[self class]], nil);
		NSString *localizedErrorMessage = NSLocalizedStringFromTableInBundle(@"Cannot copy files to the same destination as original!", nil, [NSBundle bundleForClass:[self class]], nil);

		QSShowNotifierWithAttributes(@{
									   QSNotifierType: @"QSCopyFileError",
									   QSNotifierIcon: [QSResourceManager imageNamed:@"AlertStopIcon"],
									   QSNotifierTitle: localizedTitle,
									   QSNotifierText: localizedErrorMessage
									   });
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
		__block QSFileConflictResolutionMethod copyMethod = QSDontReplaceFilesResolution;

		// Ask the user what to do about those conflicts
		QSGCDMainSync(^{
			NSLog(@"Conflicts: %@", conflicts);
			id panel = [QSFileConflictPanel conflictPanel];
			[panel setConflictNames:[conflicts allValues]];
			id QSIC = [(QSController *)[NSApp delegate] interfaceController];
			[QSIC showMainWindow:nil];
			[QSIC setHiding:YES];
			copyMethod = [panel runModalAsSheetOnWindow:[QSIC window]];
			[QSIC setHiding:NO];
		});

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
				otherFiles = [filePaths mutableCopy];
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
			if ([resultPaths count] < [filePaths count])
                NSLog(@"Finder-based move may not return all paths");
            return [QSObject fileObjectWithArray:resultPaths];
        } else {
            NSLog(@"Finder move failed");
        }
        
        if (!resultPaths) {
            //		if (DEBUG) NSLog(@"Using NSFileManager");
            NSError *err;
            NSMutableArray *newPaths = [NSMutableArray arrayWithCapacity:[filePaths count]];
            for(NSString *thisFile in filePaths) {
                NSString *destinationFile = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
                if (copy && [[NSFileManager defaultManager] copyItemAtPath:thisFile toPath:destinationFile error:&err]) {
                    [newPaths addObject:destinationFile];
                } else if (!copy && [[NSFileManager defaultManager] moveItemAtPath:thisFile toPath:destinationFile error:&err]) {
                    [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[thisFile stringByDeletingLastPathComponent]];
                    [newPaths addObject:destinationFile];
                } else {
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"The following error occured while trying to move \"%1$@\" to \"%2$@\"\n\n%3$@", nil), thisFile, destination, [err localizedDescription]];
                    [NSAlert runAlertWithTitle:NSLocalizedString(@"Move error", nil)
                                                               message:message
                                                               buttons:@[NSLocalizedString(@"OK", nil)]
                                                                 style:NSWarningAlertStyle];
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
        if ([destinationFile isEqualToString:thisFile]) {
            // change the name if the alias will be in the same directory
            NSString *aliasSuffix = NSLocalizedString(@"alias", @"alias");
            NSArray *pathAndSuffix = @[destinationFile, aliasSuffix];
            destinationFile = [pathAndSuffix componentsJoinedByString:@" "];
        }
		if ([(NDAlias *)[NDAlias aliasWithPath:thisFile] writeToFile:destinationFile])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:destination];
	}
	return nil;
}

- (QSObject *)makeLinkTo:(QSObject *)dObject inFolder:(QSObject *)iObject {
	NSString *destination = [iObject singleFilePath];
    NSString *linkPath;
	for(__strong NSString *thisFile in [dObject arrayForType:QSFilePathType]) {
        linkPath = [destination stringByAppendingPathComponent:[thisFile lastPathComponent]];
        if ([linkPath isEqualToString:thisFile]) {
            // change the name if the link will be in the same directory
            NSString *linkSuffix = NSLocalizedString(@"link", @"link");
            NSArray *pathAndSuffix = @[linkPath, linkSuffix];
            linkPath = [pathAndSuffix componentsJoinedByString:@" "];
            // don't use the absolute path, since we know the relative locations
            thisFile = [thisFile lastPathComponent];
        }
		if ([[NSFileManager defaultManager] createSymbolicLinkAtPath:linkPath withDestinationPath:thisFile error:nil])
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
	NSString *fileURLs = [[NSURL performSelector:@selector(fileURLWithPath:) onObjectsInArray:[dObject arrayForType:QSFilePathType] returnValues:YES] componentsJoinedByString:@"\n"];
    return [QSObject objectWithType:QSTextType value:fileURLs name:fileURLs];
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
# define kPasteboardPasteActionAsPlainText @"PasteboardPasteActionAsPlainText"

@implementation ClipboardActions

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
    return [NSArray arrayWithObjects:kPasteboardPasteAction,kPasteboardPasteActionAsPlainText,nil];
}
	 
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
