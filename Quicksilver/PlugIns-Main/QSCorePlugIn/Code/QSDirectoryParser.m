//
// QSDirectoryParser.m
// Quicksilver
//
// Created by Alcor on 4/6/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSDirectoryParser.h"

#import "NDAlias+AliasFile.h"


@implementation QSDirectoryParser
- (BOOL)validParserForPath:(NSString *)path {
	BOOL isDirectory;
	[[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    
	return isDirectory;
}

- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings {
	NSNumber *depth = [settings objectForKey:kItemFolderDepth];
	NSInteger depthValue = (depth?[depth integerValue] : 1);
    BOOL descendIntoBundles = [[settings objectForKey:kItemDescendIntoBundles] boolValue];

	NSMutableArray *types = [NSMutableArray array];
	for (NSString *type in [settings objectForKey:kItemFolderTypes]) {
        [types addObject:QSUTIForAnyTypeString(type)];
	}
    
    NSMutableArray *excludedTypes = [NSMutableArray array];
    for (NSString *excludedType in [settings objectForKey:kItemExcludeFiletypes]) {
        [excludedTypes addObject:QSUTIForAnyTypeString(excludedType)];
    }
	return [[NSSet setWithArray:[self objectsFromPath:path depth:depthValue types:types excludeTypes:excludedTypes descend:descendIntoBundles]] allObjects];
}

- (NSArray *)objectsFromPath:(NSString *)path depth:(NSInteger)depth types:(NSArray *)types excludeTypes:(NSArray *)excludedTypes descend:(BOOL)descendIntoBundles {
#ifdef DEBUG
    NSDate *startDate = [NSDate date];
#endif
	BOOL isDirectory;
    NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory)
		return nil;

	if (depth) depth--;

    NSArray *properties = @[NSURLIsSymbolicLinkKey, NSURLIsAliasFileKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, NSURLIsPackageKey];
    
    NSDirectoryEnumerator *enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:path]
                                      includingPropertiesForKeys:properties
                                                         options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                    errorHandler:nil];
	if (!enumerator) return nil;

	NSMutableArray *array = [NSMutableArray array];

    for (NSURL *theURL in enumerator) {
        NSString *file = [theURL path];

        NSString *type = nil;

		NDAlias *aliasSource = nil; // So we can keep track of which alias was resolved
        NSString *aliasFile = nil;

        NSError *err;
        NSDictionary *resources = [theURL resourceValuesForKeys:properties error:&err];
        if (!resources) {
            // Do nothing. Still add the file to the catalog, just we will know little about it.
            // Typically, this error will only occur for sockets or fifos (since they're not actually files)
        }

        NSURL *targetURL = nil;

        if ([resources[NSURLIsAliasFileKey] boolValue]) {
            NSDictionary *newResources = [resources copy];
            targetURL = theURL;

            while ([newResources[NSURLIsAliasFileKey] boolValue]) {
                // NB: `NSURLIsAliasFileKey` AND `NSURLIsSymbolicLinkKey`
                // are BOTH true for symlinks (only the former for aliases,
                // or even aliases to symlinks)

                if ([newResources[NSURLIsSymbolicLinkKey] boolValue]) {
                    targetURL = [targetURL URLByReallyResolvingSymlinksInPath];
                } else {
                    BOOL stale = NO;
                    targetURL = [NSURL URLByResolvingBookmarkAtURL:targetURL
                                                           options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting
                                               bookmarkDataIsStale:&stale
                                                             error:&err];

                    if (!targetURL) {
                        NSLog(@"Error resolving %@alias at %@: %@", (stale ? @"stale " : @""), theURL, err);
                    }
                }
                newResources = [targetURL resourceValuesForKeys:properties error:&err];
            }
        } else {
            isDirectory = [resources[NSURLIsDirectoryKey] boolValue];
        }

        if (targetURL) {
            /* This was a symlink or an alias, grab the correct information */
            aliasSource = [NDAlias aliasWithContentsOfFile:file];
            aliasFile = file;
            file = [targetURL path];
            [manager fileExistsAtPath:file isDirectory:&isDirectory];
            [[NSURL fileURLWithPath:file] getResourceValue:&type forKey:NSURLTypeIdentifierKey error:nil];
		}
        if (!type) {
            type = resources[NSURLTypeIdentifierKey];
        }

        // Check if the type is wanted, or not
        BOOL include = NO;
        if (![types count]) {
            include = YES;
        } else {
            for (NSString *requiredType in types) {
                if (QSTypeConformsTo(type, requiredType)) {
                    include = YES;
                    break;
                }
            }
        }
        for (NSString *excludedType in excludedTypes) {
            if (QSTypeConformsTo(type, excludedType)) {
                include = NO;
            }
        }
        
        if (include) {
            QSObject *obj = [QSObject fileObjectWithFileURL:theURL];
            if (aliasSource) [obj setObject:[aliasSource data] forType:QSAliasDataType];
            if (aliasFile) [obj setObject:aliasFile forType:QSAliasFilePathType];
            if (obj) [array addObject:obj];
        }
        
        BOOL shouldDescend = YES;
        if ([resources[NSURLIsPackageKey] boolValue] && !descendIntoBundles)
            shouldDescend = NO;
        
        if (depth && isDirectory && shouldDescend) {
            @autoreleasepool {
                [array addObjectsFromArray:[self objectsFromPath:[theURL path] depth:depth types:types excludeTypes:excludedTypes descend:descendIntoBundles]];
            }
        }
    }
#ifdef DEBUG
    if (VERBOSE) {
        NSLog(@"Scanning %@ took %ld µs",path,(long)(-[startDate timeIntervalSinceNow]*1000000));
    }
#endif
	return array;
}

@end
