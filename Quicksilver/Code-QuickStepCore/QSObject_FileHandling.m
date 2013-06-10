#import "QSObject_FileHandling.h"
#import "QSObject_Pasteboard.h"
#import "QSParser.h"
#import "QSComputerSource.h"
#import "QSResourceManager.h"
#import "QSLibrarian.h"
#import "QSTypes.h"
#import "QSRegistry.h"
#import <QSFoundation/QSFoundation.h>
#import "QSPreferenceKeys.h"
#import "NDResourceFork.h"
#import "QSCatalogEntry.h"
#import "NDAlias+QSMods.h"
#import "QSUTI.h"
#import "QSExecutor.h"
#import "QSMacros.h"
#import "QSAction.h"
#import "QSObject_PropertyList.h"
#include "QSLocalization.h"
#import "QSDownloads.h"
#import <sys/mount.h>

#import "NSApplication_BLTRExtensions.h"

NSString *identifierForPaths(NSArray *paths) {
	if ([paths count] == 1) return [paths lastObject];
	return [paths componentsJoinedByString:@" "];
}

NSArray *recentDocumentsForBundle(NSString *bundleIdentifier) {
    if (bundleIdentifier == nil) {
		return nil;
	}

	// make sure latest changes are available
	CFPreferencesSynchronize((CFStringRef) [bundleIdentifier stringByAppendingString:@".LSSharedFileList"],
							 kCFPreferencesCurrentUser,
							 kCFPreferencesAnyHost);
	NSDictionary *recentDocuments106 = [(NSDictionary *)CFPreferencesCopyValue((CFStringRef) @"RecentDocuments",
																		  (CFStringRef) [bundleIdentifier stringByAppendingString:@".LSSharedFileList"],
																		  kCFPreferencesCurrentUser,
																		  kCFPreferencesAnyHost) autorelease];
	NSArray *recentDocuments = [recentDocuments106 objectForKey:@"CustomListItems"];

	NSMutableArray *documentsArray = [NSMutableArray arrayWithCapacity:0];
	NSData *bookmarkData;
	NSURL *url;
	NSError *err;
	for(NSDictionary *documentStorage in recentDocuments) {
		bookmarkData = [documentStorage objectForKey:@"Bookmark"];
		err = nil;
		url = [NSURL URLByResolvingBookmarkData:bookmarkData
										options:NSURLBookmarkResolutionWithoutMounting|NSURLBookmarkResolutionWithoutUI
								  relativeToURL:nil
							bookmarkDataIsStale:NO
										  error:&err];
		if (url == nil || err != nil) {
			// couldn't resolve bookmark, so skip
			continue;
		}
		[documentsArray addObject:[url path]];
	}
	return documentsArray;
}

@interface QSFileSystemObjectHandler (hidden)
-(NSImage *)prepareImageforIcon:(NSImage *)icon;

@end

#pragma mark QSFileSystemObjectHandler

@implementation QSFileSystemObjectHandler

- (QSObject *)parentOfObject:(QSObject *)object {
	QSObject * parent = nil;
	if ([object singleFilePath]) {
		if ([[object singleFilePath] isEqualToString:@"/"]) parent = [QSProxyObject proxyWithIdentifier:@"QSComputerProxy"];
		else parent = [QSObject fileObjectWithPath:[[object singleFilePath] stringByDeletingLastPathComponent]];
	}
	return parent;
}

- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type {
	return [object arrayForType:type];
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	if (NSWidth(rect) <= 32)
		return NO;
	NSString *path = [object singleFilePath];

	if ([object isApplication]) {
        NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];

        NSString *handlerName = [[QSReg tableNamed:@"QSBundleDrawingHandlers"] objectForKey:bundleIdentifier];
        if (handlerName) {
            id handler = [QSReg getClassInstance:handlerName];
            if (handler) {
                if ([handler respondsToSelector:@selector(drawIconForObject:inRect:flipped:)])
                    return [handler drawIconForObject:object inRect:rect flipped:flipped];
                return NO;
            }
        }
    }
    return NO;
}

