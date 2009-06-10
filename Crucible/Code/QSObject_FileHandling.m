

#import "QSObject_FileHandling.h"
#import "QSObject_Pasteboard.h"
#import "QSParser.h"
#import "QSComputerSource.h"
#import "QSResourceManager.h"
#import "QSLibrarian.h"
#import "QSTypes.h"

#import "NSImage_BLTRExtensions.h"
#import "NSGeometry_BLTRExtensions.h"

#import "QSPreferenceKeys.h"
#import "NDResourceFork.h"
#import "QSCatalogEntry.h"
#import "NDAlias.h"
#import "NDAlias+QSMods.h"
#import "QSUTI.h"
#import "QSExecutor.h"
#import "QSMacros.h"
#import "QSAction.h"

#import "QSObject_PropertyList.h"

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "NSImage+QuickLook.h"
#import "QSLocalization.h"

NSString *identifierForPaths(NSArray *paths) {
    if ([paths count] == 1)
        return [[paths lastObject] stringByResolvingSymlinksInPath];
    return [paths componentsJoinedByString:@" "];
}

@implementation QSBasicObject (FileHandling)

- (NSString *)singleFilePath {
    return [self objectForType:QSFilePathType];
}

- (NSString *)validSingleFilePath {
    NSString *path = [self objectForType:QSFilePathType];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
		return path;
	return nil;
}

- (NSArray *)validPaths {return [self validPathsResolvingAliases:NO];}

- (NSArray *)validPathsResolvingAliases:(BOOL)resolve {
    NSArray *paths = [self arrayForType:QSFilePathType];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exists = [manager filesExistAtPaths:paths];
    if (exists)
        return paths;
    
    if ([paths count] == 1) {
        NSString *aliasFile = [self objectForType:QSAliasFilePathType];
        if ([manager fileExistsAtPath:aliasFile]) {
            if (VERBOSE)
                QSLog(@"Using original alias file:%@", aliasFile);
            return [NSArray arrayWithObject:aliasFile];
        }
    } 
    return nil;
}

- (int) fileCount {
    return [[self arrayForType:QSFilePathType] count];
}

@end


@implementation QSObject (FileHandling)

+ (QSObject *)fileObjectWithPath:(NSString *)path {
    if (![path length]) return nil;
	//QSLog(@"Path %@", path);
    path = [[path stringByStandardizingPath] stringByResolvingSymlinksInPath];
	
	//QSLog(@"Path %@", path);
	
	// ***warning * should this only resolve simlinks of ancestors?
    
    if ([[path pathExtension] isEqualToString:@"silver"])
		return [QSObject objectWithDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    
    QSObject *newObject = [QSObject objectWithIdentifier:path];  
    if (!newObject) {
		//	QSLog(@"creating for %@", path);
		newObject = [[[QSObject alloc] initWithArray:[NSArray arrayWithObject:path]]autorelease];
    }
    NSString *type = [[NSFileManager defaultManager] typeOfFile:path];
    if ([clippingTypes containsObject:type])
		[newObject performSelectorOnMainThread:@selector(addContentsOfClipping:) withObject:path waitUntilDone:YES];
	return newObject;
}

+ (QSObject *)fileObjectWithArray:(NSArray *)paths {
    QSObject *newObject = [QSObject objectWithIdentifier:identifierForPaths(paths)];
    //  QSLog(@"object:%@", newObject);
    if (!newObject) {
        if ([paths count] >1)
            newObject = [[[QSObject alloc] initWithArray:paths] autorelease];
        else if ([paths count] == 0)
            return nil;
        else
            newObject = [QSObject fileObjectWithPath:[paths lastObject]];
    }    
    return newObject;
}

+ (NSArray *)fileObjectsWithPathArray:(NSArray *)pathArray {
    NSMutableArray *fileObjectArray = [NSMutableArray arrayWithCapacity:1];
	id object;
    for (id loopItem in pathArray) {
		if ((object = [QSObject fileObjectWithPath:loopItem]))
			[fileObjectArray addObject:object];
	}
    return fileObjectArray;
}

+ (NSMutableArray *)fileObjectsWithURLArray:(NSArray *)pathArray {
    NSMutableArray *fileObjectArray = [NSMutableArray arrayWithCapacity:1];
    for (id loopItem in pathArray) {
        //QSLog(@"path %@", [[pathArray objectAtIndex:i] path]);
        [fileObjectArray addObject:[QSObject fileObjectWithPath:[loopItem path]]];
        
    }
    return fileObjectArray;
}


- (id)initWithArray:(NSArray *)paths { //**this function could create dups
    if ((self = [self init])) {
        NSString *thisIdentifier = identifierForPaths(paths);
		
        if ([paths count] == 1) {
			NSString *path = [paths lastObject];
            [[self dataDictionary] setObject:path forKey:QSFilePathType];  
			NSString *uti = QSUTIOfFile(path);
			id handler = nil;
            if (![uti hasPrefix:@"dyn."]) handler = [QSReg instanceForKey:uti inTable:@"QSFileObjectCreationHandlers"];
			//QSLog(@"handler %@ %@", uti, handler);
			if (handler)
				return [handler initFileObject:self ofType:uti];
			
        } else {
			[[self dataDictionary] setObject:paths forKey:QSFilePathType];
		}
		
        [QSObject registerObject:self withIdentifier:thisIdentifier];
        [self setPrimaryType:QSFilePathType];
        [self getNameFromFiles];
    }
    return self;
}

- (BOOL)isApplication {
    NSString *path = [self singleFilePath];
    
    LSItemInfoRecord infoRec;
    LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
    
    return (infoRec.flags & kLSItemInfoIsApplication);
    //  return ([self isFolder] && ([[path pathExtension] isEqualToString:@"app"] || [[NSArray arrayWithObjects:@"'APPL'", nil] containsObject: NSHFSTypeOfFile(path)]));
    
}

- (BOOL)isFolder {
    BOOL isDirectory;
    NSString *path = [self singleFilePath];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:path isDirectory:&isDirectory])
        return isDirectory;
    return NO;
}

