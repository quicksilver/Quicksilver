//
//  QSFileTemplateManager.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 12/20/05.

//

#import "QSFileTemplateManager.h"

@implementation QSFileTemplateManager
- (QSObject *)instantiateTemplate:(QSObject *)dObject inDirectory:(QSObject *)iObject{
	NSString *template=[dObject singleFilePath];
	NSString *destination=[iObject singleFilePath];
	destination=[[destination stringByAppendingPathComponent:@"untitled"]stringByAppendingPathExtension:
		[template pathExtension]];
	destination=[destination firstUnusedFilePath];
	
	NSFileManager *fm=[NSFileManager defaultManager];
		[fm copyPath:template toPath:destination handler:nil];
	
	return [QSObject fileObjectWithPath:destination];
}


- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	return [self templateObjects];
}

- (NSArray *)templateObjects{
	NSMutableArray *array=[NSMutableArray array];
	NSFileManager *fm=[NSFileManager defaultManager];
	NSString *path=QSApplicationSupportSubPath(@"Templates",NO);
	
	foreach(subpath, [fm directoryContentsAtPath:path]){
		if ([subpath hasPrefix:@"."])continue;
		subpath=[path stringByAppendingPathComponent:subpath];
		[array addObject:[self templateFromFile:subpath]];	
	}
	return array;
}
- (QSObject *)templateFromFile:(NSString *)path{
	QSObject *fileObject=[QSObject fileObjectWithPath:path];
	[fileObject setLabel:[[path lastPathComponent]stringByDeletingPathExtension]];

	NSString *kind;
	LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:path],(CFStringRef *)&kind);
	[kind autorelease];
		[fileObject setDetails:kind];
	return fileObject;
}
@end
