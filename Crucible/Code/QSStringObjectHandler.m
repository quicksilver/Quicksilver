//
//  QSStringObjectHandler.m
//  Crucible
//
//  Created by Etienne on 08/06/09.
//  Copyright 2009 Etienne Samson. All rights reserved.
//

#import "QSStringObjectHandler.h"

@implementation QSStringObjectHandler

- (NSData *)fileRepresentationForObject:(QSObject *)object{
	return [[object stringValue]dataUsingEncoding:NSUTF8StringEncoding];
}
- (NSString *)filenameForObject:(QSObject *)object{
	NSString *name=[[[object stringValue] lines]objectAtIndex:0];
	return [name stringByAppendingPathExtension:@"txt"];
}


- (BOOL)objectHasChildren:(id <QSObject>)object{
    return YES;
}
- (void)setQuickIconForObject:(QSObject *)object{
	[object setIcon:[[NSWorkspace sharedWorkspace]iconForFileType:@"'clpt'"]];
}
- (BOOL)loadIconForObject:(QSObject *)object{
	return NO;
}
- (NSString *)identifierForObject:(id <QSObject>)object{
    return nil;
}
- (BOOL)loadChildrenForObject:(QSObject *)object{
	return NO;
}

- (NSString *)detailsOfObject:(QSObject *)object{
	return nil;
}

@end