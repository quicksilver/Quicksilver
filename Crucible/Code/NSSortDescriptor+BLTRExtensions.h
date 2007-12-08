//
//  NSSortDescriptor+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 3/27/05.

//

#import <Cocoa/Cocoa.h>


@interface NSSortDescriptor (QSConvenience)
+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)ascending;
+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)ascending selector:(SEL)selector;
+ (NSArray *)descriptorArrayWithKey:(NSString *)key ascending:(BOOL)ascending;
+ (NSArray *)descriptorArrayWithKey:(NSString *)key ascending:(BOOL)ascending selector:(SEL)selector;
@end
