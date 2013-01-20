//
//  QSUserDefinedProxyTargetPicker.m
//  Quicksilver
//
//  Created by Rob McBroom on 2012/12/20.
//
//

#import "QSUserDefinedProxyTargetPicker.h"

@implementation QSUserDefinedProxyTargetPicker

@synthesize representedObject, entrySource;


- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

- (void)willHideMainWindow:(id)sender
{
    [dSelector clearObjectValue];
    [super willHideMainWindow:sender];
}

- (IBAction)executeCommand:(id)sender {
    // save the target object
//    NSLog(@"saving Target: %@", [dSelector objectValue]);
    [entrySource save];
    [self hideMainWindow:self];
}

@end
