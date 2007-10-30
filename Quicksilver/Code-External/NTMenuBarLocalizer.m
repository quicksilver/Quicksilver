//
//  NTMenuBarLocalizer.m
//  Path Finder
//
//  Created by Steve Gehrman on Sun Nov 17 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTMenuBarLocalizer.h"
#import "NTLocalizedString.h"

@implementation NTMenuBarLocalizer

+ (void)recursiveLocalizer:(NSMenu*)menu
{
    NSArray* itemArray = [menu itemArray];
    int i, cnt = [itemArray count];
    BOOL restore = NO;

    // don't update menu until everything is added
    if ([menu menuChangedMessagesEnabled])
    {
        restore = YES;
        [menu setMenuChangedMessagesEnabled:NO];
    }

    // localize the menu
    [menu setTitle:[NTLocalizedString localize:[menu title] table:@"menuBar"]];

    for (i=0;i<cnt;i++)
    {
        NSMenuItem* item = [itemArray objectAtIndex:i];
        
        // localize the menuItem
        [item setTitle:[NTLocalizedString localize:[item title] table:@"menuBar"]];
        
        if ([item submenu])
            [self recursiveLocalizer:[item submenu]];
    }

    if (restore)
        [menu setMenuChangedMessagesEnabled:YES];
}

+ (void)localizeMenu:(NSMenu*)menu;
{
    // don't localize if english, save time at startup, programmer must add a CURRENT_LANGUAGE string to the .strings file for each language
    if (![[NTLocalizedString localize:@"CURRENT_LANGUAGE"] isEqualToString:@"English"])
        [self recursiveLocalizer:menu];
}

@end
