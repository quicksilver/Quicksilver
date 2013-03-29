//
// QSDelegatingCell.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 2/5/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSDelegatingCell.h"

@implementation QSDelegatingCell
- (id)initTextCell:(NSString *)aString {
	self = [super initTextCell:(NSString *)aString];
	if (self != nil) {
		delegate = nil;
		userInfo = nil;
	}
	return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if (delegate && [delegate respondsToSelector:@selector(drawCell:withFrame:inView:)]) {
		[delegate drawCell:self withFrame:cellFrame inView:controlView];
	} else {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

- (void)superDrawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[super drawWithFrame:cellFrame inView:controlView];
}


- (void)setTransparent:(BOOL)flag {}

- (NSObject *)delegate { return delegate; }
- (void)setDelegate:(NSObject *)newDelegate {
	if (delegate != newDelegate) {
		delegate = newDelegate;
	}
}

- (id)userInfo { return userInfo;  }
- (void)setUserInfo:(id)newUserInfo {
	if (userInfo != newUserInfo) {
		userInfo = newUserInfo;
	}
}
@end
