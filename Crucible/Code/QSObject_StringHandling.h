//
//  QSObject_StringHandling.h
//  Quicksilver
//
//  Created by Alcor on 8/5/04.

//

#import <Cocoa/Cocoa.h>
#import <QSCrucible/QSObject.h>

@interface QSObject (StringHandling)
+ (id)objectWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;
- (void)sniffString;
- (NSString *)stringValue;
@end