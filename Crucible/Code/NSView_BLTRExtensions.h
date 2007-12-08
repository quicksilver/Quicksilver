//
//  NSView_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Sun Dec 21 2003.

//

#import <Foundation/Foundation.h>

@interface NSView (Mirroring)
-(void)flipSubviewsOnAxis:(bool)vertical;
-(BOOL)containsEvent:(NSEvent *)event;
@end
