//
//  NSFileManager_CarbonExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu Apr 03 2003.

//

#import "NSFileManager_BLTRExtensions.h"

#import "NSString_BLTRExtensions.h"
#import "UKDirectoryEnumerator.h"

@interface UKDirectoryEnumerator (Private)
- (NSDate *)fileModificationDate;
@end
#import "Carbon/Carbon.h"
#define HIDDENROOT [NSArray arrayWithObjects:@"home", @"net", @"automount",@"bin",@"cores",@"dev",@"etc",@"mach",@"mach.sym",@"mach_kernel",@"private",@"sbin",@"sbin",@"tmp",@"usr",@"var",nil]
@implementation NSFileManager (Carbon)

- (bool) isVisible:(NSString *)path{
    LSItemInfoRecord infoRec;
    OSStatus status=LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
    if (infoRec.flags & kLSItemInfoIsInvisible) return NO;
    
    if ([[path stringByDeletingLastPathComponent] isEqualToString:@"/"]){
	
       // NSArray *hiddenFiles=[[NSString stringWithContentsOfFile:@"/.hidden"]componentsSeparatedByString:@"\n"];
      //  if ([hiddenFiles containsObject:[path lastPathComponent]]) return NO;
		if ([HIDDENROOT containsObject:[path lastPathComponent]]) return NO;
    }
    if (status){
        if ([[path lastPathComponent]hasPrefix:@"."])return NO;
        //QSLog(@"%d",status);
    }
    return YES;
}

- (BOOL)isHiddenFile:(NSString *)path{
  	NSRange slashRange=[path rangeOfString:@"/" options:0 range:NSMakeRange(1,[path length]-1)];
	if (slashRange.location==NSNotFound || NSMaxRange(slashRange) == [path length]){
		// if ([[path stringByDeletingLastPathComponent] isEqualToString:@"/"]){
		QSLog(@"hidden?");
        NSArray *hiddenFiles=[[NSString stringWithContentsOfFile:@"/.hidden"]componentsSeparatedByString:@"\n"];
        if ([hiddenFiles containsObject:[path lastPathComponent]]) return YES;
		}
	if ([[path lastPathComponent]hasPrefix:@"."])return YES;
	return NO;
	}

- (NSString *)humanReadableFiletype:(NSString *)path{
    NSString *res;
    LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:path],(CFStringRef *)&res );
    return [res autorelease];
}

- (BOOL)movePathToTrash:(NSString *)filepath{
	NSString *trashfilepath=[[@"~/.Trash/" stringByStandardizingPath]stringByAppendingPathComponent:[filepath lastPathComponent]];
	trashfilepath=[trashfilepath firstUnusedFilePath];
	
	return [self movePath:filepath toPath:trashfilepath handler:nil];
}

- (BOOL)movePathToTrashUsingFinder:(NSString *)filepath{
	AppleEvent        event, reply;
	OSErr            err;
	OSType            adrFinder = 'MACS';
	FSRef            fileRef;
	AliasHandle        fileAlias = NULL;
	
	err = FSPathMakeRef((const UInt8 *)[filepath fileSystemRepresentation], &fileRef, 
						NULL);
	if (err != noErr) return NO;
	
	err = FSNewAliasMinimal(&fileRef, &fileAlias);
	if (err != noErr) return NO;
	
	err = AEBuildAppleEvent('core', 'delo', typeApplSignature, 
							&adrFinder, sizeof(adrFinder),
							kAutoGenerateReturnID, kAnyTransactionID, &event, NULL,
							"'----':alis(@@)", fileAlias);
	if (err != noErr) return NO;
	
	err = AESend(&event, &reply, kAEWaitReply, kAENormalPriority, 
				 kAEDefaultTimeout, NULL, NULL);
	AEDisposeDesc(&event);
	AEDisposeDesc(&reply);
    
    if (fileAlias)
        DisposeHandle((Handle)fileAlias);
	
	return YES;
	
}

@end

NSString *QSUTIWithLSInfoRec(NSString *path,LSItemInfoRecord *infoRec);

NSString *QSUTIOfFile(NSString *path){
	LSItemInfoRecord infoRec;
	// OSStatus status=
	LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],
						 kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	
	
	return QSUTIWithLSInfoRec(path,&infoRec);
}

