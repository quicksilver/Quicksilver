/*
 *  ScreenSaverController.h
 *  Quicksilver
 *
 *  Created by Alcor on Fri Jul 18 2003.
 *  Copyright (c) 2003 Blacktree. All rights reserved.
 *
 */
@protocol ScreenSaverControl
- (double)screenSaverTimeRemaining;
- (void)restartForUser:fp12;
- (void)screenSaverStopNow;
- (void)screenSaverStartNow;
- (void)setScreenSaverCanRun:(char)fp12;
- (char)screenSaverCanRun;
- (char)screenSaverIsRunning;
@end

@interface ScreenSaverController:NSObject <ScreenSaverControl>
{
    NSConnection *_connection;
    id _daemonProxy;
    void *_reserved;
}
+ controller;
+ monitor;
+ daemonConnectionName;
+ daemonPath;
+ enginePath;
- init;
- (void)dealloc;
- (void)_connectionClosed:fp12;
- (char)screenSaverIsRunning;
- (char)screenSaverCanRun;
- (void)setScreenSaverCanRun:(char)fp12;
- (void)screenSaverStartNow;
- (void)screenSaverStopNow;
- (void)restartForUser:fp12;
- (double)screenSaverTimeRemaining;
@end