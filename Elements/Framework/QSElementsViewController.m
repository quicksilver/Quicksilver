//
//  QSElementsViewController.m
//  Elements
//
//  Created by Nicholas Jitkoff on 12/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSElementsViewController.h"


@implementation QSElementsViewController

static id sharedInstance = nil;
+ (id) sharedController {
    if( sharedInstance == nil ) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id) init {
    self = [super initWithNibName:@"ElementsManager" bundle:[NSBundle bundleForClass:[self class]]];
    if( self ) {
    }
    return self;
}

- (id) registry
{
    return QSReg;
}

- (void) showWindow:(id)sender {
    [self loadView]; 
    [[[self view] window] makeKeyAndOrderFront:nil];
}

@end