NSString *QSUTIWithLSInfoRec(NSString *path,LSItemInfoRecord *infoRec){
    NSString *extension=[path pathExtension];
	
    if (![extension length])
		extension=nil; 
	BOOL isDirectory;//, isPackage;
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) return nil;
		
		NSString *extensionUTI = [(NSString *)UTTypeCreatePreferredIdentifierForTag (kUTTagClassFilenameExtension,(CFStringRef)extension, NULL) autorelease];
		NSString *hfsType=[(NSString *)UTCreateStringForOSType(infoRec->filetype) autorelease];
		
		
		
		if (infoRec->flags & kLSItemInfoIsAliasFile)
			return (NSString *)kUTTypeAliasFile;
		if (infoRec->flags & kLSItemInfoIsVolume)
			return (NSString *)kUTTypeVolume;
		
		//BOOL executable=;
		
		//if ([hfsType isEqualToString:@"APPL"]) return kUTTypeApplication;
		
		//	if ([hfsType isEqualToString:@"''"]) hfsType=nil;
		//	QSLog(@"hfs %@> %@<",hfsType,extensionUTI);
		//	isPackage=infoRec->flags & kLSItemInfoIsPackage;
		//	if (![hfsType length] && isDirectory && isPackage){
		//        NSString *packageType=[NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/PkgInfo"]];
		//        if ([packageType length]>=4)
		//            packageType=[packageType substringToIndex:4];
		//        if (packageType) packageType=[NSString stringWithFormat:@"%@",packageType];
		//        if (packageType && ![packageType isEqualToString:@"BNDL"])
		//            hfsType=packageType;
		//		//  if ([hfsType isEqualToString:@"'APPL'"]) 
		//		//	return kUTTypeApplication;
		//    }
		
		NSString *hfsUTI=[(NSString *)UTTypeCreatePreferredIdentifierForTag (kUTTagClassOSType,(CFStringRef)hfsType, NULL) autorelease];
		
		
		
		if (extensionUTI && ![extensionUTI hasPrefix:@"dyn"])
			return extensionUTI;
		
		if (![hfsType length] && isDirectory)
			return (NSString *)kUTTypeFolder;
		//	if ([hfsType length]){
		//hfsUTI=[UTTypeCreatePreferredIdentifierForTag (kUTTagClassOSType,[hfsType substringWithRange:NSMakeRange(1,4)], NULL) autorelease];
		
		
		if (![hfsUTI hasPrefix:@"dyn"]){
			return hfsUTI;		
		}
		
		if([[NSFileManager defaultManager] isExecutableFileAtPath:path]){
			return @"public.executable";
		}
		return (extensionUTI?extensionUTI:hfsUTI);
		
		}


@implementation NSFileManager (Scanning)
- (NSString *)UTIOfFile:(NSString *)path{
	return QSUTIOfFile(path);
}

- (NSString *)typeOfFile:(NSString *)path{
    BOOL isDirectory, isPackage;
    
    if (![self fileExistsAtPath:path isDirectory:&isDirectory]) return nil;
    
    LSItemInfoRecord infoRec;
    OSStatus status=LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],
                                         kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
    if (status){
		return @"";
    }
	
    NSString *extension=[path pathExtension];
    if (![extension length]) extension=nil; 
    
    isPackage=infoRec.flags & kLSItemInfoIsPackage;
    if (infoRec.flags & kLSItemInfoIsAliasFile)return @"'alis'";
    OSType fileType=infoRec.filetype;
    if (fileType=='APPL') return NSFileTypeForHFSTypeCode(fileType);
    
    NSString *hfsType=NSFileTypeForHFSTypeCode(fileType);
    if ([hfsType isEqualToString:@"''"]) hfsType=nil;
    
    if (!hfsType && isDirectory && isPackage){
        NSString *packageType=[NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/PkgInfo"]];
        if ([packageType length]>=4)
            packageType=[packageType substringToIndex:4];
        if (packageType) packageType=[NSString stringWithFormat:@"'%@'",packageType];
        if (packageType && ![packageType isEqualToString:@"'BNDL'"])
            hfsType=packageType;
        if ([hfsType isEqualToString:@"'APPL'"]) return @"'APPL'";
    }
    
    if (![hfsType length] && isDirectory)hfsType=@"'fold'";
    
    if (extension)
        return extension;
    else if  (hfsType)
        return hfsType;
    else return @"";
}

- (NSString *)fullyResolvedPathForPath:(NSString *)sourcePath{
    NSEnumerator *enumer=[[[[sourcePath stringByStandardizingPath]stringByResolvingSymlinksInPath] pathComponents]objectEnumerator];
    NSString *thisComponent;
    NSString *path=@"";
    while((thisComponent=[enumer nextObject])){
        path=[path stringByAppendingPathComponent:thisComponent];
        
        if (![self fileExistsAtPath:path])continue;
        
        LSItemInfoRecord infoRec;
        LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],
							 kLSRequestBasicFlagsOnly, &infoRec);
        
        if (infoRec.flags & kLSItemInfoIsAliasFile)
            path=[[self resolveAliasAtPath:path]stringByResolvingSymlinksInPath];
        
        
		// QSLog(path);
    }
    return path;
}



