//
// NSFileManager_CarbonExtensions.m
// Quicksilver
//
// Created by Alcor on Thu Apr 03 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSFileManager_BLTRExtensions.h"

#import "NSString_BLTRExtensions.h"

#import "Carbon/Carbon.h"
#define HIDDENROOT [NSArray arrayWithObjects:@"automount", @"bin", @"cores", @"dev", @"etc", @"mach", @"mach.sym", @"mach_kernel", @"private", @"sbin", @"sbin", @"tmp", @"usr", @"var", nil]

@implementation NSFileManager (Carbon)

- (BOOL)isVisible:(NSString *)path {
	LSItemInfoRecord infoRec;
	OSStatus status = LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path], kLSRequestBasicFlagsOnly, &infoRec);
/*	BOOL result = ! ( (infoRec.flags & kLSItemInfoIsInvisible) || ([[path stringByDeletingLastPathComponent] isEqualToString:@"/"] && [HIDDENROOT containsObject:[path lastPathComponent]]) || (status && [[path lastPathComponent] hasPrefix:@"."]) );
	return result;*/
	return ! ( (infoRec.flags & kLSItemInfoIsInvisible) || (status && [[path lastPathComponent] hasPrefix:@"."]) );
}

#if 0
- (BOOL)isHiddenFile:(NSString *)path {
 	NSRange slashRange = [path rangeOfString:@"/" options:nil range:NSMakeRange(1, [path length]-1)];
	return ( ( (slashRange.location == NSNotFound || NSMaxRange(slashRange) == [path length]) && ([[[NSString stringWithContentsOfFile:@"/.hidden"] componentsSeparatedByString:@"\n"] containsObject:[path lastPathComponent]]) ) || [[path lastPathComponent] hasPrefix:@"."] );
}
#endif

#if 0
- (NSString *)humanReadableFiletype:(NSString *)path {
	NSString *res;
	LSCopyKindStringForURL((CFURLRef) [NSURL fileURLWithPath:path] , (CFStringRef *)&res );
	return [res autorelease];
}
#endif

- (BOOL)movePathToTrash:(NSString *)filepath {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    BOOL result = [ws performFileOperation:NSWorkspaceRecycleOperation
                                    source:[filepath stringByDeletingLastPathComponent]
                               destination:@""
                                     files:[NSArray arrayWithObject:[filepath lastPathComponent]]
                                       tag:nil];
    if (!result) {
        NSLog(@"Failed to move file %@ to Trash", filepath);
    }
    return result;
}

#if 0
- (BOOL)movePathToTrashUsingFinder:(NSString *)filepath {
	AppleEvent		event, reply;
	OSErr			err;
	OSType			adrFinder = 'MACS';
	FSRef			fileRef;
	AliasHandle		fileAlias = NULL;

	err = FSPathMakeRef((const UInt8 *)[filepath fileSystemRepresentation] , &fileRef,
						NULL);
	if (err != noErr) return NO;

	err = FSNewAliasMinimal(&fileRef, &fileAlias);
	if (err != noErr) return NO;

	err = AEBuildAppleEvent('core', 'delo', typeApplSignature,
							&adrFinder, sizeof(adrFinder),
							kAutoGenerateReturnID, kAnyTransactionID, &event, NULL,
							"'----':alis(@@) ", fileAlias);
	if (err != noErr) return NO;

	err = AESend(&event, &reply, kAEWaitReply, kAENormalPriority,
				 kAEDefaultTimeout, NULL, NULL);
	AEDisposeDesc(&event);
	AEDisposeDesc(&reply);

	if (fileAlias)
		DisposeHandle((Handle) fileAlias);

	return YES;
}
#endif

@end

@implementation NSFileManager (Scanning)
- (NSString *)UTIOfFile:(NSString *)path {
	return QSUTIOfFile(path);
}

- (NSString *)UTIOfURL:(NSURL *)fileURL {
	return QSUTIOfURL(fileURL);
}

