//
//  NDAlias+QSMods.m
//  Quicksilver
//
//  Created by Alcor on Fri Mar 05 2004.
//  Copyright (c) 2004 Blacktree, Inc.. All rights reserved.
//

#import "NDAlias+QSMods.h"

@implementation NDAlias (QSMods)
- (NSString *)quickPath {
	return self.lastKnownPath;
}
@end
