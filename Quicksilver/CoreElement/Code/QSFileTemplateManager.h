//
//  QSFileTemplateManager.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 12/20/05.

//

#import <Cocoa/Cocoa.h>

@class QSObject;
@interface QSFileTemplateManager : NSObject {

}
- (NSArray *)templateObjects;
- (QSObject *)templateFromFile:(NSString *)path;
@end
