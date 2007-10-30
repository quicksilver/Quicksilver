//
//  QSAutomatorSet.h
//  QSAutomatorSet
//
//  Created by Nicholas Jitkoff on 3/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>

@interface QSAutomatorSet : AMBundleAction 
{
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
