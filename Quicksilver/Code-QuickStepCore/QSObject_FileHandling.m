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
#import "QSScreenshots.h"
#import "QSPaths.h"
#import <sys/mount.h>

#import "NSApplication_BLTRExtensions.h"

NSString *identifierForPaths(NSArray *paths) {
	if ([paths count] == 1) return [paths lastObject];
	return [paths componentsJoinedByString:@" "];
}
NSString *QSGetRecentDocumentsPathForBundle(NSString *bundleIdentifier) {
	if ([NSApplication isSonoma]) {
		return [NSString stringWithFormat:pSharedFileListPathTemplate, bundleIdentifier, @"sfl3"];
	}
	// macOS <15
	return [NSString stringWithFormat:pSharedFileListPathTemplate, bundleIdentifier, @"sfl2"];
}

NSArray *QSGetRecentDocumentsForBundle(NSString *bundleIdentifier) {
    if (bundleIdentifier == nil) {
		return nil;
	}

    NSMutableArray *documentsArray = [NSMutableArray arrayWithCapacity:0];
	NSURL *url;
	
	NSString *sflPath = QSGetRecentDocumentsPathForBundle(bundleIdentifier);
	NSString *sflStandardized = [sflPath stringByStandardizingPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:sflStandardized isDirectory:nil]) {
		NSDictionary *sflData = [NSKeyedUnarchiver unarchiveObjectWithFile:sflStandardized];
		for (NSDictionary *item in sflData[@"items"]) {
			NSData *bookmarkData = item[@"Bookmark"];
			url = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithoutMounting relativeToURL:nil bookmarkDataIsStale:NO error:nil];
			if (url && [url isFileURL]) {
				[documentsArray addObject:[url path]];
			}
		}
	}
	return documentsArray;
}

@interface QSFileSystemObjectHandler (hidden)
-(NSImage *)prepareImageforIcon:(NSImage *)icon;

@end

#pragma mark QSFileSystemObjectHandler

@implementation QSFileSystemObjectHandler

- (QSObject *)parentOfObject:(QSObject *)object {
    QSObject *parent = nil;
    NSArray *paths = [object arrayForType:QSFilePathType];
    if ([paths count]) {
        // use the 1st file's parent as the 'default' parent
        NSString *path = [paths objectAtIndex:0];
        if ([path isEqualToString:@"/"]) {
            parent = [QSProxyObject proxyWithIdentifier:@"QSComputerProxy"];
        }
        else {
            NSURL *parentURL = nil;
            NSError *err = nil;
            [[NSURL fileURLWithPath:path] getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:&err];
            NSString *parentString;
            if (err) {
                NSLog(@"Error getting parent of file object %@\n%@",object,err);
                parentString = [path stringByDeletingLastPathComponent];
            } else {
                parentString = [parentURL path];
            }
            parent = [QSObject fileObjectWithPath:parentString];
        }
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
		if ([object isAlias] && ![object isUbiquitousItem]) { // isAlias returns YES for symlink or alias
			// Symlink file
			if (QSTypeConformsTo([object fileUTI], (NSString *)kUTTypeSymLink)) {
				return [[path stringByResolvingSymlinksInPath] stringByAbbreviatingWithTildeInPath];
			}
			// Finder alias file
			NSURL *fileURL = [NSURL fileURLWithPath:path];
			NSURL *resolvedURL = [NSURL URLByResolvingBookmarkAtURL:fileURL
															options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting bookmarkDataIsStale:NULL
															  error:NULL];
			return [resolvedURL path];
		}
		// Temporary QS file
		__block BOOL hasTemporaryPrefix = NO;
		QSGCDMainSync(^{
			hasTemporaryPrefix = [path hasPrefix:@"/private/var/folders/"];
		});
		
		if (hasTemporaryPrefix) {
			return [@"(Quicksilver) " stringByAppendingPathComponent:[path lastPathComponent]];
		}
		// check if it's a Dropbox file
		if ([[object singleFilePath] containsString:@"CloudStorage/Dropbox/"]) {
				return @"Dropbox";
		}
		if ([[object singleFilePath] containsString:@"CloudStorage/GoogleDrive-"]) {
				return @"Google Drive";
		}
		// iCloud File
		if ([[object singleFilePath] containsString:@"com~apple~CloudDocs"]) {
				return @"iCloud";
		}
		
		if ([object isUbiquitousItem]) {
				return [NSString stringWithFormat:@"%@ (%@)", [path stringByAbbreviatingWithTildeInPath], NSLocalizedString(@"Cloud File", @"Label for files which are stored remotely")];
		}

		// normal file
		return [path stringByAbbreviatingWithTildeInPath];
		
	} else if ([theFiles count] > 1) {
		return [[theFiles arrayByPerformingSelector:@selector(lastPathComponent)] componentsJoinedByString:@", "];
	}
	
	return nil;
}

