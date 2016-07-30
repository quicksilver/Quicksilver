//
//  QSTargetPickerPanel.m
//  Quicksilver
//
//  Created by Patrick Robertson on 20/01/2013.
//
//

#import "QSTargetPickerPanel.h"

@implementation QSTargetPickerPanel

@synthesize searchObjView;

-(void)awakeFromNib {
    
    QSUserDefinedProxyTargetPicker *wc = [self windowController];
    // don't observe notifications meant for the main interface
    [wc ignoreInterfaceNotifications];
    
    QSObjectCell *theCell = [searchObjView cell];
    [theCell setCellRadiusFactor:2000];
    [theCell setHighlightColor:[NSColor colorWithDeviceRed:228.0f/255.0f green:228.0f/255.0f blue:228.0f/255.0f alpha:1.0]];
    [theCell setTextColor:[NSColor blackColor]];
    [theCell setShowDetails:NO];
    [self setHasShadow:NO];
    [theCell setFont:[NSFont systemFontOfSize:16.0]];
    
    [self setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSlightShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.1], @"duration", nil]];
    [self setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.2], @"duration", nil, [NSNumber numberWithDouble:0.25], @"brightnessB", @"QSStandardBrightBlending", @"brightnessFn", nil] forKey:kQSWindowCancelEffect];
    // populate and set up search
    [searchObjView setDropMode:QSSelectDropMode];
    [searchObjView setAllowText:NO];
    [searchObjView setSearchMode:QSSearchModeAll];
    [searchObjView setObjectValue:[wc representedObject]];
}

- (void)resignKeyWindow
{
    [self orderOut:nil];
}

@end
