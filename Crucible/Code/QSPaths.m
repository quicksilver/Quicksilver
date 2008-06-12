//
//  QSPaths.m
//  Quicksilver
//
//  Created by Alcor on 3/28/05.

//

#import "QSPaths.h"

NSString *QSApplicationSupportPath( void ) {
    FSRef foundRef;
    unsigned char path[1024];
    
    FSFindFolder( kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef );
    FSRefMakePath( &foundRef, path, sizeof(path) );
    
    NSString * applicationSupportFolder;
    applicationSupportFolder = [[NSString stringWithUTF8String:(char *)path] stringByStandardizingPath];
    applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Quicksilver"];  
    
    return applicationSupportFolder;
}

NSString *QSApplicationSupportSubPath( NSString *subpath, BOOL createFolder ) {
    NSString *path = [QSApplicationSupportPath() stringByAppendingPathComponent:subpath];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ( createFolder && ![manager fileExistsAtPath:path isDirectory:NULL] )
 		[manager createDirectoriesForPath:path];
    
 	return path;
}