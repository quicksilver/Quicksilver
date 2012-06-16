
#import <Foundation/Foundation.h>

#import "VDKQueue.h"

@interface QSVoyeur : VDKQueue <VDKQueueDelegate> {
}

+ (id)sharedInstance;
//- (void)setDelegate:(id)delegate;
@end
