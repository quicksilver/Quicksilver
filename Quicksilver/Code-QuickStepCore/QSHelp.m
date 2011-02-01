//
// QSHelp.m
// Quicksilver
//
// Created by Alcor on 2/27/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSHelp.h"
void QSShowHelpPage(NSString *page) {
	if (page)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[kHelpURL stringByAppendingString:page]]];
}
