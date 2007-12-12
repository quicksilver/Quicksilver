//
// QSGroupObjectSource.m
// Quicksilver
//
// Created by Alcor on 4/5/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSGroupObjectSource.h"

@implementation QSGroupObjectSource
- (BOOL)isVisibleSource {return YES;}
- (NSImage *)iconForEntry:(NSDictionary *)dict {return [NSImage imageNamed:@"CatalogGroup"];}
- (NSArray *)objectsForEntry:(NSDictionary *)dict { return nil;  }
@end
