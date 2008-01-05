//
//  QSCatalystPref.m
//  QSCatalyst
//
//  Created by Nicholas Jitkoff on 1/5/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

#import "QSCatalystPref.h"


@implementation QSCatalystPref

- (void) mainViewDidLoad {
  NSString *agent = [[NSBundle bundleForClass:[self class]] pathForResource:@"Catalyst Agent" ofType:@"app"];
  agent = [[NSBundle bundleWithPath:agent] executablePath];
  NSLog(@"agent %@", agent);

  NSTask *task = [NSTask launchedTaskWithLaunchPath:agent arguments:[NSArray array]];
}

@end
