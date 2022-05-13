//
// QSFileTemplateManager.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 12/20/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSFileTemplateManager.h"

#import <QSCore/QSObject.h>
#import <QSCore/QSObject_FileHandling.h>

@implementation QSFileTemplateManager

- (QSObject *)instantiateTemplate:(QSObject *)dObject inDirectory:(QSObject *)iObject {
	NSString *template = [dObject singleFilePath];
	if (!template) {
		// make sure that it's actually a file template
		NSBeep();
		return nil;
	}
	NSString *destination = [iObject singleFilePath];
	destination = [[destination stringByAppendingPathComponent:@"untitled"] stringByAppendingPathExtension:
		[template pathExtension]];
	destination = [destination firstUnusedFilePath];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm copyItemAtPath:template toPath:destination error:nil];
	
	return [QSObject fileObjectWithPath:destination];
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	return [self templateObjects];
}

- (NSArray *)templateObjects {
	NSMutableArray *array = [NSMutableArray array];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = QSApplicationSupportSubPath(@"Templates", NO);
    NSArray * fmContents = [fm contentsOfDirectoryAtPath:path error:nil];
	for(__strong NSString * subpath in fmContents) {
		if ([subpath hasPrefix:@"."]) continue;
		subpath = [path stringByAppendingPathComponent:subpath];
		[array addObject:[self templateFromFile:subpath]];
	}
	return array;
}
- (QSObject *)templateFromFile:(NSString *)path {
	QSObject *fileObject = [QSObject fileObjectWithPath:path];
	
	NSURL *url = [NSURL fileURLWithPath:path];
	NSString *type = nil;
	[url getResourceValue:&type forKey:NSURLLocalizedTypeDescriptionKey error:nil];
    [fileObject setLabel:[NSString stringWithFormat:NSLocalizedString(@"%@ Template (%@)", @"Name format for the 'Make New...' action. First argument is typically one of 'Text', 'HTML', 'Python' etc."), [type localizedCapitalizedString], [[[path lastPathComponent] stringByDeletingPathExtension] localizedCapitalizedString]]];
	return fileObject;
}
@end
