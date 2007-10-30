/*
 *  QSAccessibility.h
 *  Quicksilver
 *
 *  Created by Nicholas Jitkoff on 2/12/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
void QSEnableAccessibility();
//The feature called 'Enable access for assistive devices' is found in the Universal Access preference pane. It needs to be enabled in order for any GUI AppleScripts to run. I was trying to enable it from the Terminal, to insure that it was always enabled when needed. I struggled with this for a long time, and then finally found a simple solution. 
//
//To turn it on, type this in Terminal:
//sudo touch /private/var/db/.AccessibilityAPIEnabled
//To then disable it, type this:
//sudo rm /private/var/db/.AccessibilityAPIEnabled
//Thats it. If you wanted to AppleScript it, you could do something like this:
//do shell script ¬
//"touch /private/var/db/.AccessibilityAPIEnabled" password "pwd" ¬
//with administrator privileges
//[robg adds: Somewhat obviously, replace pwd with your admin user's password. Also, change touch to rm for the opposite version of the AppleScript.]