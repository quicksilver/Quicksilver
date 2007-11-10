//
//  QSDefaultsManager.m
//  Quicksilver
//
//  Created by Alcor on 3/31/05.

//

#import "QSDefaultsManager.h"


@implementation QSDefaultsManager
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle{
	//QSLog(@"New defaults: %@",[[info allKeys]componentsJoinedByString:@", "]);
	[[NSUserDefaults standardUserDefaults]registerDefaults:info];
	return YES;
}
@end