//
//  NSMetadataItem+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 5/26/05.

//

#import <Cocoa/Cocoa.h>

@interface NSMetadataItem (Private)
- (id)_init:(struct __MDItem *)fp8;
@end

@interface NSMetadataItem (BLTRExtensions)
- (NSImage *)icon;
- (NSString *)displayName;
+ (NSMetadataItem *)itemWithPath:(NSString *)path;
@end
