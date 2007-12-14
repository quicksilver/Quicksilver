//
//  NSScreen_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 12/19/04.

//

@interface NSScreen (BLTRExtensions)
-(int)screenNumber;
-(NSString *)deviceName;
+(NSScreen *)screenWithNumber:(int)number;
-(BOOL)usesOpenGLAcceleration;
@end