- (NSString *)resolveAliasAtPath:(NSString *)aliasFullPath{
    NSString *outString = nil;
    //  Boolean success = false;
    NSURL *url;
    FSRef aliasRef;
    //  OSErr anErr = noErr;
    Boolean targetIsFolder;
    Boolean wasAliased;
    
    if (!CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:aliasFullPath], &aliasRef))
        return nil;
    
    
    if (FSResolveAliasFileWithMountFlags(&aliasRef, true, &targetIsFolder, &wasAliased,kResolveAliasFileNoUI) != noErr)
        return nil;
    
    if ((url = (NSURL *) CFURLCreateFromFSRef(kCFAllocatorDefault, &aliasRef))) {
        outString = [url path];
        CFRelease(url);
        return outString;
    }
    return nil;
}

- (NSString *)resolveAliasAtPathWithUI:(NSString *)aliasFullPath{
    NSString *outString = nil;
    //  Boolean success = false;
    NSURL *url;
    FSRef aliasRef;
    //  OSErr anErr = noErr;
    Boolean targetIsFolder;
    Boolean wasAliased;
    
    if (!CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:aliasFullPath], &aliasRef))
        return nil;
    
    
    if (FSResolveAliasFileWithMountFlags(&aliasRef, true, &targetIsFolder, &wasAliased,0) != noErr)
        return nil;
    
    if ((url = (NSURL *) CFURLCreateFromFSRef(kCFAllocatorDefault, &aliasRef))) {
        outString = [url path];
        CFRelease(url);
        return outString;
    }
    return nil;
}


- (NSArray *) itemsForPath:(NSString *)path depth:(int)depth types:(NSArray *)types{
    NSFileManager *manager=[NSFileManager defaultManager];
    // NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    BOOL isDirectory;
    if (![manager fileExistsAtPath:path isDirectory:&isDirectory]) return nil;
    
    NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
    
    //QSLog(@"Scanning %@\rDepth:%d\tTypes: [%@]",path,depth,[types componentsJoinedByString:@", "]);
    if (depth) depth--;
    if (depth==-10){
        //if (VERBOSE)QSLog(@"Scan Depth Exceeded 10 Levels with: %@",path);
        return array;
    }
    
    NSString *file;
    NSString *type;
    LSItemInfoRecord infoRec;
    OSStatus status;
    NSEnumerator *enumerator = [[manager directoryContentsAtPath:path] objectEnumerator];
    while ((file = [enumerator nextObject])){
        file=[path stringByAppendingPathComponent:file];
        type=[self typeOfFile:file];
        
        status=LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:file],
                                    kLSRequestBasicFlagsOnly, &infoRec);
        
        if (infoRec.flags & kLSItemInfoIsAliasFile){
            NSString *aliasFile=[self resolveAliasAtPath:file];
            if (aliasFile && [manager fileExistsAtPath:aliasFile]){
                file=aliasFile;
                LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:file], kLSRequestBasicFlagsOnly, &infoRec);
            }
        }
        
        
        if (![manager fileExistsAtPath:file isDirectory:&isDirectory]) continue;
        if ([manager isVisible:file]){
            if ((!types) || [types containsObject:type]){
                [array addObject:file];
            }
        }
        if (depth && isDirectory && !(infoRec.flags & kLSItemInfoIsPackage))
            [array addObjectsFromArray:[self itemsForPath:file depth:depth types:types]];
    }
    //   QSLog(@"%@",array);
    return array;
}

- (BOOL)touchPath:(NSString *)path{
	return [self changeFileAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate]
							   atPath:path];
	
}

- (NSDate *)bulkPath:(NSString *)path wasModifiedAfter:(NSDate *)date depth:(int)depth{
	if (depth) depth--;
	UKDirectoryEnumerator *enumerator = [[UKDirectoryEnumerator alloc]initWithPath:path];
   	NSDate *fileDate;
	NSDate *newDate=nil;
	NSString *child;
    [enumerator setDesiredInfo:kFSCatInfoContentMod | kFSCatInfoNodeFlags];
	while ((child = [enumerator nextObjectFullPath])){
		fileDate=[enumerator fileModificationDate];
		if ([date compare:fileDate]==NSOrderedAscending && [date compare:[NSDate date]]==NSOrderedAscending){	
			newDate=fileDate;
			break;
		}
		if(depth && [enumerator isDirectory]){
			static LSItemInfoRecord info;
			//OSStatus err = 
				LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:child], kLSRequestBasicFlagsOnly, &info);
			if (info.flags & kLSItemInfoIsPackage){
				//QSLog(@"skipping %@",child);
				continue;
			}
			if ((fileDate=[self bulkPath:child wasModifiedAfter:date depth:depth--])){
				//QSLog(@"date of %@ %@ %@ %d",date,fileDate,child,[enumerator isDirectory]);
				newDate=fileDate;
				break;
			}
		}
	}
	[enumerator release];
	
	return newDate;
}


