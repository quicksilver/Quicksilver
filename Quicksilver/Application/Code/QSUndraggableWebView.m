//
//  QSUndraggableWebView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 1/2/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSUndraggableWebView.h"


@implementation QSUndraggableWebView

- (BOOL)mouseDownCanMoveWindow{
	return NO;	
}
@end
