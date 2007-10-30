//
//  QSFileTemplateManager.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 12/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QSObject;
@interface QSFileTemplateManager : NSObject {

}
- (NSArray *)templateObjects;
- (QSObject *)templateFromFile:(NSString *)path;
@end