- (NSString *)kindOfObject:(QSObject *)object {
    if ([object isApplication])
        return @"QSKindApplication";

    return nil;
}

- (NSString *)detailsOfObject:(QSObject *)object {
	NSArray *theFiles = [object arrayForType:QSFilePathType];
	if ([theFiles count] == 1) {
		NSString *path = [theFiles lastObject];
		if ([path hasPrefix:NSTemporaryDirectory()]) {
			return [@"(Quicksilver) " stringByAppendingPathComponent:[path lastPathComponent]];
		} else if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:[NSURL fileURLWithPath:path]]) {
			return @"iCloud";
		} else {
			return [path stringByAbbreviatingWithTildeInPath];
		}
	} else if ([theFiles count] > 1) {
		return [[theFiles arrayByPerformingSelector:@selector(lastPathComponent)] componentsJoinedByString:@", "];
	}
	return nil;
}

- (void)setQuickIconForObject:(QSObject *)object {
	NSImage *theImage = nil;
	NSArray *theFiles = [object arrayForType:QSFilePathType];
	if (!theFiles) return;
	if ([theFiles count] == 1) {
		// it's a single file
		// use basic file type icon temporarily
        NSString *type = [object isFolder] ? @"'fold'" : [object fileExtension];
        theImage = [[NSWorkspace sharedWorkspace] iconForFileType:type];
	} else {
		// it's a combined object, containing multiple files
		NSMutableSet *set = [NSMutableSet set];
		NSWorkspace *w = [NSWorkspace sharedWorkspace];
		NSFileManager *manager = [NSFileManager defaultManager];
		for(NSString *theFile in theFiles) {
			NSString *type = [manager typeOfFile:theFile];
			[set addObject:type?type:@"'msng'"];
		}
        
		if ([set containsObject:@"'fold'"]) {
			[set removeObject:@"'fold'"];
			[set addObject:@"'fldr'"];
		}
        
		if ([set count] == 1) {
			theImage = [w iconForFileType:[set anyObject]];
		} else {
			theImage = [w iconForFiles:theFiles];
		}
	}
    
	// set temporary image until preview icon is generated
	theImage = [self prepareImageforIcon:theImage];
	[object setIcon:theImage];
}

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *theImage = nil;
	NSString *path = [[object arrayForType:QSFilePathType] lastObject];
	NSFileManager *manager = [NSFileManager defaultManager];
    
	// the object isn't a file/doesn't exist, so return. shouldn't actually happen
	if (![manager fileExistsAtPath:path]) {
		return NO;
	}
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSLoadImagePreviews"]) {
        // try to create a preview icon
        NSString *uti = [object fileUTI];
        // try customized methods (from plug-ins) to generate a preview
        NSArray *specialTypes = [[QSReg tableNamed:@"QSFSFileTypePreviewers"] allKeys];
        for (NSString *type in specialTypes) {
            if (UTTypeConformsTo((CFStringRef)uti, (CFStringRef)type)) {
                id provider = [QSReg instanceForKey:type inTable:@"QSFSFileTypePreviewers"];
                if (provider) {
                    //NSLog(@"provider %@", [QSReg tableNamed:@"QSFSFileTypePreviewers"]);
                    theImage = [provider iconForFile:path ofType:type];
                    break;
                }
            }
        }
        if (!theImage) {
            NSArray *previewTypes = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSFilePreviewTypes"];
            for (NSString *type in previewTypes) {
                if (UTTypeConformsTo((CFStringRef)uti, (CFStringRef)type)) {
                    theImage = [NSImage imageWithPreviewOfFileAtPath:path ofSize:QSSizeMax asIcon:YES];
                    break;
                }
            }
        }
    }
    if (!theImage) {
        // previews are disabled or couldn't be loaded
        // use the file's actual icon
        theImage = [[NSWorkspace sharedWorkspace] iconForFiles:[object arrayForType:QSFilePathType]];
    }
    if (theImage) {
        // update the UI with the new icon
        theImage = [self prepareImageforIcon:theImage];
        [object setIcon:theImage];
        return YES;
    } else {
        [object setRetainsIcon:YES];
    }
    return NO;
}

