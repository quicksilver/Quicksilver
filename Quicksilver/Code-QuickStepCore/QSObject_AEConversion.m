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
    NSMutableArray * objects = [NSMutableArray arrayWithCapacity:[desc numberOfItems]];
    
    NSArray *handlers = [[NSSet setWithArray:[[QSReg objectHandlers] allValues]] allObjects];
    
    foreach( object, objects ) {
        foreach( handler, handlers ) {
            id obj = nil;
            if ([handler respondsToSelector:@selector(objectWithAEDescriptor:)])
                obj = [handler objectWithAEDescriptor:desc];
            
            if (obj)
                [objects addObject:obj];
        }
    }

    if([objects count] == 0)
        NSLog(@"Unhandled AE conversion from descriptor %@", desc);
	return [QSObject objectByMergingObjects:objects];
}

- (NSAppleEventDescriptor *)AEDescriptor {
	id handler = [self handler];
    if( handler && [handler respondsToSelector:@selector(AEDescriptorForObject:)] )
        return [handler performSelector:@selector(AEDescriptorForObject:) withObject:self];
	return nil;
}

@end
