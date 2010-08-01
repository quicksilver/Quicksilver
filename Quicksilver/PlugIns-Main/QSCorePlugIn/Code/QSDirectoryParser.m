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
	NSString *excludeValue = [settings objectForKey:kItemExcludeFiletypes];
	NSArray *excludeFiletypes = [NSArray array];
	if (excludeValue != nil)
		excludeFiletypes = [excludeValue componentsSeparatedByString:@","];
	
	NSString *descendValue = [settings objectForKey:kItemDescendIntoBundles];
	
	BOOL descendIntoBundles = [descendValue isEqualToString:@"no"] ? NO : YES;
	
	int depthValue = (depth?[depth intValue] : 1);

	NSMutableArray *types = [NSMutableArray array];

	// ???: Is this really a loop
	// Does [settings objectForKey:kItemFolderTypes] return a collection or
	// just a single item?  If just a single item then refactor the 'for' statement
	// to an 'if' statement.
#warning - Is this really a loop??? pkohut:20090412
	for(NSString * type in [settings objectForKey:kItemFolderTypes]) {
		if ([type hasPrefix:@"'"] && [type length] == 6) {
			NSString *ident = (NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, (CFStringRef)[type substringWithRange:NSMakeRange(1, 4)], NULL);
			[types addObject:ident];
			[ident release];
		} else if ([type rangeOfString:@"."] .location == NSNotFound) {
			NSString *ident = (NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)type, NULL);
			[types addObject:ident];
			[ident release];
		} else {
			[types addObject:type];
		}
	}
	return [[NSSet setWithArray:[self objectsFromPath:path depth:depthValue types:types excludes:excludeFiletypes descend:descendIntoBundles]] allObjects];
}

int eCount = 0;

- (NSArray *)objectsFromPath:(NSString *)path depth:(int)depth types:(NSArray *)types excludes:(NSArray *)excludes descend:(BOOL)descendIntoBundles {
	BOOL isDirectory; NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory)
		return nil;

	if (depth) depth--;

	UKDirectoryEnumerator *enumerator = [[UKDirectoryEnumerator alloc] initWithPath:path];
	if (!enumerator) return nil;

	eCount++;

	NSString *file, *aliasFile, *type;
	NSMutableArray *array = [NSMutableArray array];
	NDAlias *aliasSource;
	QSObject *obj;

	[enumerator setDesiredInfo: kFSCatInfoGettableInfo|kFSCatInfoFinderInfo];
	while (file = [enumerator nextObjectFullPath]) {
		FSCatalogInfo* currInfo = [enumerator currInfo];
		type = [manager UTIOfFile:file];
//		FileInfo *fInfo = (FileInfo*)currInfo->finderInfo;
//		UInt16 finderFlags = ((FileInfo*)currInfo->finderInfo)->finderFlags;
		aliasSource = nil; aliasFile = nil;
		isDirectory = [enumerator isDirectory];
		if (((FileInfo*)currInfo->finderInfo)->finderFlags & kIsAlias) {
		 NSString *targetFile = [manager resolveAliasAtPath:file];
			 if (targetFile) {
				 aliasSource = [NDAlias aliasWithContentsOfFile:file];
				 aliasFile = file;
				 file = targetFile;
				 type = [manager UTIOfFile:file];
				 [manager fileExistsAtPath:file isDirectory:&isDirectory];
			}
		}
		if (aliasFile || (![enumerator isInvisible] && ![[file lastPathComponent] hasPrefix:@"."] && ![file isEqualToString:@"/mach.sym"]) ) {
			// if this is the target of alias, include
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
			
			NSString *ext = [file pathExtension];
			if (include && ext != nil && [ext length] > 0 && [excludes containsObject:ext])
				include = NO;
			
			if (include) {
				obj = [QSObject fileObjectWithPath:file];
				if (aliasSource) [obj setObject:[aliasSource data] forType:QSAliasDataType];
				if (aliasFile) [obj setObject:aliasFile forType:QSAliasFilePathType];
				if (obj) [array addObject:obj];
			}
			
			BOOL shouldDescend = YES;
			if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:file] && !descendIntoBundles)
				shouldDescend = NO;
			
			if (depth && isDirectory && shouldDescend) {// && !(infoRec.flags & kLSItemInfoIsPackage))
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[array addObjectsFromArray:[self objectsFromPath:file depth:depth types:types excludes:excludes descend:descendIntoBundles]];
				[pool release];
			}
		}
	}
	[enumerator release];
	return array;
}

@end
