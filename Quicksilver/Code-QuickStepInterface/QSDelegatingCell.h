//
//  QSDelegatingCell.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 2/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSDelegatingCell : NSTextFieldCell {
	NSObject *delegate;
	id userInfo;
}
- (NSObject *)delegate;
- (void)setDelegate:(NSObject *)newDelegate;
- (id)userInfo;
- (void)setUserInfo:(id)newUserInfo;
@end

@interface NSObject (QSDelegatingCellProto)
- (void)drawCell:(NSCell *)cell withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end