- (void)setQuickIconForCombinedObject:(QSObject *)combinedObject {

	// it's a combined object, containing multiple files
	NSMutableSet *set = [NSMutableSet set];
	NSWorkspace *w = [NSWorkspace sharedWorkspace];
	NSImage *theImage = nil;
	for(QSObject *obj in [combinedObject splitObjects]) {
		NSString *uti = [obj fileUTI];
		[set addObject:uti?uti:@"public.item"];
	}

	
	if ([set count] == 1) {
		theImage = [w iconForFileType:[set anyObject]];
	} else {
		theImage = [w iconForFiles:[combinedObject arrayForType:QSFilePathType]];
	}
	theImage = [self prepareImageforIcon:theImage];
	[combinedObject setIcon:theImage];
}

- (void)setQuickIconForObject:(QSObject *)object {
	NSString *path = [object singleFilePath];
	if (!path) return;
	// it's a single file
	// use basic file type icon temporarily
	NSImage *theImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
	// set temporary image until preview icon is generated
	theImage = [self prepareImageforIcon:theImage];
	[object setIcon:theImage];
}

- (BOOL)loadIconForObject:(QSObject *)object {
    NSImage *theImage = nil;
    NSImage *previewImage = nil;
    NSString *path = [[object arrayForType:QSFilePathType] lastObject];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // the object isn't a file/doesn't exist, so return. shouldn't actually happen
    __block BOOL exists = YES;
    QSGCDMainSync(^{
        if (![manager fileExistsAtPath:path]) {
            exists = NO;
        }
    });
    if (!exists) {
        return NO;
    }
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSLoadImagePreviews"]) {
        // try to create a preview icon
        NSString *uti = [object fileUTI];
        // try customized methods (from plug-ins) to generate a preview
        NSArray *specialTypes = [[QSReg tableNamed:@"QSFSFileTypePreviewers"] allKeys];
        for (NSString *type in specialTypes) {
            if (UTTypeConformsTo((__bridge CFStringRef)uti, (__bridge CFStringRef)type)) {
                id provider = [QSReg instanceForKey:type inTable:@"QSFSFileTypePreviewers"];
                if (provider) {
                    //NSLog(@"provider %@", [QSReg tableNamed:@"QSFSFileTypePreviewers"]);
                    previewImage = [provider iconForFile:path ofType:type];
                    break;
                }
            }
        }
        if (!previewImage) {
            NSArray *previewTypes = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSFilePreviewTypes"];
            for (NSString *type in previewTypes) {
                if (UTTypeConformsTo((__bridge CFStringRef)uti, (__bridge CFStringRef)type)) {
                    previewImage = [NSImage imageWithPreviewOfFileAtPath:path ofSize:QSSizeMax asIcon:YES];
                    break;
                }
            }
        }
        if (previewImage) {
            if (UTTypeConformsTo((__bridge CFStringRef)uti, kUTTypeResolvable)) {
                [previewImage lockFocus];
                NSImage *aliasImage = [QSResourceManager imageNamed:@"AliasBadgeIcon"];
                aliasImage = [aliasImage duplicateOfSize:QSSizeMax];
                [aliasImage drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
                [previewImage unlockFocus];
            }
            theImage = previewImage;
        }
    }
    if (theImage) {
        // update the UI with the new icon
        theImage = [self prepareImageforIcon:theImage];
        [object setIcon:theImage];
        return YES;
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
            // does the app have a QSBundleChildPresets? - define an existing preset to be the children of a given app
            handlerName = [[QSReg tableNamed:@"QSBundleChildPresets"] objectForKey:bundleIdentifier];
            if (handlerName) {
                return YES;
            }
            // Does the app have valid recent documents
            if (bundleIdentifier) {
				NSString *sflPath = QSGetRecentDocumentsPathForBundle(bundleIdentifier);
				if ([[NSFileManager defaultManager] fileExistsAtPath:[sflPath stringByStandardizingPath] isDirectory:nil]) {
					return YES;
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
      } else {
          // Check for recent documents
          NSString *sflPath = QSGetRecentDocumentsPathForBundle(bundleIdentifier);
          if ([[NSFileManager defaultManager] fileExistsAtPath:[sflPath stringByStandardizingPath] isDirectory:nil]) {
              // reload recent documents every time
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
	if (iObject && ![iObject arrayForType:QSFilePathType])
		return NSDragOperationNone;
	if ([dObject fileCount] > 1)
		return NSDragOperationNone;
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
			if ([visibleFileChildren isEqual:fileChildren]) {
				newAltChildren = newChildren;
			} else {
				newAltChildren = [QSObject fileObjectsWithPathArray:fileChildren];
			}


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
					NSArray *recentDocuments = QSGetRecentDocumentsForBundle(bundleIdentifier);
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
        NSDictionary *appActions = [[QSReg tableNamed:QSApplicationActions] objectForKey:bundleIdentifier];
        if([appActions count]) {
            for(NSString *actionID in appActions) {
				NSDictionary *actionDict = [appActions objectForKey:actionID];
                actionDict = [actionDict copy];
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

- (NSString *)singleFilePath {
	NSString *path = [self objectForType:QSFilePathType];
	if (path && ![path isKindOfClass:[NSString class]]) {
		NSLog(@"unexpected object for file path: %@, object: %@", path, self);
		return nil;
	}
	return path;
}

- (NSString *)validSingleFilePath {
	NSString *path = [self singleFilePath];
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
	QSObject *newObject = [[QSObject alloc] initWithArray:[NSArray arrayWithObject:path]];

	if ([newObject isClipping]) {
		QSGCDMainAsync(^{
			[newObject addContentsOfClipping:path];
		});
	}
	return newObject;
}

+ (QSObject *)fileObjectWithFileURL:(NSURL *)fileURL {
    return [self fileObjectWithPath:[fileURL path]];
}

+ (QSObject *)fileObjectWithArray:(NSArray *)paths {
	QSObject *newObject = [QSObject objectByMergingObjects:[self fileObjectsWithPathArray:paths]];
	if (!newObject) {
		if ([paths count] > 1)
			newObject = [[QSObject alloc] initWithArray:paths];
		else if ([paths count] == 0)
			return nil;
		else
			newObject = [QSObject fileObjectWithPath:[paths lastObject]];
	}
	return newObject;
}

+ (NSArray *)fileObjectsWithPathArray:(NSArray *)pathArray {
	NSMutableArray *fileObjectArray = [pathArray mutableCopy];

	NSMutableIndexSet __block *objsToRemove = nil;

	[pathArray enumerateObjectsUsingBlock:^(NSString * loopItem, NSUInteger idx, BOOL * _Nonnull stop) {
		QSObject *object = [QSObject fileObjectWithPath:loopItem];
		if (object) {
			[fileObjectArray replaceObjectAtIndex:idx withObject:object];
		} else {
			if (objsToRemove == nil) {
				objsToRemove = [NSMutableIndexSet indexSet];
			}
			[objsToRemove addIndex:idx];
		}
	}];
	if ([objsToRemove count]) {
		[fileObjectArray removeObjectsAtIndexes:objsToRemove];
	}
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
	QSObject *existingObject = [QSLib objectWithIdentifier:thisIdentifier];
	if (existingObject) {
		return existingObject;
	}

	// if no previous object has been created, then create a new one
	if (self = [self init]) {
		if ([paths count] == 1) {
			NSString *path = [paths lastObject];
			[[self dataDictionary] setObject:path forKey:QSFilePathType];
			[[self dataDictionary] setObject:path forKey:QSTextType];
			if ([[QSReg tableNamed:@"QSFileObjectCreationHandlers"] count]) {
				// only get the file UTI if there's actually any QSFileObjectCreationHandlers to check
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
			}
		} else {
			[[self dataDictionary] setObject:paths forKey:QSFilePathType];
		}
		[self setIdentifier:thisIdentifier];
		[self setPrimaryType:QSFilePathType];
		[self getNameFromFiles];
	}
	return self;
}

- (NSDictionary *)infoRecord {
	
	@synchronized (self) {
		if (![self objectForCache:@"QSItemInfoRecord"]) {
			[self setObject:[self loadInfoRecord] forCache:@"QSItemInfoRecord"];
		}
	}
	return [self objectForCache:@"QSItemInfoRecord"];
}

- (NSDictionary *)loadInfoRecord {

    NSString *path = [self validSingleFilePath];
    if (!path) {
        return nil;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSError *err = nil;
    
    // Note: NSURLLocalizedLabelKey gives a localized string of the Finder label (tag in 10.9+). E.g. Red / Rouge
    NSDictionary *dict = [fileURL resourceValuesForKeys:@[NSURLTypeIdentifierKey, NSURLIsDirectoryKey, NSURLIsAliasFileKey, NSURLIsPackageKey, NSURLLocalizedLabelKey, NSURLLocalizedNameKey, NSURLVolumeIsLocalKey, NSURLIsExecutableKey, NSURLIsUbiquitousItemKey, NSURLIsApplicationKey] error:&err];
    return dict;
}

- (BOOL)isExecutable {
    return [[[self infoRecord] objectForKey:NSURLIsExecutableKey] boolValue];
}
- (BOOL)isIcloudFile {
	return [self isUbiquitousItem];
}
- (BOOL)isUbiquitousItem {
	return [[[self infoRecord] objectForKey:NSURLIsUbiquitousItemKey] boolValue];
}

- (BOOL)canBeExecutedByScript {
    CFStringRef uti = (__bridge CFStringRef)[self fileUTI];
    if (UTTypeConformsTo(uti, CFSTR("public.script")) || UTTypeConformsTo(uti, CFSTR("public.executable"))) {
        return YES;
    }
    NSError *err;
    NSURL *url = [NSURL fileURLWithPath:[self singleFilePath]];
    NSString *resourceType;
    [url getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:nil];
    if (!resourceType || [resourceType isEqualToString:NSURLFileResourceTypeNamedPipe] || [resourceType isEqualToString:NSURLFileResourceTypeSocket]) {
        return NO;
    }
    NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingFromURL:[NSURL fileURLWithPath:[self singleFilePath]] error:&err];
    // Read in the first 5 bytes of the file to see if it contains #! (5 bytes, because some files contain byte order marks (3 bytes)
    NSData * buffer = [fileHandle readDataOfLength:5];
    NSString *string = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
    if ([string containsString:@"#!"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isFileObject {
	return [self singleFilePath] != nil;
}

- (BOOL)isApplication {
	return [[[self infoRecord] objectForKey:NSURLIsApplicationKey] boolValue] ;
}

- (BOOL)isDirectory {
	return [[[self infoRecord] objectForKey:NSURLIsDirectoryKey] boolValue];
}

- (QSObject *)resolvedAliasObject {
    QSObject *resolved = self;
    if ([self isAlias]) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *path = [manager resolveAliasAtPath:[self singleFilePath]];
        if ([manager fileExistsAtPath:path]) {
            resolved = [QSObject fileObjectWithPath:path];
        }
    }
    return resolved;
}
- (BOOL)isClipping {
	if (![self isFileObject]) {
		// it's not a file object
		return NO;
	}
	return [clippingTypes containsObject:[self fileExtension]] || [clippingTypes containsObject:[self fileUTI]];
}

- (BOOL)isFolder {
    return ([self isDirectory] && ![self isPackage]);
}

- (BOOL)isPackage {
	return [[[self infoRecord] objectForKey:NSURLIsPackageKey] boolValue];
}

- (BOOL)isAlias {
	return [[[self infoRecord] objectForKey:NSURLIsAliasFileKey] boolValue];
}

- (BOOL)isOnLocalVolume {
    return [[[self infoRecord] objectForKey:NSURLVolumeIsLocalKey] boolValue];
}

- (NSString *)fileExtension {
	NSString *extension;
	if (extension = [self objectForCache:@"extension"]) {
		return extension;
	}
	NSURL *fileURL = [NSURL fileURLWithPath:[self singleFilePath]];
	extension = [fileURL pathExtension];
	[self setObject:extension forCache:@"extension"];
	return extension;
}

- (NSString *)fileUTI {
    return [[self infoRecord] objectForKey:NSURLTypeIdentifierKey];
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
		CFStringRef kind = NULL;
		LSCopyKindStringForURL((__bridge CFURLRef)fileURL, &kind);
#ifdef DEBUG
      if (DEBUG_LOCALIZATION) NSLog(@"kind: %@", kind);
#endif
		NSString *stringKind = (__bridge_transfer NSString *)kind;
        if ([stringKind length]) {
			bundleName = [NSString stringWithFormat:@"%@ %@", bundleName, stringKind];
        }
    }
    
	return bundleName;
}

- (void)getNameFromFiles {
	NSString *newName = nil;
	if ([self count] >1) {
		NSArray *paths = [self arrayForType:QSFilePathType];
		NSString *container = [self filesContainer];
		NSString *type = [self filesType];
		BOOL onDesktop = [container isEqualToString:[@"~/Desktop/" stringByStandardizingPath]];
		newName = [NSString stringWithFormat:@"%ld %@ %@ \"%@\"", (long)[paths count] , type, onDesktop?@"on":@"in", [container lastPathComponent]];
		[self setName:newName];
		return;
	}
	// single object
	NSString *path = [self singleFilePath];
	newName = [path lastPathComponent];

	[self setName:newName];
	
	// generally: name = what you see in Terminal, label = what you see in Finder
	
	NSString *newLabel = nil;
	[[NSURL fileURLWithPath:path] getResourceValue:&newLabel forKey:NSURLLocalizedNameKey error:nil];
	if ([[newLabel pathExtension] isEqualToString:@"app"]) {
		// most apps just remove the extension
		newLabel = [newLabel stringByDeletingPathExtension];
	}

	if (UTTypeConformsTo((__bridge CFStringRef)[self fileUTI], (CFStringRef)@"com.apple.systempreference.prefpane")) {
		// get the CFBundleName for preference panes
		newLabel = [[NSBundle bundleWithPath:path] localizedInfoDictionary][@"CFBundleName"];
	}
	if (![newLabel isEqualToString:newName]) {
		[self setLabel:newLabel];
	}

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

- (NSString *)filesType {
    BOOL appsOnly = YES;
	BOOL foldersOnly = YES;
	BOOL filesOnly = YES;
	NSString *kind = nil;
	for (QSObject *obj in [self splitObjects]) {
		
		if ([obj isFolder]) {
			filesOnly = NO;
			appsOnly = NO;
            // application type (or Finder 'FNDR')
		} else if ([obj isApplication]) {
			foldersOnly = NO;
			filesOnly = NO;
		} else {
			appsOnly = NO;
			foldersOnly = NO;
            //			if (!kind) {
			kind = [self fileUTI];
            //			} else if (![kind isEqualToString:[self kindOfFile:thisPath]]) {
            //				kind = @"";
            //			}
		}
	}
	if (appsOnly) {
        return @"Applications";
    }
	if (foldersOnly) return @"Folders";
	if (filesOnly) {
		if ([kind length]) return [NSString stringWithFormat:@"[%@] ", kind];
		return @"Files";
	}
	return @"Items";
}

- (NSString *)kindOfFile:(NSString *)path {
    CFStringRef kind = NULL;
    BOOL theVal = (!path || LSCopyKindStringForURL((__bridge CFURLRef) [NSURL fileURLWithPath:path], &kind));
	return theVal ? nil : (__bridge NSString *)kind;
}

@end

