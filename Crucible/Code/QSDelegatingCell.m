//
//  QSDelegatingCell.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 2/5/06.

//

#import "QSDelegatingCell.h"


@implementation QSDelegatingCell
- (id)initTextCell:(NSString *)aString{
	self = [super initTextCell:(NSString *)aString];
	if (self != nil) {
		delegate=nil;
		userInfo=nil;
	}
	return self;
}
//- (void)drawCell:(NSCell *)cell withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	//QSLog(@"draw with delegate %@ %@",delegate,[self objectValue]);
	if (delegate && [delegate respondsToSelector:@selector(drawCell:withFrame:inView:)]){
		[delegate drawCell:self withFrame:cellFrame inView:controlView];
	}else{
		[super drawWithFrame:cellFrame inView:controlView];	
	}
}

- (void)superDrawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[super drawWithFrame:cellFrame inView:controlView];	
}


- (void)dealloc
{
	[self setDelegate:nil];
    [self setUserInfo:nil];
    [super dealloc];
}

- (void)setTransparent:(BOOL)flag{;}

- (NSObject *)delegate { return [[delegate retain] autorelease]; }
- (void)setDelegate:(NSObject *)newDelegate
{
    if (delegate != newDelegate) {
        [delegate release];
        delegate = [newDelegate retain];
    }
}


- (id)userInfo { return [[userInfo retain] autorelease]; }
- (void)setUserInfo:(id)newUserInfo
{
    if (userInfo != newUserInfo) {
        [userInfo release];
        userInfo = [newUserInfo retain];
    }
}



@end