- (NSImage *)prepareImageforIcon:(NSImage *)theImage {
	// last fallback, other methods didn't work
	if (!theImage) theImage = [QSResourceManager imageNamed:@"GenericQuestionMarkIcon"];
	return theImage;
}

- (BOOL)objectHasChildren:(QSObject *)object {
	BOOL isDirectory;
	NSString *path = [object singleFilePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {

        // A plain folder (not a package) has children
        if ([object isDirectory] && ![object isPackage]) {
            return YES;
        }
        
        // If it's an app check to see if there's a handler for it (e.g. a plugin) or if there are recent documents
		if ([object isApplication]) {
			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];

            // Does the app have an external handler? (e.g. a plugin)
			NSString *handlerName = [[QSReg tableNamed:@"QSBundleChildHandlers"] objectForKey:bundleIdentifier];
			if (handlerName) {
                return YES;
            }
            // Does the app have valid recent documents
            if (bundleIdentifier) {
                NSDictionary *recentDocuments = (NSDictionary *)CFPreferencesCopyValue((CFStringRef) @"RecentDocuments",
                                                                                       (CFStringRef) [bundleIdentifier stringByAppendingString:@".LSSharedFileList"],
                                                                                       kCFPreferencesCurrentUser,
                                                                                       kCFPreferencesAnyHost);
                if (recentDocuments) {
                    NSArray *recentDocumentsArray = [recentDocuments objectForKey:@"CustomListItems"];
                    [recentDocuments release];
                    if (recentDocumentsArray && [recentDocumentsArray count]) {
                        return YES;
                    }
                }
            }
		}

        // If there is a valid file parser (text or HTML parser) the object has children
        NSString *uti = [object fileUTI];
        id <QSParser> parser = [QSReg instanceForKey:uti inTable:@"QSFSFileTypeParsers"];
        if (parser) {
            return YES;
        }

        // An alias has children (the resolved file)
		if ([object isAlias]) {
            return YES;
        }
	}
	return NO;
}

- (BOOL)objectHasValidChildren:(QSObject *)object {
	if ([object fileCount] == 1) {
		NSString *path = [object singleFilePath];

		if ([object isApplication]) {
			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
			NSString *handlerName = [[QSReg tableNamed:@"QSBundleChildHandlers"] objectForKey:bundleIdentifier];
			if (handlerName) {
				id handler = [QSReg getClassInstance:handlerName];
				if (handler) {
					if ([handler respondsToSelector:@selector(objectHasValidChildren:)])
						return [handler objectHasValidChildren:object];
					return NO;
				}
			}
			return YES;
		}

		NSTimeInterval modDate = [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL] fileModificationDate] timeIntervalSinceReferenceDate];
		if (modDate > [object childrenLoadedDate]) return NO;
	}
	return YES;

}

