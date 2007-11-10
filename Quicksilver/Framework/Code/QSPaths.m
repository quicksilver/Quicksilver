//
//  QSPaths.m
//  Quicksilver
//
//  Created by Alcor on 3/28/05.

//

#import "QSPaths.h"

NSString *QSApplicationSupportPath;
NSString *QSApplicationSupportSubPath(NSString *subpath,BOOL createFolder){
	NSString *path=[QSApplicationSupportPath stringByAppendingPathComponent:subpath];
	NSFileManager *manager=[NSFileManager defaultManager];
	if (createFolder && ![manager fileExistsAtPath:path isDirectory:nil])
		[manager createDirectoriesForPath:path];
	return path;
}