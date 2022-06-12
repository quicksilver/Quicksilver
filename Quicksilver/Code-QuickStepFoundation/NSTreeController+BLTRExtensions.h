//
//  NSTreeController+BLTRExtensions.h
//  QuickStep Foundation
//
//  Created by Patrick Robertson on 12/06/2022.
//

#import <AppKit/AppKit.h>


#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTreeController (NSTreeController_BLTRExtensions)

- (NSIndexPath*)indexPathOfObject:(id)anObject;
- (NSIndexPath*)indexPathOfObject:(id)anObject inNodes:(NSArray*)nodes;
@end

NS_ASSUME_NONNULL_END
