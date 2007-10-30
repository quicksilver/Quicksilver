

#import "QSAppWindowController.h"

#define BUTTON_SPREAD 24
#define BUTTON_HEIGHT 26
#define BUTTON_PADDING 3

NSRect frameForButton(int i,int count,NSRect frameRect){
    return NSMakeRect(BUTTON_PADDING,BUTTON_PADDING+(count-i-1)*BUTTON_SPREAD,frameRect.size.width-BUTTON_PADDING*2,BUTTON_HEIGHT);
    int row=(i)/2;
    int col=(i)%2;
    int buttonWidth=(frameRect.size.width-BUTTON_PADDING*2)/2;
    NSRect rect=NSMakeRect(col*buttonWidth,row*BUTTON_SPREAD,(buttonWidth),BUTTON_HEIGHT);
    return NSOffsetRect(rect,BUTTON_PADDING,BUTTON_PADDING);
    if (0)
        return NSMakeRect(BUTTON_PADDING+i*128,BUTTON_PADDING,128,BUTTON_HEIGHT);
    else
        return NSMakeRect(BUTTON_PADDING,BUTTON_PADDING+(count-i-1)*BUTTON_SPREAD,frameRect.size.width-BUTTON_PADDING*2,BUTTON_HEIGHT);
}
NSRect windowFrameForButtons(int buttonCount,NSRect frame){
    NSRect newFrame=frame;
    //NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    float height=0;
    if (buttonCount) height+=(buttonCount+1)*BUTTON_SPREAD; //[buttonBox frame].size.height+30;
    newFrame.origin.y+=newFrame.size.height-height;
    newFrame.size.height=height;
    return newFrame;
    // [mainWindow makeFirstResponder:mainWindow];
    // [mainWindow setFrame:newFrame display:YES animate:NO];
}

@implementation QSAppWindowController

+ (id)sharedAppWindowController
{
    static QSAppWindowController *_sharedAppWindowController = nil;

    if (!_sharedAppWindowController){
        _sharedAppWindowController = [[QSAppWindowController allocWithZone:[self zone]] init];

    }
    //QSLog(@"edit: %@", _sharedEditorController);
    return _sharedAppWindowController;
}

- (id)init {
    self = [self initWithWindowNibName:@"QSAppWindow"];
    if (self) {
       
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
 //       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChanged:) name:NSOutlineViewSelectionDidChangeNotification object:0];
  //      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popUp:) name:NSPopUpButtonWillPopUpNotification object:0];
    }
    return self;
}

- (void)dealloc {
    //QSLog(@"DEALLOC CONTROLLER");
    [self close];
    [super dealloc];
}


- (void)windowDidLoad {
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    launchedApplications=[[workspace launchedApplications]retain];
    int appCount=[launchedApplications count];
    int tag;
    NSString* name;
    NSDictionary *app;
    NSButton *view;
    NSView *mainview=[[self window] contentView];
    NSImage *icon;
    int i;
    for (i=0;i<appCount && (app=[launchedApplications objectAtIndex:i]);i++){
        app=[launchedApplications objectAtIndex:i];
        tag=[[app objectForKey:@"NSApplicationProcessIdentifier"]intValue];
        view=[[[self window] contentView] viewWithTag:tag];

        if (!view){
            view=[[NSButton alloc]initWithFrame:frameForButton(i,appCount,[[[self window] contentView] bounds])];

            {
                [view setBezelStyle:NSRegularSquareBezelStyle];
                [view setImagePosition:NSImageLeft];
                [view setButtonType:NSMomentaryLight];
                [view setAlignment:NSLeftTextAlignment];
              
                [view setFont:[NSFont systemFontOfSize:10]];
                // Initialization code here.
                icon=[workspace iconForFile:[app objectForKey:@"NSApplicationPath"]];
                [icon setSize:NSMakeSize(16,16)];
                [view setImage:icon];
              
                [view setAutoresizingMask:NSViewWidthSizable|NSViewMaxXMargin|NSViewMinXMargin];
                [view setAction:@selector(openLink:)];
                  QSLog([view target]);
            }

            name=[app objectForKey:@"NSApplicationName"];
                [view setTitle:name];
                [mainview addSubview:view];
        }
    }
    [[self window] setFrame:windowFrameForButtons(appCount,[[self window]frame]) display:YES];
    [self showWindow:self];

}


@end
