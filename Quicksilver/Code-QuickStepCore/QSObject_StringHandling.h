//
//  QSObject_StringHandling.h
//  Quicksilver
//
//  Created by Alcor on 8/5/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"


@interface NSString (Trimming)
- (NSString *)trimWhitespace;
@end

@interface QSStringObjectHandler : NSObject

@end

@interface QSObject (StringHandling)
+ (id)objectWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;
- (void)sniffString;
- (NSString *)stringValue;
@end
