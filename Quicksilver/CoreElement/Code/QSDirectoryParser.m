//
//  QSDirectoryParser.m
//  Quicksilver
//
//  Created by Alcor on 4/6/05.

//

#import "QSDirectoryParser.h"

#import <QSCrucible/NDAlias.h>
#import <QSCrucible/NDAlias+AliasFile.h>

@implementation UKDirectoryEnumerator (QSFinderInfo) 
- (FSCatalogInfo *)currInfo{
	if (infoCache==NULL)return NULL;
	
	FSCatalogInfo*			currInfo = &(infoCache[currIndex -1]);
	
	return currInfo;	
}
@end


@implementation QSDirectoryParser
- (BOOL)validParserForPath:(NSString *)path{
  NSFileManager *manager=[NSFileManager defaultManager];
  BOOL isDirectory, exists;
  exists=[manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
  return isDirectory;
}

- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
  NSNumber *depth=[settings objectForKey:kItemFolderDepth];
  int depthValue=(depth?[depth intValue]:1);
  
	NSMutableArray *types=[NSMutableArray array];
	
	foreach(type,[settings objectForKey:kItemFolderTypes]){
		if ([type hasPrefix:@"'"] && [type length]==6){
			[types addObject:[(NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType,(CFStringRef)[type substringWithRange:NSMakeRange(1,4)],NULL) autorelease]];
		}else if ([type rangeOfString:@"."].location==NSNotFound){
			[types addObject:[(NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(CFStringRef)type,NULL) autorelease]];
		}else{
			[types addObject:type];
		}
	}
	
  NSArray *fileObjects=[self objectsFromPath:path depth:depthValue types:types];
  fileObjects=[[NSSet setWithArray:fileObjects]allObjects];
  return fileObjects;
}   

int eCount=0;

- (NSArray *)objectsFromPath:(NSString *)path depth:(int)depth types:(NSArray *)types{
  NSFileManager *manager=[NSFileManager defaultManager];
  BOOL isDirectory;
  if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) return nil;
	
  NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
	
	if (depth) depth--;
  
  NSString *file;
  NSString *aliasFile;
  NSString *type;
  
	UKDirectoryEnumerator *enumerator = [[[UKDirectoryEnumerator alloc]initWithPath:path] autorelease];
	if (!enumerator)return nil;
	
  eCount++;
	NDAlias *aliasSource;
  QSObject *obj;
	//FSCatalogInfoBitmap infoBitmap=kFSCatInfoGettableInfo;
  [enumerator setDesiredInfo:kFSCatInfoGettableInfo|kFSCatInfoFinderInfo];
	while ((file = [enumerator nextObjectFullPath])){
		FSCatalogInfo*			currInfo = [enumerator currInfo];
		type=[manager UTIOfFile:file];
		
		FileInfo*		fInfo = (FileInfo*) currInfo->finderInfo;		
		UInt16 finderFlags=fInfo->finderFlags;
		
    aliasSource=nil;
    aliasFile=nil; 
    
		isDirectory=[enumerator isDirectory];
		
    if (finderFlags & kIsAlias){
      NSString *targetFile=[manager resolveAliasAtPath:file];
		  if (targetFile){
        aliasSource=[NDAlias aliasWithContentsOfFile:file];
        aliasFile=file;
        file=targetFile;
				type=[manager UTIOfFile:file];
				
				[manager fileExistsAtPath:file isDirectory:&isDirectory];
			}
    }
		
    
		// if (![manager fileExistsAtPath:file isDirectory:&isDirectory]) continue;
    if (aliasFile || (![enumerator isInvisible] && ![[file lastPathComponent]hasPrefix:@"."] && ![file isEqualToString:@"/mach.sym"])){ // if this is the target of alias, include
			BOOL include=NO;
			if (![types count]){
				include=YES;
			}else{
				foreach(requiredType,types){
					if (UTTypeConformsTo((CFStringRef)type,(CFStringRef)requiredType)){
						include=YES;
						break;
					}
				}
			}
      if (include){
        obj=[QSObject fileObjectWithPath:file];
        if (aliasSource)[obj setObject:[aliasSource data] forType:QSAliasDataType];
        if (aliasFile)[obj setObject:aliasFile forType:QSAliasFilePathType];
        if (obj)[array addObject:obj];
				
      }
			
			if (depth && isDirectory){// && !(infoRec.flags & kLSItemInfoIsPackage))
				NSAutoreleasePool *pool=[[NSAutoreleasePool alloc]init];
				[array addObjectsFromArray:[self objectsFromPath:file depth:depth types:types]];
				[pool release];
      }
    }
		
  }
  return array;
}

@end