- (NSString *)typeOfFile:(NSString *)path {
	BOOL isDirectory;

	if (![self fileExistsAtPath:path isDirectory:&isDirectory])
		return nil;

	LSItemInfoRecord infoRec;
	OSStatus status = LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path], kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	if (status)
		return @"";

	if (infoRec.flags & kLSItemInfoIsAliasFile)
		return @"'alis'";
	OSType fileType = infoRec.filetype;
	if (fileType == 'APPL')
		return NSFileTypeForHFSTypeCode(fileType);

	NSString *hfsType = NSFileTypeForHFSTypeCode(fileType);
	if ([hfsType isEqualToString:@"''"]) hfsType = nil;

	if (!hfsType && isDirectory && infoRec.flags&kLSItemInfoIsPackage) {
		NSString *packageType = [NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/PkgInfo"] usedEncoding:nil error:nil];
		if ([packageType length] >= 4)
			packageType = [packageType substringToIndex:4];
		if (packageType)
			packageType = [NSString stringWithFormat:@"'%@'", packageType];
		if (packageType && ![packageType isEqualToString:@"'BNDL'"])
			hfsType = packageType;
		if ([hfsType isEqualToString:@"'APPL'"])
			return @"'APPL'";
	}

	NSString *extension = [path pathExtension];
	// if no extension or is a directory
        // 29/12/2009 Patrick Robertson
        // Fix bug #34
	if (![extension length] || isDirectory)
	{
		extension = nil;
	}
	// Defines a directory
	if (![hfsType length] && isDirectory)
		hfsType = @"'fold'";
	
	// NSLog(@"Checking if directory... path is: %@", path);
	
	// Defines if is a file with 'extension'
	if (extension)
		return extension;
	else if (hfsType)
		return hfsType;
	else
		return @"";
}

- (NSString *)fullyResolvedPathForPath:(NSString *)sourcePath {
	NSString *path = @"";
	for(NSString *thisComponent in [[sourcePath stringByStandardizingPath] pathComponents]) {
		path = [path stringByAppendingPathComponent:thisComponent];
		if (![self fileExistsAtPath:path])
			continue;
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path], kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsAliasFile)
			path = [[self resolveAliasAtPath:path] stringByResolvingSymlinksInPath];
	}
	return path;
}

- (NSString *)resolveAliasAtPath:(NSString *)aliasFullPath {
    return [self resolveAliasAtPath:aliasFullPath usingUI:NO];
}

- (NSString *)resolveAliasAtPathWithUI:(NSString *)aliasFullPath {
    return [self resolveAliasAtPath:aliasFullPath usingUI:YES];
}

- (NSString *)resolveAliasAtPath:(NSString *)aliasFullPath usingUI:(BOOL)usingUI {
	NSString *outString = nil;
	NSURL *url = [NSURL fileURLWithPath:aliasFullPath];
	FSRef aliasRef;
	Boolean targetIsFolder;
	Boolean wasAliased;

	if (!CFURLGetFSRef((CFURLRef)url, &aliasRef))
		return nil;

    if (FSResolveAliasFileWithMountFlags(&aliasRef, true, &targetIsFolder, &wasAliased, (!usingUI ? kResolveAliasFileNoUI : 0)))
        return nil;

	if (url = (NSURL *)CFURLCreateFromFSRef(kCFAllocatorDefault, &aliasRef)) {
		outString = [url path];
		CFRelease(url);
		return outString;
	}
	return nil;
}

- (NSArray *)itemsForPath:(NSString *)path depth:(NSInteger)depth types:(NSArray *)types {
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if (![manager fileExistsAtPath:path isDirectory:&isDirectory])
		return nil;

	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];

	if (depth)
		depth--;
	if (depth == -10)
		//if (VERBOSE) NSLog(@"Scan Depth Exceeded 10 Levels with: %@", path);
		return array;

	NSString *type;
	LSItemInfoRecord infoRec;
//	OSStatus status;
	for (NSString *file in [manager contentsOfDirectoryAtPath:path error:nil]) {
		file = [path stringByAppendingPathComponent:file];
		type = [self typeOfFile:file];

		/*status = */LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:file], kLSRequestBasicFlagsOnly, &infoRec);

		if (infoRec.flags & kLSItemInfoIsAliasFile) {
			NSString *aliasFile = [self resolveAliasAtPath:file];
			if (aliasFile && [manager fileExistsAtPath:aliasFile]) {
				file = aliasFile;
				LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:file] , kLSRequestBasicFlagsOnly, &infoRec);
			}
		}
		if (![manager fileExistsAtPath:file isDirectory:&isDirectory])
			continue;
		if ([manager isVisible:file]) {
			if ((!types) || [types containsObject:type]) {
				[array addObject:file];
			}
		}
		if (depth && isDirectory && !(infoRec.flags & kLSItemInfoIsPackage) )
			[array addObjectsFromArray:[self itemsForPath:file depth:depth types:types]];
	}
	// NSLog(@"%@", array);
	return array;
}