- (NSDragOperation)operationForDrag:(id <NSDraggingInfo>)sender ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject {
	if (![iObject arrayForType:QSFilePathType])
		return 0;
	if ([dObject fileCount] > 1)
		return NSDragOperationGeneric;
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	if ([dObject isApplication])
		return NSDragOperationPrivate;
	else if ([dObject isDirectory]) {
		NSDragOperation defaultOp = [[NSFileManager defaultManager] defaultDragOperationForMovingPaths:[iObject validPaths] toDestination:[dObject singleFilePath]];
		if (defaultOp == NSDragOperationMove) {
			if (sourceDragMask & NSDragOperationMove)
				return NSDragOperationMove;
			else if (sourceDragMask & NSDragOperationCopy)
				return NSDragOperationCopy;
		} else if (defaultOp == NSDragOperationCopy)
			return NSDragOperationCopy;
	}
	return sourceDragMask & NSDragOperationGeneric;
}
- (NSString *)actionForDragMask:(NSDragOperation)operation ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject {
	if ([dObject fileCount] > 1)
		return 0;
	if ([dObject isApplication]) {
		return @"FileOpenWithAction";
	} else if ([dObject isDirectory]) {
		if (operation & NSDragOperationMove)
			return @"FileMoveToAction";
		else if (operation & NSDragOperationCopy)
			return @"FileCopyToAction";
	}
	return 0;
}

- (NSAppleEventDescriptor *)AEDescriptorForObject:(QSObject *)object {
	return [NSAppleEventDescriptor aliasListDescriptorWithArray:[object validPaths]];
}

- (NSString *)identifierForObject:(QSObject *)object {
    if ([object count] > 1)
        return nil;
	return identifierForPaths([object arrayForType:QSFilePathType]);
}
- (BOOL)loadChildrenForObject:(QSObject *)object {
	NSArray *newChildren = nil;
	NSArray *newAltChildren = nil;

	if ([object fileCount] == 1) {
		NSString *path = [object singleFilePath];
		if (!path || ![path length]) return NO;
		NSFileManager *manager = [NSFileManager defaultManager];
        // Boolean as to whether or not the alias is a directory
        BOOL isDirectory = NO;
        if ([object isAlias]) {
            /* Resolve the alias before loading its children */
			path = [manager resolveAliasAtPath:path];
			if (![manager fileExistsAtPath:path isDirectory:&isDirectory]) {
                /* Alias can't be resolved : no children */
                return NO;
            } else if (!isDirectory) {
                /* Alias is a file, set it as object's child */
				[object setChildren:[NSArray arrayWithObject:[QSObject fileObjectWithPath:path]]];
				return YES;
			}
		}

        if ([object isDirectory] || isDirectory) {

            
            NSError *err = nil;
            // pre-fetch the required info (hidden key) for the dir contents to speed up the task
            NSArray *dirContents = [manager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path] includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsHiddenKey] options:0 error:&err];
            if (!dirContents) {
                NSLog(@"Error loading files: %@", err);
                return NO;
            }
            
            NSMutableArray *fileChildren = [NSMutableArray arrayWithCapacity:1];
            NSMutableArray *visibleFileChildren = [NSMutableArray arrayWithCapacity:1];
            for (NSURL *individualURL in dirContents) {
                NSString *p = [individualURL path];
                [fileChildren addObject:p];
                NSNumber *isHidden = 0;
                [individualURL getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:nil];
                if (![isHidden boolValue]) {
                    [visibleFileChildren addObject:p];
                }
            }
            // sort the files like Finder does. Note: Casting array to NSMutable array so don't try and alter these arrays later on
            fileChildren = (NSMutableArray *)[fileChildren sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            visibleFileChildren = (NSMutableArray *)[visibleFileChildren sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            
            newChildren = [QSObject fileObjectsWithPathArray:visibleFileChildren];
            newAltChildren = [QSObject fileObjectsWithPathArray:fileChildren];

            if (newAltChildren) [object setAltChildren:newAltChildren];
        }

		if ([object isApplication]) {
			// ***warning * omit other types of bundles
			//newChildren = nil;

			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
			NSString *handlerName = [[QSReg tableNamed:@"QSBundleChildHandlers"] objectForKey:bundleIdentifier];
			id handler = nil;

			if (handlerName) handler = [QSReg getClassInstance:handlerName];

			if (handler) {
				return [handler loadChildrenForObject:object];
			} else {
				NSString *childPreset = [[QSReg tableNamed:@"QSBundleChildPresets"] objectForKey:bundleIdentifier];
				if (childPreset) {
#ifdef DEBUG
					if (VERBOSE) NSLog(@"using preset %@", childPreset);
#endif
					QSCatalogEntry *theEntry = [[QSLibrarian sharedInstance] entryForID:childPreset];
					newChildren = [theEntry contentsScanIfNeeded:YES];
				} else {
					NSArray *recentDocuments = recentDocumentsForBundle(bundleIdentifier);
					NSArray *iCloudDocuments = [QSDownloads iCloudDocumentsForBundleID:bundleIdentifier];
					// combine recent and iCloud documents, removing duplicates
                    NSIndexSet *ind = [iCloudDocuments indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSObject *icdoc, NSUInteger i, BOOL *stop) {
                        return ![recentDocuments containsObject:[icdoc objectForType:QSFilePathType]];
                    }];
                    newChildren = [[QSObject fileObjectsWithPathArray:recentDocuments] arrayByAddingObjectsFromArray:[iCloudDocuments objectsAtIndexes:ind]];

					for(QSObject * child in newChildren) {
						[child setObject:bundleIdentifier forMeta:@"QSPreferredApplication"];
					}
				}
			}

		} else if ([object isPackage] || ![object isDirectory]) {
			//NSString *type = [[NSFileManager defaultManager] typeOfFile:path];

			NSString *uti = [object fileUTI];

			id <QSParser> parser = [QSReg instanceForKey:uti inTable:@"QSFSFileTypeParsers"];
			NSArray *children = [parser objectsFromPath:path withSettings:nil];
			if (children) {
				[object setChildren:children];
				return YES;
			}

		}

	} else {
		newChildren = [QSObject fileObjectsWithPathArray:[object arrayForType:QSFilePathType]];
	}

	if (newChildren) [object setChildren:newChildren];

	return YES;
}

- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
    if ([dObject isApplication]) {
        NSMutableArray *actions = (NSMutableArray *)[QSExec validActionsForDirectObject:dObject indirectObject:iObject];
        NSString *path = [dObject singleFilePath];
        NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];

        //NSLog(@"actions %d", [actions count]);
        NSDictionary *appActions = [[QSReg tableNamed:@"QSApplicationActions"] objectForKey:bundleIdentifier];
        if([appActions count]) {
            for(NSString *actionID in appActions) {
				NSDictionary *actionDict = [appActions objectForKey:actionID];
                actionDict = [[actionDict copy] autorelease];
                [actions addObject:[QSAction actionWithDictionary:actionDict identifier:actionID]];
            }
        }
        //    NSLog(@"actions %d", [actions count]);
        return actions;
    }
    return nil;
}

@end

@implementation QSBasicObject (FileHandling)

- (NSString *)singleFilePath {return [self objectForType:QSFilePathType];}

- (NSString *)validSingleFilePath {
	NSString *path = [self objectForType:QSFilePathType];
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
		return path;
	return nil;
}

- (NSArray *)validPaths {return [self validPathsResolvingAliases:NO];}
- (NSArray *)validPathsResolvingAliases:(BOOL)resolve {
	NSArray *paths = [self arrayForType:QSFilePathType];
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL exists = [manager filesExistAtPaths:(NSArray *)paths];
	if (exists) return paths;

	if ([paths count] == 1) {
		NSString *aliasFile = [self objectForType:QSAliasFilePathType];
		if ([manager fileExistsAtPath:aliasFile]) {
#ifdef DEBUG
			if (VERBOSE) NSLog(@"Using original alias file:%@", aliasFile);
#endif
			return [NSArray arrayWithObject:aliasFile];
		}
	}
	return nil;
}

- (NSInteger) fileCount {
	return [[self arrayForType:QSFilePathType] count];
}

@end

@implementation QSObject (FileHandling)

