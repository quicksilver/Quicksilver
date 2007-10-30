//
//  QSGlobalSelectionProvider.h
//  Quicksilver
//
//  Created by Alcor on 1/21/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"
@protocol QSGlobalSelectionProvider
- (QSObject *)currentSelectionForApplication:(NSString *)bundleID;

@end

@interface QSGlobalSelectionProvider : NSObject {
	NSTimeInterval failDate;
}

+(id)currentSelection;
@end
