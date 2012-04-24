//
// QSDirectoryParser.m
// Quicksilver
//
// Created by Alcor on 4/6/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSDirectoryParser.h"

#import <QSFoundation/NDAlias.h>
#import <QSCore/QSCore.h>
#import "UKDirectoryEnumerator.h"
#import "NDAlias+AliasFile.h"

@interface UKDirectoryEnumerator (QSFinderInfo)
- (FSCatalogInfo *)currInfo;
@end

@implementation UKDirectoryEnumerator (QSFinderInfo)
- (FSCatalogInfo *)currInfo {
	if (infoCache == NULL) return NULL;
	FSCatalogInfo *currInfo = &(infoCache[currIndex-1]);
	return currInfo;
}
@end


@implementation QSDirectoryParser
- (BOOL)validParserForPath:(NSString *)path {
	BOOL isDirectory;
	[[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    
	return isDirectory;
}

- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings {
	NSNumber *depth = [settings objectForKey:kItemFolderDepth];
	int depthValue = (depth?[depth intValue] : 1);
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

- (NSArray *)objectsFromPath:(NSString *)path depth:(int)depth types:(NSArray *)types excludeTypes:(NSArray *)excludedTypes descend:(BOOL)descendIntoBundles {
	BOOL isDirectory; NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory)
		return nil;

	if (depth) depth--;

	UKDirectoryEnumerator *enumerator = [[UKDirectoryEnumerator alloc] initWithPath:path];
	if (!enumerator) return nil;

	NSString *file, *aliasFile, *type;
	NSMutableArray *array = [NSMutableArray array];
	NDAlias *aliasSource;
	QSObject *obj;

	[enumerator setDesiredInfo: kFSCatInfoGettableInfo | kFSCatInfoFinderInfo];
	while (file = [enumerator nextObjectFullPath]) {
		aliasSource = nil; aliasFile = nil;
		isDirectory = [enumerator isDirectory];
		if ([enumerator isAlias]) {
            /* If this is an alias, try to resolve it to get the remaining checks right */
            NSString *targetFile = [manager resolveAliasAtPath:file];
			 if (targetFile) {
				 aliasSource = [NDAlias aliasWithContentsOfFile:file];
				 aliasFile = file;
				 file = targetFile;
				 [manager fileExistsAtPath:file isDirectory:&isDirectory];
			}
		}
		if (aliasFile || (![enumerator isInvisible] && ![[file lastPathComponent] hasPrefix:@"."] && ![file isEqualToString:@"/mach.sym"]) ) {
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
				obj = [QSObject fileObjectWithPath:file];
				if (aliasSource) [obj setObject:[aliasSource data] forType:QSAliasDataType];
				if (aliasFile) [obj setObject:aliasFile forType:QSAliasFilePathType];
				if (obj) [array addObject:obj];
			}
			
			BOOL shouldDescend = YES;
			if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:file] && !descendIntoBundles)
				shouldDescend = NO;
			
			if (depth && isDirectory && shouldDescend) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[array addObjectsFromArray:[self objectsFromPath:file depth:depth types:types excludeTypes:excludedTypes descend:descendIntoBundles]];
				[pool release];
			}
		}
	}
	[enumerator release];
	return array;
}

@end