+ (QSObject *)fileObjectWithPath:(NSString *)path {
	if (![path length])
		return nil;
	path = [path stringByStandardizingPath];
	if ([[path pathExtension] isEqualToString:@"silver"])
		return [QSObject objectWithDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];

    // initWithArray: deals with file objects that already exist
    QSObject *newObject = [[[QSObject alloc] initWithArray:[NSArray arrayWithObject:path]] autorelease];
    
	if ([clippingTypes containsObject:[[NSFileManager defaultManager] typeOfFile:path]])
		[newObject performSelectorOnMainThread:@selector(addContentsOfClipping:) withObject:path waitUntilDone:YES];
	return newObject;
}

+ (QSObject *)fileObjectWithFileURL:(NSURL *)fileURL {
    return [self fileObjectWithPath:[fileURL path]];
}

+ (QSObject *)fileObjectWithArray:(NSArray *)paths {
	QSObject *newObject = [QSObject objectByMergingObjects:[self fileObjectsWithPathArray:paths]];
	if (!newObject) {
		if ([paths count] > 1)
			newObject = [[[QSObject alloc] initWithArray:paths] autorelease];
		else if ([paths count] == 0)
			return nil;
		else
			newObject = [QSObject fileObjectWithPath:[paths lastObject]];
	}
	return newObject;
}

+ (NSArray *)fileObjectsWithPathArray:(NSArray *)pathArray {
	NSMutableArray *fileObjectArray = [NSMutableArray array];
	QSObject *object = nil;
    for (NSString* loopItem in pathArray) {
        if (object = [QSObject fileObjectWithPath:loopItem]) {
			[fileObjectArray addObject:object];
        }
    };
	return fileObjectArray;
}

+ (NSMutableArray *)fileObjectsWithURLArray:(NSArray *)URLArray {
	NSMutableArray *fileObjectArray = [NSMutableArray array];
    QSObject *object = nil;
    for (NSURL* loopItem in URLArray) {
        if (object = [QSObject fileObjectWithFileURL:loopItem]) {
            [fileObjectArray addObject:object];
        }
	}
	return fileObjectArray;
}

- (id)initWithArray:(NSArray *)paths { 
	NSString *thisIdentifier = identifierForPaths(paths);

	// return an already-created object if it exists
	QSObject *existingObject = [QSObject objectWithIdentifier:thisIdentifier];
	if (existingObject) {
		[existingObject retain];
		return existingObject;
	}

	// if no previous object has been created, then create a new one
	if (self = [self init]) {
		if ([paths count] == 1) {
			NSString *path = [paths lastObject];
			[[self dataDictionary] setObject:path forKey:QSFilePathType];
			NSString *uti = [self fileUTI];
			id handler = [QSReg instanceForKey:uti inTable:@"QSFileObjectCreationHandlers"];
			if (handler) {
				if ([handler respondsToSelector:@selector(createFileObject:ofType:)])
					[handler createFileObject:self ofType:uti];
				else if ([handler respondsToSelector:@selector(initFileObject:ofType:)])
					/* Try with the old selector */
					[handler performSelector:@selector(initFileObject:ofType:) withObject:self withObject:uti];
				return self;
			}
		} else {
			[[self dataDictionary] setObject:paths forKey:QSFilePathType];
		}
		[QSObject registerObject:self withIdentifier:thisIdentifier];
		[self setPrimaryType:QSFilePathType];
		[self getNameFromFiles];
	}
	return self;
}

