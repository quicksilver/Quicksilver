//
//  QSHandledObjectHandler.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 9/24/05.

//

#import <Cocoa/Cocoa.h>
@class QSObject;
@interface QSHandledObjectHandler : NSObject
- (QSObject *)handledObjectObjectWithInfo:(NSDictionary *)dict;
@end
