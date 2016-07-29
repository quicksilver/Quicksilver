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
- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry {return [QSResourceManager imageNamed:@"CatalogGroup"];}
- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry { return nil;  }
@end
