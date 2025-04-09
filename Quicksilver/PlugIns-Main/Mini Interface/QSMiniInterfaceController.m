#import "QSMiniInterfaceController.h"

#import <IOKit/IOCFBundle.h>
#import <ApplicationServices/ApplicationServices.h>

//#import "QSMenuButton.h"

#define DIFF 18

@implementation QSMiniInterfaceController


- (id)init {
    self = [super initWithWindowNibName:@"MiniInterface"];
    if (self) {

    }
    return self;
}

- (void) windowDidLoad{
        [super windowDidLoad];
    QSWindow *window = (QSWindow *)[self window];
    [window setLevel:NSModalPanelWindowLevel];
    [window setFrameAutosaveName:@"MiniInterfaceWindow"];
    
    [[self window] setCollectionBehavior:NSWindowCollectionBehaviorTransient];
    
    [window setFrame:constrainRectToRect([[self window]frame],[[[self window]screen]visibleFrame]) display:NO];
    [window setHideOffset:NSMakePoint(150,0)];
    [window setShowOffset:NSMakePoint(-150,0)];
    
	
	[window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect",@"transformFn",@"show",@"type",[NSNumber numberWithDouble:0.15],@"duration",nil]];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExplodeEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithDouble:0.2],@"duration",nil]
							  forKey:kQSWindowExecEffect];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"hide",@"type",[NSNumber numberWithDouble:0.15],@"duration",nil]
							  forKey:kQSWindowFadeEffect];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithDouble:0.333],@"duration",nil,[NSNumber numberWithDouble:0.25],@"brightnessB",@"QSStandardBrightBlending",@"brightnessFn",nil]
							  forKey:kQSWindowCancelEffect];
    
    
    [[[self window] contentView] bind:@"color" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1B" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
    [[self window] bind:@"hasShadow" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSBezelHasShadow" options:nil];
    [commandView bind:@"textColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1T" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];

	
	
	
	[(QSCollectingSearchObjectView *)dSelector setCollectionSpace:0.0f];
	[(QSCollectingSearchObjectView *)iSelector setCollectionSpace:0.0f];
	[(QSCollectingSearchObjectView *)dSelector setCollectionEdge:NSMinXEdge];
	[(QSCollectingSearchObjectView *)iSelector setCollectionEdge:NSMinXEdge];
	
	
	
    [self contractWindow:self];
}

- (void)updateViewLocations{
    [super updateViewLocations];

 //   [[[self window]contentView]display];
}


- (void)hideMainWindow:(id)sender{

    [[self window] saveFrameUsingName:@"MiniInterfaceWindow"];
    
    [super hideMainWindow:sender];
}

- (NSSize)maxIconSize{
    return NSMakeSize(32,32);
}
- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect{
    //
    return NSOffsetRect(NSInsetRect(rect,8,0),0,-21);
    return NSMakeRect(0,[(NSView *)[window firstResponder]frame].origin.y,NSWidth(rect),0);
}


- (void)showIndirectSelector:(id)sender{
    if (![iSelector superview] && !expanded)
        [iSelector setFrame:NSOffsetRect([aSelector frame],0,-NSHeight([aSelector frame]))];
    [super showIndirectSelector:sender];
}

- (void)expandWindow:(id)sender{ 
    if (![self expanded]) {
        NSRect expandedRect=[[self window]frame];
        expandedRect.size.height+=DIFF;
        expandedRect.origin.y-=DIFF;
        [[self window]setFrame:expandedRect display:YES animate:YES];
    }
    [super expandWindow:sender];
}

- (void)contractWindow:(id)sender{
    if ([self expanded]) {
        NSRect contractedRect=[[self window]frame];
        
        contractedRect.size.height-=DIFF;
        contractedRect.origin.y+=DIFF;
        
        [[self window]setFrame:contractedRect display:YES animate:YES];
    }
    [super contractWindow:sender];
}


@end
