- (NSDictionary *)infoRecord {
    NSDictionary *dict;
    if (dict = [self objectForCache:@"QSItemInfoRecord"])
        return dict;
    
    NSString *path = [self validSingleFilePath];
    if (!path)
        return nil;

	/* Try to get information for this file */
    LSItemInfoRecord record;
    OSStatus status = LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path], kLSRequestAllInfo, &record);
    if (status) {
        NSLog(@"LSCopyItemInfoForURL error: %ld", (long)status);
        return nil;
    }

	NSString *uti = QSUTIWithLSInfoRec(path, &record);
    NSString *extension = [(NSString *)record.extension copy];
    
    /* local or network volume? does it support Trash? */
    struct statfs sfsb;
    statfs([path UTF8String], &sfsb);
    NSString *device = [NSString stringWithCString:sfsb.f_mntfromname encoding:NSUTF8StringEncoding];
    BOOL isLocal = [device hasPrefix:@"/dev/"];
    
	/* Now build a dictionary with that record */
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLong:record.flags], @"flags",
			[NSValue valueWithOSType:record.filetype],     @"filetype",
			[NSValue valueWithOSType:record.creator],      @"creator",
            [NSNumber numberWithBool:isLocal],             @"localVolume",
			nil];
    if (uti) {
        [tempDict setObject:uti forKey:@"uti"];
    }
    if (extension) {
        [tempDict setObject:extension forKey:@"extension"];
    }
    [extension release];
    dict = [NSDictionary dictionaryWithDictionary:tempDict];
	/* Release the file's extension if one was returned */
	if (record.extension)
		CFRelease(record.extension);

    [self setObject:dict forCache:@"QSItemInfoRecord"];
    return dict;
}

- (BOOL)checkInfoRecordFlags:(LSItemInfoFlags)infoFlags {
	NSDictionary *infoRec = [self infoRecord];
	NSNumber *fileFlags = [infoRec objectForKey:@"flags"];
	if (!fileFlags)
		return NO;
	unsigned int numFlags = [fileFlags unsignedIntValue];
	return numFlags & infoFlags;
}

- (BOOL)isApplication {
	return [self checkInfoRecordFlags:kLSItemInfoIsApplication];
}

- (BOOL)isDirectory {
	return [self checkInfoRecordFlags:kLSItemInfoIsContainer];
}

- (BOOL)isFolder {
    return ([self isDirectory] && ![self isPackage]);
}

- (BOOL)isPackage {
	return [self checkInfoRecordFlags:kLSItemInfoIsPackage];
}

- (BOOL)isAlias {
	return [self checkInfoRecordFlags:kLSItemInfoIsAliasFile];
}

- (BOOL)isOnLocalVolume {
	NSDictionary *infoRec = [self infoRecord];
    return [[infoRec objectForKey:@"localVolume"] boolValue];
}

- (NSString *)fileExtension {
	NSDictionary *infoRec = [self infoRecord];
    return [infoRec objectForKey:@"extension"];
}

- (NSString *)fileUTI {
    NSDictionary *infoRec = [self infoRecord];
    return [infoRec objectForKey:@"uti"];
}

- (NSString *)bundleNameFromInfoDict:(NSDictionary *)infoDict {
    // Use the display name
    return [infoDict objectForKey:@"CFBundleDisplayName"];
}

- (NSString *)descriptiveNameForPackage:(NSString *)path withKindSuffix:(BOOL)includeKind {
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    NSString *bundleName = nil;
    // First try the localised info Dict
    NSDictionary *infoDict = [[NSBundle bundleWithURL:fileURL] localizedInfoDictionary];
    if (infoDict) {
        bundleName = [self bundleNameFromInfoDict:infoDict];
    }
    // Get the general info Dict
    if (!bundleName) {
        infoDict = [[NSBundle bundleWithURL:fileURL] infoDictionary];
        bundleName = [self bundleNameFromInfoDict:infoDict];
    }
    
    if (!bundleName) {
        return nil;
    }
    
	if (includeKind) {
		NSString *kind = nil;
		LSCopyKindStringForURL((CFURLRef)fileURL, (CFStringRef *)&kind);
		[kind autorelease];
	
#ifdef DEBUG
      if (DEBUG_LOCALIZATION) NSLog(@"kind: %@", kind);
#endif
		
        if ([kind length]) {
			bundleName = [NSString stringWithFormat:@"%@ %@", bundleName, kind];
        }
    }
        
    bundleName = [[bundleName retain] autorelease];
    
	return bundleName;
}

