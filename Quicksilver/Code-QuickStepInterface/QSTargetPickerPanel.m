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
    
    // configure appearance
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    QSObjectCell *theCell = [searchObjView cell];
    [theCell setCellRadiusFactor:20];
    [theCell setHighlightColor:[defaults colorForKey:@"QSAppearance1B"]];
    [theCell setTextColor:[defaults colorForKey:@"QSAppearance1T"]];
    [theCell setShowDetails:NO];
    [theCell setFont:[NSFont systemFontOfSize:16.0]];
    
    [self setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSGrowEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.2], @"duration", nil]];
    [self setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSlightShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.1], @"duration", nil]];
    [self setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.2], @"duration", nil, [NSNumber numberWithDouble:0.25], @"brightnessB", @"QSStandardBrightBlending", @"brightnessFn", nil] forKey:kQSWindowCancelEffect];
    // populate and set up search
    [searchObjView setDropMode:QSSelectDropMode];
    [searchObjView setAllowText:NO];
    [searchObjView setSearchMode:SearchFilterAll];
    [searchObjView setObjectValue:[wc representedObject]];
    
}


@end
