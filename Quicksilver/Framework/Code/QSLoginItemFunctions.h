//
//  QSLoginItemFunctions.h
//  Quicksilver
//
//  Created by Alcor on 12/22/04.

//

#import <Cocoa/Cocoa.h>

BOOL QSItemShouldLaunchAtLogin(NSString *path);
void QSSetItemShouldLaunchAtLogin(NSString *path,BOOL launch,BOOL includeAlias);	