- (void)getNameFromFiles {
	NSString *newName = nil;
	NSString *newLabel = nil;
	if ([self count] >1) {
		NSArray *paths = [self arrayForType:QSFilePathType];
		NSString *container = [self filesContainer];
		NSString *type = [self filesType];
		BOOL onDesktop = [container isEqualToString:[@"~/Desktop/" stringByStandardizingPath]];
		newName = [NSString stringWithFormat:@"%ld %@ %@ \"%@\"", (long)[paths count] , type, onDesktop?@"on":@"in", [container lastPathComponent]];
	} else {
		// generally: name = what you see in Terminal, label = what you see in Finder
		NSString *path = [self objectForType:QSFilePathType];
        newName = [path lastPathComponent];
		// look for a more suitable display name
		if ([[self fileExtension] isEqualToString:@"qsplugin"]) {
			newLabel = [self descriptiveNameForPackage:path withKindSuffix:![self isApplication]];
		} else if (UTTypeConformsTo((CFStringRef)[self fileUTI], (CFStringRef)@"com.apple.systempreference.prefpane")) {
            // kMDItemDisplayName works better for Preference Panes
            MDItemRef mdItem = MDItemCreate(kCFAllocatorDefault, (CFStringRef)path);
            if (mdItem) {
                newLabel = [(NSString *)MDItemCopyAttribute(mdItem, kMDItemDisplayName) autorelease];
            }
        }
        // fall back to the default display name
        if (!newLabel) {
            newLabel = [[NSFileManager defaultManager] displayNameAtPath:path];
        }
	}
    [self setName:newName];
	[self setLabel:newLabel];
}

- (NSString *)filesContainer {
	NSArray *paths = [self arrayForType:QSFilePathType];

	NSString *commonPath = [[[paths objectAtIndex:0] stringByStandardizingPath] stringByDeletingLastPathComponent];
	for (id loopItem in paths) {
		NSString *thisPath = [loopItem stringByStandardizingPath];
		while (commonPath && ![thisPath hasPrefix:commonPath])
			commonPath = [commonPath stringByDeletingLastPathComponent];
	}
	return commonPath;
}

- (NSString *)singleFileType {
	return [[NSFileManager defaultManager] typeOfFile:[self singleFilePath]];
}

- (NSString *)filesType {
	BOOL appsOnly = YES;
	BOOL foldersOnly = YES;
	BOOL filesOnly = YES;
	NSString *kind = nil;
	NSArray *paths = [self arrayForType:QSFilePathType];

	for (id loopItem in paths) {
		NSString *thisPath = [loopItem stringByStandardizingPath];
		NSString *type = [[NSFileManager defaultManager] typeOfFile:thisPath];
		if ([type isEqualToString:@"'fold'"]) {
			filesOnly = NO;
			appsOnly = NO;
            // application type (or Finder 'FNDR')
		} else if ([type isEqualToString:@"app"] || [type isEqualToString:@"'APPL'"] || [type isEqualToString:@"'FNDR'"]) {
			foldersOnly = NO;
			filesOnly = NO;
		} else {
			appsOnly = NO;
			foldersOnly = NO;
//			if (!kind) {
			kind = [self kindOfFile:thisPath];
//			} else if (![kind isEqualToString:[self kindOfFile:thisPath]]) {
//				kind = @"";
//			}
		}
	}
	if (appsOnly) return @"Applications";
	if (foldersOnly) return @"Folders";
	if (filesOnly) {
		if ([kind length]) return [NSString stringWithFormat:@"[%@] ", kind];
		return @"Files";
	}
	return @"Items";
}

- (NSString *)kindOfFile:(NSString *)path {
	NSString *kind;
	return (!path || LSCopyKindStringForURL((CFURLRef) [NSURL fileURLWithPath:path], (CFStringRef *)&kind)) ? nil : [kind autorelease];
}

@end

