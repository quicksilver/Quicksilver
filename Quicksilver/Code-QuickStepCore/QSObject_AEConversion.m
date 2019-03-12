//
// QSObject_AEConversion.m
// Quicksilver
//
// Created by Alcor on 3/20/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSObject_AEConversion.h"
#import "QSRegistry.h"

#define kQSAEDescriptorType @"aedesc"

@implementation QSObject (AEConversion)

+ (QSObject *)objectWithAEDescriptor:(NSAppleEventDescriptor *)desc {
	return nil;
}

- (NSAppleEventDescriptor *)AEDescriptor {
	id handler = [self handler];
    if( handler && [handler respondsToSelector:@selector(AEDescriptorForObject:)] )
        return [handler performSelector:@selector(AEDescriptorForObject:) withObject:self];
	return nil;
}

@end
