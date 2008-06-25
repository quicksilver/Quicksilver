//
//  main.m
//  Quicksilver
//
//  Created by Alcor on Sun Jun 29 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
    if(DEBUG_MEMORY) {
        setenv("MallocStackLogging", "1", 1);
        setenv("MallocStackLoggingNoCompact", "1", 1);
    }
	return NSApplicationMain(argc, argv);
}
