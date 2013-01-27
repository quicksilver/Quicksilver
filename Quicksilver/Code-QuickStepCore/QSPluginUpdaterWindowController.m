//
//  QSPluginUpdaterWindowController.m
//  Quicksilver
//
//  Created by Patrick Robertson on 26/01/2013.
//
//

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#import "QSPluginUpdaterWindowController.h"


// The height of a cell when it's closed
#define kExpandHeight 45.0
// used to pad out the web view a little bit
#define kPaddingFactor 1.1

@interface QSPluginUpdaterWindowController ()

@end

@implementation QSPluginUpdaterWindowController

@synthesize pluginTableView, pluginsArray;

- (id)initWithPlugins:(NSArray *)newPluginsArray
{
    self = [super initWithWindowNibName:@"QSPluginUpdater"];
    if (self) {
        pluginsArray = [newPluginsArray retain];
        // all plugins are checked to install by default
        numberOfPluginsToInstall = [pluginsArray count];
        pluginsToInstall = nil;
    }
    return self;
}

-(void)windowDidLoad {
    [self setWindowHeight:0 animate:NO];
}

-(void)setWindowHeight:(CGFloat)aHeight animate:(BOOL)animate {
    NSRect frame = [[self window] frame];
    CGFloat originy = frame.origin.y;

    // Valus for aHeight: -ive indicates shrinkage, +ive indicates expand. 0 indicates use initial height
    if (aHeight == 0) {
        // 100 is the 'extra' height of the window
        aHeight = [pluginsArray count]*kExpandHeight+100;
    } else {
        originy -= aHeight;
        aHeight = frame.size.height + aHeight;
    }

    [[self window] setFrame:NSMakeRect(frame.origin.x, originy, frame.size.width,aHeight) display:YES animate:animate];
}

- (void)dealloc {
    [pluginsArray release]; pluginsArray = nil;
    [pluginsToInstall release]; pluginsToInstall = nil;
    [super dealloc];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [pluginsArray count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:@"PluginColumn"]) {
        QSPluginUpdateTableCellView *cellView = [tableView makeViewWithIdentifier:@"PluginsView" owner:self];
        [cellView setOptions:[pluginsArray objectAtIndex:row]];
        [[cellView webView] setAlphaValue:[cellView changesAreShowing]];
        [[cellView webView] setDrawsBackground:NO];
        [cellView.webView setFrameLoadDelegate:cellView];
        [[[cellView.webView mainFrame] frameView] setAllowsScrolling:NO];
        return cellView;

    }
    return [tableView makeViewWithIdentifier:@"Checkbox" owner:self];
}

- (NSArray *)showModal {
    [NSApp runModalForWindow:[self window]];
    // return an immutable representation
    return [[pluginsToInstall copy] autorelease];
}

-(IBAction)cancel:(id)sender {
    [self close];
    [NSApp stopModal];
}


-(IBAction)install:(id)sender {
    [self close];
    pluginsToInstall = [[NSMutableArray arrayWithCapacity:numberOfPluginsToInstall] retain];
    [pluginsArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if ([obj objectForKey:@"shouldInstall"] == nil || [[obj objectForKey:@"shouldInstall"] integerValue] == NSOnState) {
            [pluginsToInstall addObject:[obj objectForKey:@"identifier"]];
        }
    }];
    [NSApp stopModal];
}

// We make the "group rows" have the standard height, while all other image rows have a larger height
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    NSNumber *height = [[pluginsArray objectAtIndex:row] objectForKey:@"cellHeight"];
    if (height == nil) {
        return 45;
    }
    return [height doubleValue];
}

-(void)noteHeightOfRowChanged:(QSPluginUpdateTableCellView *)cell {
    [pluginTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[pluginTableView rowForView:cell]]];
}


-(void)setPluginView:(QSPluginUpdateTableCellView *)view details:(id)details forKey:(NSString *)key {
    NSMutableDictionary *pluginDict = [pluginsArray objectAtIndex:[pluginTableView rowForView:view]];
    [pluginDict setObject:details forKey:key];
}

-(IBAction)toggleInstallPlugin:(NSButton *)sender {
    NSInteger row = [pluginTableView rowForView:sender];
    [[pluginsArray objectAtIndex:row] setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"shouldInstall"];
    numberOfPluginsToInstall = numberOfPluginsToInstall + ([sender state] == NSOffState ? -1 : 1);
    [installButton setEnabled:numberOfPluginsToInstall > 0];

}

@end

@implementation QSPluginUpdateTableCellView

@synthesize webView, pluginDetails;

- (void)setOptions:(NSDictionary *)options {
//    for (NSControl *v in @[changesTitle, triangleDisclosure, pluginDetails]) {

//        [v setFont:[NSSystemF]
//    }
    static NSString *css = nil;
    if (css == nil) {
        css = [@"<style>body {margin:0px;padding:0px;font-size:11px;font-family:\"lucida grande\";}ul {-webkit-padding-start:16px;list-style-type:square;margin:0px}</style>" retain];
    }
    NSString *name;
    if ([options objectForKey:@"installedVersion"] && [options objectForKey:@"latestVersion"]) {
        name = [NSString stringWithFormat:@"%@ (%@ → %@)",[options objectForKey:@"name"], [options objectForKey:@"installedVersion"],[options objectForKey:@"latestVersion"]];
    } else {
        name = [options objectForKey:@"name"];
    }
        
    self.pluginDetails.stringValue = name;
    WebFrame *wf = self.webView.mainFrame;
    
    [wf loadHTMLString:[NSString stringWithFormat:@"%@%@",css,[options objectForKey:@"releaseNotes"]] baseURL:nil];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)webFrame {
    //get the rect for the rendered frame
    NSRect webFrameRect = [[[webFrame frameView] documentView] frame];
    //get the rect of the current webview
    NSRect webViewRect = [self.webView frame];
    
    //calculate the new frame
    NSRect newWebViewRect = NSMakeRect(webViewRect.origin.x,
                                       webViewRect.origin.y - NSHeight(webFrameRect),
                                       NSWidth(webViewRect),
                                       NSHeight(webFrameRect)*kPaddingFactor);
    //set the frame
    [self.webView setFrame:newWebViewRect];
    webViewHeight = NSHeight(newWebViewRect)*kPaddingFactor;
}
 

-(BOOL)changesAreShowing {
    return _changesAreShowing;
}

-(IBAction)toggleChanges:(id)sender {
    _changesAreShowing = !_changesAreShowing;
    [self.webView setAlphaValue:1.0];
    [[self.webView animator] setAlphaValue:_changesAreShowing ? 1 : 0];
    [wc setWindowHeight:webViewHeight*(_changesAreShowing ? 1 : -1) animate:YES];
    [self updateHeight];
}

-(void)updateHeight {
    if (_changesAreShowing) {
        [wc setPluginView:self details:[NSNumber numberWithFloat:webViewHeight + kExpandHeight] forKey:@"cellHeight"];
    } else {
        [wc setPluginView:self details:[NSNumber numberWithFloat:kExpandHeight] forKey:@"cellHeight"];

    }
    [wc noteHeightOfRowChanged:self];
    
}


@end