//
// NSFileManager_CarbonExtensions.m
// Quicksilver
//
// Created by Alcor on Thu Apr 03 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSFileManager_BLTRExtensions.h"

#import "NSString_BLTRExtensions.h"
#import "SUPlainInstallerInternals.h"

#define HIDDENROOT [NSArray arrayWithObjects:@"automount", @"bin", @"cores", @"dev", @"etc", @"mach", @"mach.sym", @"mach_kernel", @"private", @"sbin", @"sbin", @"tmp", @"usr", @"var", nil]

@implementation NSFileManager (Carbon)

- (BOOL)movePathToTrash:(NSString *)filepath {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    BOOL result = [ws performFileOperation:NSWorkspaceRecycleOperation
                                    source:[filepath stringByDeletingLastPathComponent]
                               destination:@""
                                     files:[NSArray arrayWithObject:[filepath lastPathComponent]]
                                       tag:nil];
    if (!result) {
        BOOL didFindTrash;
        NSString *trashPath = [SUPlainInstaller _temporaryCopyNameForPath:filepath didFindTrash:&didFindTrash];
        if (didFindTrash) {
			NSError	 *err = nil;
            result = [SUPlainInstaller _movePathWithForcedAuthentication:filepath toPath:trashPath error:&err];
            if (!result) {
				NSLog(@"Couldn't move %@ to the trash (%@). %@", filepath, trashPath, err);
            }
		}
    }
    return result;
}

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
	CFURLRef cfURL = (__bridge_retained CFURLRef)[NSURL fileURLWithPath:path];
	OSStatus status = LSCopyItemInfoForURL(cfURL, kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	CFRelease(cfURL);
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
		LSCopyItemInfoForURL((__bridge CFURLRef) [NSURL fileURLWithPath:path], kLSRequestBasicFlagsOnly, &infoRec);
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
	NSURL *url = [NSURL fileURLWithPath:aliasFullPath];
	
	// First resolve any symlinks
	NSURL *resolvedURL = [url URLByReallyResolvingSymlinksInPath];

	// File is a Finder alias file, resolve bookmark data first
	NSError *err;
	NSData *bookmarkData = [NSURL bookmarkDataWithContentsOfURL:resolvedURL error:&err];
	if (!bookmarkData) {
		return [resolvedURL path];
	}

	NSUInteger options = 0;
	if (!usingUI) {
		options |= (NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting);
	}
	NSURL *aliasURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:options relativeToURL:nil bookmarkDataIsStale:nil error:&err];

	if (!aliasURL) {
		return nil;
	}
	return [aliasURL path];
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
	for (__strong NSString *file in [manager contentsOfDirectoryAtPath:path error:nil]) {
		file = [path stringByAppendingPathComponent:file];
        NSURL *fileURL = [NSURL fileURLWithPath:file];
        NSError *err = nil;
        NSDictionary *fileProperties = [fileURL resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLTypeIdentifierKey, NSURLIsAliasFileKey, NSURLIsHiddenKey, NSURLIsPackageKey] error:&err];
        if (err) {
            NSLog(@"Unable to obtain file information for %@", file);
            continue;
        }

		if ([[fileProperties objectForKey:NSURLIsAliasFileKey] boolValue]) {
			NSString *aliasFile = [self resolveAliasAtPath:file];
			if (aliasFile && [manager fileExistsAtPath:aliasFile]) {
				file = aliasFile;
                fileURL = [NSURL fileURLWithPath:file];
                fileProperties = [fileURL resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLTypeIdentifierKey, NSURLIsAliasFileKey, NSURLIsHiddenKey, NSURLIsPackageKey] error:&err];

			}
		}
        type = [fileProperties objectForKey:NSURLTypeIdentifierKey];

		if (![[fileProperties objectForKey:NSURLIsHiddenKey] boolValue]) {
			if ((!types) || [types containsObject:type]) {
				[array addObject:file];
			}
		}
		if (depth && [[fileProperties objectForKey:NSURLIsDirectoryKey] boolValue] && !([[fileProperties objectForKey:NSURLIsPackageKey] boolValue]) )
			[array addObjectsFromArray:[self itemsForPath:file depth:depth types:types]];
	}

	return array;
}

- (BOOL)touchPath:(NSString *)path {
	return [self setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:path error:nil];

}


- (NSDate *)path:(NSString *)path wasModifiedAfter:(NSDate *)date depth:(NSInteger)depth {
    NSURL *pathURL = [NSURL fileURLWithPath:path];
    if (!pathURL) {
        return nil;
    }
    if (depth) depth--;

    NSError *err = nil;
    NSDictionary *attributes = [pathURL resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLContentModificationDateKey] error:nil];
    if (err) {
        NSLog(@"Error: %@", err);
    }

	NSDate *moddate = attributes[NSURLContentModificationDateKey];

    if (!moddate) {
        return date;
    }

	if ([date compare:moddate] == NSOrderedAscending && [moddate timeIntervalSinceNow] <0) {
		return moddate;
	}
	if (attributes[NSURLIsDirectoryKey]) {
		for (__strong NSURL *url in [self contentsOfDirectoryAtURL:pathURL includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsPackageKey] options:0 error:nil]) {
            NSNumber *isDirectory;
            NSNumber *isPackage;
            [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
            [url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
			if (depth && isDirectory && !isPackage) {
                @autoreleasepool {
                    moddate = [self path:[url path] wasModifiedAfter:date depth:depth--];
                }
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
		for (__strong NSString *file in [self contentsOfDirectoryAtPath:path error:nil]) {
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
