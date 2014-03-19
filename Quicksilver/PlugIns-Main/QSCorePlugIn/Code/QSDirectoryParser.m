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
	BOOL isDirectory; NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory)
		return nil;

	if (depth) depth--;
    
    NSDirectoryEnumerator *enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:path] includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey,NSURLIsSymbolicLinkKey,NSURLIsPackageKey,nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
	if (!enumerator) return nil;

	NSString *file, *aliasFile, *type;
	NSMutableArray *array = [NSMutableArray array];
	NDAlias *aliasSource;
	QSObject *obj;
    NSNumber *URLIsSymbolicLink;
    NSNumber *URLIsDirectory;
    NSNumber *URLIsPackage;
    
	for (NSURL *theURL in enumerator) {
        file = [theURL path];
		aliasSource = nil; aliasFile = nil;
        NSError *err;
        NSDictionary *resources = [theURL resourceValuesForKeys:@[NSURLIsSymbolicLinkKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, NSURLIsPackageKey] error:&err];
        if (err) {
            // Do nothing. Still add the file to the catalog, just we will know little about it.
            // Typically, this error will only occur for sockets or fifos (since they're not actually files)
        }
		if ([resources[URLIsSymbolicLink] boolValue]) {
            /* If this is an alias, try to resolve it to get the remaining checks right */
            NSString *targetFile = [manager resolveAliasAtPath:file];
            if (targetFile) {
                aliasSource = [NDAlias aliasWithContentsOfFile:file];
                aliasFile = file;
                file = targetFile;
                [manager fileExistsAtPath:file isDirectory:&isDirectory];
			}
		} else {
            isDirectory = [resources[URLIsDirectory] boolValue];
        }
        type = resources[NSURLTypeIdentifierKey];
        // if we are an alias or the file has no reason to be included
        BOOL include = NO;
        if (![types count]) {
            include = YES;
        } else {
            for(NSString * requiredType in types) {
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
            obj = [QSObject fileObjectWithFileURL:theURL];
            if (aliasSource) [obj setObject:[aliasSource data] forType:QSAliasDataType];
            if (aliasFile) [obj setObject:aliasFile forType:QSAliasFilePathType];
            if (obj) [array addObject:obj];
        }
        
        BOOL shouldDescend = YES;
        if ([resources[URLIsPackage] boolValue] && !descendIntoBundles)
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
