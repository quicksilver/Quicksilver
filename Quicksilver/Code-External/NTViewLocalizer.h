//
//  NTViewLocalizer.h
//  CocoaTechBase
//
//  Created by Steve Gehrman on Sun Mar 09 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTViewLocalizer : NSObject
{
	NSString* _table;
	NSBundle* _bundle;
}

+ (void)localizeWindow:(NSWindow*)window table:(NSString*)table bundle:(NSBundle*)bundle;
+ (void)localizeView:(NSView*)view table:(NSString*)table bundle:(NSBundle*)bundle;

@end
