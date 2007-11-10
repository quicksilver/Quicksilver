//
//  QSGlobalSelectionProvider.h
//  Quicksilver
//
//  Created by Alcor on 1/21/05.

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
