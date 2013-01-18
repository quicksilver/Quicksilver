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

- (void)windowDidBecomeKey:(NSNotification *)note
{
    // don't observe notifications meant for the main interface
    [self ignoreInterfaceNotifications];
    
    // configure appearance
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    QSObjectCell *theCell = [dSelector cell];
    [theCell setCellRadiusFactor:20];
    [theCell setHighlightColor:[defaults colorForKey:@"QSAppearance1B"]];
    [theCell setTextColor:[defaults colorForKey:@"QSAppearance1T"]];
    [theCell setShowDetails:NO];
    [theCell setFont:[NSFont systemFontOfSize:16.0]];
    QSWindow *window = (QSWindow *)[self window];
    [window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSGrowEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.2], @"duration", nil]];
    [window setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSlightShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.1], @"duration", nil]];
    [window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.2], @"duration", nil, [NSNumber numberWithDouble:0.25], @"brightnessB", @"QSStandardBrightBlending", @"brightnessFn", nil] forKey:kQSWindowCancelEffect];
    // populate and set up search
    [dSelector setDropMode:QSSelectDropMode];
    [dSelector setAllowText:NO];
    [dSelector setSearchMode:SearchFilterAll];
    [dSelector setObjectValue:representedObject];
}

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
