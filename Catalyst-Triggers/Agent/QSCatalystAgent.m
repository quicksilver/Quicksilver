//
//  QSCatalystAgent.m
//  QSCatalyst
//
//  Created by Nicholas Jitkoff on 1/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "QSCatalystAgent.h"
#import "QSTriggerCenter.h"

@implementation QSCatalystAgent
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  NSBundle *prefPaneBundle = [NSBundle bundleWithPath:[[[[[NSBundle mainBundle] bundlePath] 
                                stringByDeletingLastPathComponent] // Resources
                               stringByDeletingLastPathComponent] // Contents
                              stringByDeletingLastPathComponent]]; // Catalyst.prefPane
  
  [prefPaneBundle load];
  
  
  [QSTriggerCenter sharedInstance];
}

@end
