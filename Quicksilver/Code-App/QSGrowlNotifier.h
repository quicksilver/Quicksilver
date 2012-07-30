//
//  QSGrowlNotifier.h
//  QSGrowlNotifier
//
//  Created by Nicholas Jitkoff on 7/12/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//

// If compiler complains that GrowlApplicaionBrid.h is not found
// then download latest Growl source code and compile.
#import <Growl/GrowlApplicationBridge.h>

@interface QSGrowlNotifier : NSObject <GrowlApplicationBridgeDelegate>
{
}
@end

