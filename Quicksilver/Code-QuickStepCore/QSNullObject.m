//
// QSNullObject.m
// Quicksilver
//
// Created by Alcor on 7/29/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSNullObject.h"

@implementation QSNullObject
@end

@implementation QSBasicObject (NullObject)
+(QSBasicObject *)nullObject {
	return [[[QSNullObject alloc] init] autorelease];
}

@end