- (BOOL)touchPath:(NSString *)path {
	return [self setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:path error:nil];
}

- (NSDate *)path:(NSString *)path wasModifiedAfter:(NSDate *)date depth:(NSInteger)depth {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	BOOL isDirectory;
	if (![self fileExistsAtPath:path isDirectory:&isDirectory]) return nil;

	if (depth) depth--;

    NSError *err = nil;
	NSDate *moddate = [[self attributesOfItemAtPath:path error:&err] fileModificationDate];
    if (err) {
        NSLog(@"Error: %@",err);
    }
    if (!moddate) {
        return date;
    }
	if ([date compare:moddate] == NSOrderedAscending && [moddate timeIntervalSinceNow] <0) {
		return moddate;
	}
	if (isDirectory) {
		for (NSString *file in [self contentsOfDirectoryAtPath:path error:nil]) {
			file = [path stringByAppendingPathComponent:file];
			if (![self fileExistsAtPath:file isDirectory:&isDirectory]) continue;

			if (depth && isDirectory && ![workspace isFilePackageAtPath:file]) {
                @autoreleasepool {
                    moddate = [self path:file wasModifiedAfter:date depth:depth--];
                    [moddate retain];
                }
				[moddate autorelease];
				if (moddate)
					return moddate;
			}
		}
	}

	return nil;
}

- (NSDate *)modifiedDate:(NSString *)path depth:(NSInteger)depth {
	BOOL isDirectory;
	if (![self fileExistsAtPath:path isDirectory:&isDirectory])
		return nil;

	if (depth) depth--;

	NSDate *moddate = [self pastOnlyModifiedDate:path];
	if ([moddate timeIntervalSinceNow] >0)
		moddate = [NSDate distantPast];
	if (isDirectory) {
		for (NSString *file in [self contentsOfDirectoryAtPath:path error:nil]) {
			file = [path stringByAppendingPathComponent:file];
			if (![self fileExistsAtPath:file isDirectory:&isDirectory]) continue;

			if (depth && isDirectory && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:file]) {
				moddate = [moddate laterDate:[self modifiedDate:file depth:depth]];
			}
		}
	}
	return moddate;
}



- (NSDate *)pastOnlyModifiedDate:(NSString *)path {
	NSDate *moddate = [[self attributesOfItemAtPath:path error:NULL] fileModificationDate];
	if ([moddate timeIntervalSinceNow] > 0) {
		//NSLog(@"File has future date: %@\r%@", path, [moddate description]);
		moddate = [NSDate distantPast];
	}
	return moddate;
}

@end


@implementation NSFileManager (BLTRExtensions)

- (BOOL)createDirectoriesForPath:(NSString *)path {
	if ([path length]){
		if (![self fileExistsAtPath:[path stringByDeletingLastPathComponent] isDirectory:nil])
			[self createDirectoriesForPath:[path stringByDeletingLastPathComponent]];
		return [self createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
	} else return NO;
}
- (NSInteger)defaultDragOperationForMovingPaths:(NSArray *)sources toDestination:(NSString *)destination {
	NSDictionary *dAttr = [self attributesOfItemAtPath:destination error:NULL];
    
	for (NSString *aString in sources) {
		if ([aString isEqualToString:destination]) {
			return NSDragOperationNone;
        }
		NSDictionary *sAttr = [self attributesOfItemAtPath:[sources objectAtIndex:0] error:NULL];
		if (![[sAttr objectForKey:NSFileSystemNumber] isEqualTo:[dAttr objectForKey:NSFileSystemNumber]])
			return NSDragOperationCopy;
	}
	return NSDragOperationMove;
}

- (BOOL)filesExistAtPaths:(NSArray *)paths {
	NSString *thisFile;
	for(thisFile in paths)
		if (![self fileExistsAtPath:thisFile]) return NO;
	return YES;
}

- (NSDictionary *)conflictsForFiles:(NSArray *)files inDestination:(NSString *)destination {
	NSMutableDictionary *conflicts = [NSMutableDictionary dictionaryWithCapacity:0];

	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *file;
	NSString *destinationPath;

	for(file in files) {
		destinationPath = [destination stringByAppendingPathComponent:[file lastPathComponent]];
		if ([manager fileExistsAtPath:destinationPath])
			[conflicts setObject:destinationPath forKey:file];
	}
	if (![conflicts count])
		return nil;
	return conflicts;
}
@end