- (NSString *)localizedPrefPaneKind {
	static NSString *prefPaneKindString = nil;
	if (!prefPaneKindString)
		prefPaneKindString = [[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.systempreferences"]]
                               localizedStringForKey:@"PREF_PANE" value:@" Preferences" table:nil] retain];
	return prefPaneKindString;
}

- (NSString *)descriptiveNameForPackage:(NSString *)path withKindSuffix:(BOOL)includeKind {
    //NSBundle *bundle = nil;
    CFBundleRef bundleRef = CFBundleCreate(kCFAllocatorDefault, (CFURLRef) [NSURL fileURLWithPath:path]);
    NSString *bundleName = (NSString *)CFBundleGetValueForInfoDictionaryKey(bundleRef, kCFBundleNameKey);
    [[bundleName retain] autorelease];
    CFRelease(bundleRef);
    
    NSString *kind = nil;
    
    if (includeKind) {
        if (![[path pathExtension] caseInsensitiveCompare:@"prefPane"]) {
            kind = QSIsLocalized ? [self localizedPrefPaneKind] : @"Preference Pane";
        } else {
            LSCopyKindStringForURL((CFURLRef) [NSURL fileURLWithPath:path], (CFStringRef *)&kind);  
            [kind autorelease];
        }
        if (bundleName && [kind length])
            return [NSString stringWithFormat:@"%@ %@", bundleName, kind]; 	
    }
    return bundleName;
}

- (void)getNameFromFiles {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *newName = nil;
    NSString *newLabel = nil;
    NSString *path = [self objectForType:QSFilePathType];
    
    LSItemInfoRecord infoRec;
    LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path], kLSRequestBasicFlagsOnly, &infoRec);
    
    if (infoRec.flags & kLSItemInfoIsPackage) {
        newLabel = [self descriptiveNameForPackage:path withKindSuffix:!(infoRec.flags & kLSItemInfoIsApplication)];
        if ([newLabel isEqualToString:newName])
            newLabel = nil;
    }
    
    if (!newName) {
        newName = [path lastPathComponent];
        //   if (infoRec.flags & kLSItemInfoExtensionIsHidden) newName = [newName stringByDeletingPathExtension];
    }
    if (!newLabel && ![self label]) {
        newLabel = [manager displayNameAtPath:path];
        if ([newName isEqualToString:newLabel])
            newLabel = nil;
    }
    if ([path isEqualToString:@"/"])
        newLabel = [manager displayNameAtPath:path];
    [self setName:newName];  
    [self setLabel:newLabel];  
    
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

- (NSString *)singleFileType {
	return [[NSFileManager defaultManager] typeOfFile:[self singleFilePath]];
}

- (NSString *)filesType {
    BOOL appsOnly = YES;
    BOOL foldersOnly = YES;
    BOOL filesOnly = YES;
    
    NSString *kind = nil;
    NSArray *paths = [self arrayForType:QSFilePathType];
    
    for (id loopItem in paths) {
        NSString *thisPath = [loopItem stringByStandardizingPath];
        NSString *type = [[NSFileManager defaultManager] typeOfFile:thisPath];
        
        //QSLog(@"type %@", type);
        if ([type isEqualToString:@"'fold'"]) {
            filesOnly = NO;
            appsOnly = NO;
        } else if ([type isEqualToString:@"app"] || [type isEqualToString:@"'APPL'"]) {
            foldersOnly = NO;
            filesOnly = NO;
        } else {
            appsOnly = NO;
            foldersOnly = NO;
			
			if (!kind) {
				kind = [self kindOfFile:thisPath];
			} else if (![kind isEqualToString:[self kindOfFile:thisPath]]) {
				kind = @"";
			}
        }
    }
    
	if (appsOnly) return @"Applications";
    if (foldersOnly) return @"Folders";
    if (filesOnly) {
		if ([kind length]) return [NSString stringWithFormat:@"[%@] ", kind];
		return @"Files";
	} 	
	return @"Items";
}

- (NSString *)kindOfFile:(NSString *)path {
	if (!path) return nil;
	NSString *kind;
	OSStatus err = LSCopyKindStringForURL((CFURLRef) [NSURL fileURLWithPath:path] , (CFStringRef *)&kind);
	if (!err) return [kind autorelease];
	return nil;
}

- (QSObject *)fileObjectByMergingWith:(QSObject *)mergeObject {
    // NSArray *moreFiles = [[mergeObject dataDictionary] objectForKey:QSFilePathType;
    return nil;
    
}

@end

