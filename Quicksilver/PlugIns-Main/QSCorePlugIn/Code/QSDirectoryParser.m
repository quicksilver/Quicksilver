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
        NSString *realType = QSUTIForAnyTypeString(type);
        [types addObject:(realType ? realType : type)];
	}
    
    NSMutableArray *excludedTypes = [NSMutableArray array];
    for (NSString *excludedType in [settings objectForKey:kItemExcludeFiletypes]) {
        NSString *realType = QSUTIForAnyTypeString(excludedType);
        [excludedTypes addObject:(realType ? realType : excludedType)];
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
        [theURL getResourceValue:&URLIsSymbolicLink forKey:NSURLIsSymbolicLinkKey error:nil];
		if ([URLIsSymbolicLink boolValue]) {
            /* If this is an alias, try to resolve it to get the remaining checks right */
            NSString *targetFile = [manager resolveAliasAtPath:file];
            if (targetFile) {
                aliasSource = [NDAlias aliasWithContentsOfFile:file];
                aliasFile = file;
                file = targetFile;
                [manager fileExistsAtPath:file isDirectory:&isDirectory];
			}
		} else {
            [theURL getResourceValue:&URLIsDirectory forKey:NSURLIsDirectoryKey error:nil];
            isDirectory = [URLIsDirectory boolValue];
        }
        type = [manager UTIOfFile:file];
        // if we are an alias or the file has no reason to be included
        BOOL include = NO;
        if (![types count]) {
            include = YES;
        } else {
            for(NSString * requiredType in types) {
                if (UTTypeConformsTo((CFStringRef)type, (CFStringRef)requiredType)) {
                    include = YES;
                    break;
                }
            }
        }
        for (NSString *excludedType in excludedTypes) {
            if (UTTypeConformsTo((CFStringRef)type, (CFStringRef)excludedType)) {
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
        [theURL getResourceValue:&URLIsPackage forKey:NSURLIsPackageKey error:nil];
        if ([URLIsPackage boolValue] && !descendIntoBundles)
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
