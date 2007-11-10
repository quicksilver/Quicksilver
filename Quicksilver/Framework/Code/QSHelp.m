//
//  QSHelp.m
//  Quicksilver
//
//  Created by Alcor on 2/27/05.

//

#import "QSHelp.h"
#define uHelpRoot @"http://docs.blacktree.com/"
void QSShowHelpPage(NSString *page){
	if (!page) return;
	NSWorkspace *ws=[NSWorkspace sharedWorkspace];
	NSString *url=[uHelpRoot stringByAppendingString:page];
	[ws openURL:[NSURL URLWithString:url]];
}