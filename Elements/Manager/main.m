//
//  main.m
//  AlchemyTool
//
//  Copyright Blacktree 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <Blocks/Blocks.h>
int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    [pool release];

    return NSApplicationMain(argc,  (const char **) argv);
}