- (NSDate *)path:(NSString *)path wasModifiedAfter:(NSDate *)date depth:(int)depth{
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    BOOL isDirectory;
    if (![self fileExistsAtPath:path isDirectory:&isDirectory]) return nil;
    
    if (depth) depth--;
    
    NSString *file;
    NSDate *moddate=[[self fileAttributesAtPath:path traverseLink:NO]fileModificationDate];
	
	if ([date compare:moddate]==NSOrderedAscending && [moddate timeIntervalSinceNow]<0){
		return moddate;
	}
    if (isDirectory){
        NSEnumerator *enumerator = [[self directoryContentsAtPath:path] objectEnumerator];
        while ((file = [enumerator nextObject])){
            file=[path stringByAppendingPathComponent:file];
            if (![self fileExistsAtPath:file isDirectory:&isDirectory]) continue;
            
            if (depth && isDirectory && ![workspace isFilePackageAtPath:file]){
				NSAutoreleasePool *pool=[[NSAutoreleasePool alloc]init];
				moddate=[self path:file wasModifiedAfter:date depth:depth--];
				[moddate retain];
				[pool release];
				[moddate autorelease];
                if (moddate)
					return moddate;
            }
        }
    }
    
    return nil;
}

- (NSDate *) modifiedDate:(NSString *)path depth:(int)depth{
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    BOOL isDirectory;
    if (![self fileExistsAtPath:path isDirectory:&isDirectory]) return nil;
    
    if (depth) depth--;
    
    NSString *file;
    NSDate *moddate=[self pastOnlyModifiedDate:path];
    //NSDictionary *fattrs;
    if ([moddate timeIntervalSinceNow]>0)
        moddate=[NSDate distantPast];
    if (isDirectory){
        NSEnumerator *enumerator = [[self directoryContentsAtPath:path] objectEnumerator];
        while ((file = [enumerator nextObject])){
            file=[path stringByAppendingPathComponent:file];
            if (![self fileExistsAtPath:file isDirectory:&isDirectory]) continue;
            
            if (depth && isDirectory && ![workspace isFilePackageAtPath:file]){
                // moddate=[moddate laterDate:[self pastOnlyModifiedDate:file]];
                moddate=[moddate laterDate:[self modifiedDate:file depth:depth]];
            }
        }
    }
    
    return moddate;
}



- (NSDate *)pastOnlyModifiedDate:(NSString *)path{
    NSDate *moddate=[[self fileAttributesAtPath:path traverseLink:NO]fileModificationDate];
    if ([moddate timeIntervalSinceNow]>0){
        //QSLog(@"File has future date: %@\r%@",path,[moddate description]);
        moddate=[NSDate distantPast];
    }
    return moddate;
}

@end


@implementation NSFileManager (BLTRExtensions)

- (BOOL)createDirectoriesForPath:(NSString *)path{
    //  QSLog(@"creating folder: (%@)",path);
    if (![path length]) return NO;
    if (![self fileExistsAtPath:[path stringByDeletingLastPathComponent] isDirectory:nil])
        [self createDirectoriesForPath:[path stringByDeletingLastPathComponent]];
    
    return [self createDirectoryAtPath:path attributes:nil];
}
- (int)defaultDragOperationForMovingPaths:(NSArray *)sources toDestination:(NSString *)destination{
	
    NSDictionary *dAttr=[self fileAttributesAtPath:destination traverseLink:NO];
    int i;
    for (i=0;i<[sources count];i++){
		if ([[sources objectAtIndex:0] isEqualToString:destination]) return NSDragOperationNone;
        NSDictionary *sAttr=[self fileAttributesAtPath:[sources objectAtIndex:0] traverseLink:NO];
        
        if (![[sAttr objectForKey:NSFileSystemNumber] isEqualTo: [dAttr objectForKey:NSFileSystemNumber]])
            return NSDragOperationCopy;
    }
    
    return NSDragOperationMove;
    
}   

- (BOOL)filesExistAtPaths:(NSArray *)paths{
    
    NSString *thisFile;
    for(thisFile in paths)
        if (![self fileExistsAtPath:thisFile])return NO;
    return YES;
}

- (NSDictionary *)conflictsForFiles:(NSArray *)files inDestination:(NSString *)destination{
	NSMutableDictionary *conflicts=[NSMutableDictionary dictionaryWithCapacity:0];
	
	NSFileManager *manager=[NSFileManager defaultManager];    
	NSString *file;
	NSString *destinationPath;
	
	for(file in files){
		destinationPath=[destination stringByAppendingPathComponent:[file lastPathComponent]];
		//file=[destination stringByAppendingPathComponent:[file lastPathComponent]];
		if ([manager fileExistsAtPath:destinationPath])
			[conflicts setObject:destinationPath forKey:file];
	}
	if (![conflicts count])
		return nil;
	return conflicts;
}
@end