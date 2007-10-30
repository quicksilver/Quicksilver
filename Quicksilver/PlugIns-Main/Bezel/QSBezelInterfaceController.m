#import "QSBezelInterfaceController.h"

#import <QSInterface/QSBezelBackgroundView.h>
#import <QSInterface/QSSearchObjectView.h>
#import <QSInterface/QSInterface.h>
#import <QSInterface/QSObjectCell.h>


#import <QSEffects/QSWindow.h>
@implementation QSBezelInterfaceController


- (id)init {
    return [self initWithWindowNibName:@"QSBezelInterface"];
}

- (void) windowDidLoad{
	standardRect=centerRectInRect([[self window]frame],[[NSScreen mainScreen]frame]);
	
    [super windowDidLoad];
	QSWindow *window=(QSWindow *)[self window];
	[window setLevel:kCGOverlayWindowLevel];
    [window setBackgroundColor:[NSColor clearColor]];
    
    [window setHideOffset:NSMakePoint(0,0)];
	[window setShowOffset:NSMakePoint(0,0)];
	
	//[window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExtraExtraEffect",@"transformFn",@"show",@"type",nil]];
	//[window setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSPurgeEffect",@"transformFn",@"hide",@"type",nil]];
	
//	[window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect",@"transformFn",@"show",@"type",[NSNumber numberWithFloat:0.15],@"duration",nil]];
	//	[window setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:.25],@"duration",nil]];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExplodeEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:0.2],@"duration",nil]
					   forKey:kQSWindowExecEffect];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"hide",@"type",[NSNumber numberWithFloat:0.15],@"duration",nil]
					   forKey:kQSWindowFadeEffect];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:0.333],@"duration",nil,[NSNumber numberWithFloat:0.25],@"brightnessB",@"QSStandardBrightBlending",@"brightnessFn",nil]
					   forKey:kQSWindowCancelEffect];
	
	
    [(QSBezelBackgroundView *)[[self window] contentView] setRadius:24.0];
	[(QSBezelBackgroundView *)[[self window] contentView] setGlassStyle:QSGlossUpArc];
	
	
	
    [[self window]setFrame:standardRect display:YES];
    
//    NSData *colorData=[[NSUserDefaults standardUserDefaults]dataForKey:@"QSBezelBackgroundColor"];
//   if (colorData){
//	    NSColor *color=[NSUnarchiver unarchiveObjectWithData:colorData];
//	    [(QSBezelBackgroundView *)[[self window] contentView]setColor:color];
  //  }else{
//	    [(QSBezelBackgroundView *)[[self window] contentView]setColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.85]];
//    }
    
    [[[self window] contentView] bind:@"color"
							 toObject:[NSUserDefaultsController sharedUserDefaultsController]
						  withKeyPath:@"values.QSAppearance1B"
							  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
																  forKey:@"NSValueTransformerName"]];
    
    [[self window]  bind:@"hasShadow"
				toObject:[NSUserDefaultsController sharedUserDefaultsController]
			 withKeyPath:@"values.QSBezelHasShadow"
				 options:nil];
    
	[details bind:@"textColor"
		 toObject:[NSUserDefaultsController sharedUserDefaultsController]
	  withKeyPath:@"values.QSAppearance1T"
		  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];

	[commandView bind:@"textColor"
		 toObject:[NSUserDefaultsController sharedUserDefaultsController]
	  withKeyPath:@"values.QSAppearance1T"
		  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	
		
    [[self window]setMovableByWindowBackground:NO];
    [(QSWindow *)[self window]setFastShow:YES];
	
	
    NSArray *theControls=[NSArray arrayWithObjects:dSelector,aSelector,iSelector,nil];
    foreach(theControl,theControls){
		NSCell *theCell=[theControl cell];
		[theCell setAlignment:NSCenterTextAlignment];
		[theControl setPreferredEdge:NSMinYEdge];
		[theControl setResultsPadding:NSMinY([dSelector frame])];
		[theControl setPreferredEdge:NSMinYEdge];
		[(QSWindow *)[((QSSearchObjectView *)theControl)->resultController window]setHideOffset:NSMakePoint(0,NSMinY([iSelector frame]))];
		[(QSWindow *)[((QSSearchObjectView *)theControl)->resultController window]setShowOffset:NSMakePoint(0,NSMinY([dSelector frame]))];
		
        [(QSObjectCell *)theCell setShowDetails:YES];
        [(QSObjectCell *)theCell setTextColor:[NSColor whiteColor]];
        [(QSObjectCell *)theCell setState:NSOnState];
		
		[theCell bind:@"highlightColor"
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
		  withKeyPath:@"values.QSAppearance1A"
			  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
		
		[theCell bind:@"textColor"
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
		  withKeyPath:@"values.QSAppearance1T"
			  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
     }
    
	[self contractWindow:nil];
}

- (NSSize)maxIconSize{
    return NSMakeSize(128,128);
}

- (void)showMainWindow:(id)sender{
	[[self window]setFrame:[self rectForState:[self expanded]]  display:YES];
	if ([[self window]isVisible])[[self window]pulse:self];
    [super showMainWindow:sender];
	[[[self window]contentView]setNeedsDisplay:YES];
}

- (void)expandWindow:(id)sender{ 
    if (![self expanded])
        [[self window]setFrame:[self rectForState:YES] display:YES animate:YES];
    [super expandWindow:sender];
}
- (void)contractWindow:(id)sender{
//	NSLog(@"cont");
	if ([self expanded])
        [[self window]setFrame:[self rectForState:NO] display:YES animate:YES];
	
    [super contractWindow:sender];
}


- (NSRect)rectForState:(BOOL)shouldExpand{ 
    NSRect newRect=standardRect;
    NSRect screenRect=[[NSScreen mainScreen]frame];
    if (!shouldExpand){
	//	NSLog(@"should");
        newRect.size.width-=NSMaxX([iSelector frame])-NSMaxX([aSelector frame]);
        newRect=centerRectInRect(newRect,[[NSScreen mainScreen]frame]);
    }
    newRect=centerRectInRect(newRect,screenRect);
    newRect=NSOffsetRect(newRect,0,NSHeight(screenRect)/8);
	return newRect;
}


- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect{
	return NSOffsetRect(NSInsetRect(rect,8,0),0,-21);
}


-(void)updateDetailsString{
	NSControl *firstResponder=(NSControl *)[[self window]firstResponder];
	if ([firstResponder respondsToSelector:@selector(objectValue)]){
		id object=[firstResponder objectValue];
		if ([object respondsToSelector:@selector(details)]){
			NSString *string=[object details];
			if (string){
				[details setStringValue:string];
				return;
			}
		}
	}
	[details setStringValue:@""];
}

- (void)firstResponderChanged:(NSResponder *)aResponder{
//	logRect([[self window]frame]);
	[super firstResponderChanged:aResponder];
	[self updateDetailsString];
	
}



- (void)searchObjectChanged:(NSNotification*)notif{
	[super searchObjectChanged:notif];	
	[self updateDetailsString];
}
@end
















