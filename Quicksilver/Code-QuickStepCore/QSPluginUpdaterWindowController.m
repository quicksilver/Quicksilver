//
//  QSPluginUpdaterWindowController.m
//  Quicksilver
//
//  Created by Patrick Robertson on 26/01/2013.
//  Copyright 2013
//

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#import "QSPluginUpdaterWindowController.h"


// The height of a cell when it's closed
#define kExpandHeight 52.0
// used to pad out the web view a little bit
#define kPaddingHeight 15

@implementation QSPluginUpdaterWindowController

@synthesize pluginTableView, pluginsArray, numberOfPluginsToInstall = _numberOfPluginsToInstall ;

- (id)initWithPlugins:(NSArray *)newPluginsArray
{
    self = [super initWithWindowNibName:@"QSPluginUpdater"];
    if (self) {
        pluginsArray = newPluginsArray;
        // all plugins are checked to install by default
        _numberOfPluginsToInstall = [pluginsArray count];
        pluginsToInstall = nil;
    }
    return self;
}

-(void)windowDidLoad {
    // set the window height to its initial height (all changes boxes are closed)
    [self setWindowHeight:0 animate:NO];
    [installButton setTitle:NSLocalizedString(@"Install Selected", @"Title of the button used for installing the selected plugins in the plugin updater")];
}

-(void)setWindowHeight:(CGFloat)aHeight animate:(BOOL)animate {
    NSRect frame = [[self window] frame];
    CGFloat originy = frame.origin.y;
    NSRect screenRect = [[[self window] screen] frame];

    // Values for aHeight: -ive indicates shrinkage, +ive indicates expand. 0 indicates use initial height
    if (aHeight == 0) {
        // 111 is the 'extra' height of the window
        aHeight = [pluginsArray count]*kExpandHeight+111;
    } else {
        originy -= aHeight;
        aHeight = frame.size.height + aHeight;
    }
    NSRect newWindowRect = NSMakeRect(frame.origin.x, originy, frame.size.width,aHeight);

    [[self window] setFrame:NSIntersectionRect(newWindowRect, screenRect) display:YES animate:animate];
}

- (void)dealloc {
    pluginsArray = nil;
    pluginsToInstall = nil;
}

- (void)setNumberOfPluginsToInstall:(NSUInteger)numberOfPluginsToInstall {
    [self willChangeValueForKey:@"numberOfPluginsToInstall"];
    _numberOfPluginsToInstall = numberOfPluginsToInstall;
    [self didChangeValueForKey:@"numberOfPluginsToInstall"];
}

- (NSUInteger)numberOfPluginsToInstall {
    return _numberOfPluginsToInstall;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [pluginsArray count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:@"PluginColumn"]) {
        QSPluginUpdateTableCellView *cellView = [tableView makeViewWithIdentifier:@"PluginsView" owner:self];
        // set up the plugin view and load the html
        [cellView setOptions:[pluginsArray objectAtIndex:row]];
        return cellView;
    }
    // checkbox column. Nothing to setup
    return [tableView makeViewWithIdentifier:@"Checkbox" owner:self];
}

- (NSArray *)showModal {
    [NSApp runModalForWindow:[self window]];
    // return an immutable representation
    return [pluginsToInstall copy];
}

-(IBAction)cancel:(id)sender {
    [self close];
    [NSApp stopModal];
}

-(IBAction)install:(id)sender {
    [self close];
    if (self.numberOfPluginsToInstall > 0) {
        pluginsToInstall = [NSMutableArray arrayWithCapacity:self.numberOfPluginsToInstall];
        // generate an array of plugin IDs to install
        [pluginsArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            if ([obj objectForKey:@"shouldInstall"] == nil || [[obj objectForKey:@"shouldInstall"] integerValue] == NSOnState) {
                QSPlugIn *outdatedPlugin = [obj objectForKey:@"plugin"];
                NSString *pluginToUpdate = nil;
                if ([outdatedPlugin isObsolete]) {
                    QSPlugInManager *pm = [QSPlugInManager sharedInstance];
                    pluginToUpdate = [[pm obsoletePlugIns] objectForKey:[outdatedPlugin identifier]];
                } else {
                    pluginToUpdate = [outdatedPlugin identifier];
                }
                if (pluginToUpdate != nil) {
                    [pluginsToInstall addObject:pluginToUpdate];
                }
            }
        }];
    }
    [NSApp stopModal];
}

/* The height of the row is based on whether or not the HTML changes view is showing.
 The value is stored in the plugins dictionary in pluginsArray (and set in -[QSPluginUpdateTableCellView updateHeight])
 */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    NSNumber *height = [[pluginsArray objectAtIndex:row] objectForKey:@"cellHeight"];
    if (height == nil) {
        return 50;
    }
    return [height doubleValue];
}

// Calls the NSTableView equivalent, converting a given cell view into a its row number in the table
-(void)noteHeightOfRowChanged:(QSPluginUpdateTableCellView *)cell {
    [pluginTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[pluginTableView rowForView:cell]]];
}

// setter for adding details to a given plugin's dict (in pluginsArray).
// Used to set the 'cellHeight' key
-(void)setPluginView:(QSPluginUpdateTableCellView *)view details:(id)details forKey:(NSString *)key {
    NSMutableDictionary *pluginDict = [pluginsArray objectAtIndex:[pluginTableView rowForView:view]];
    [pluginDict setObject:details forKey:key];
}

-(IBAction)toggleInstallPlugin:(NSButton *)sender {
    NSInteger row = [pluginTableView rowForView:sender];
    [[pluginsArray objectAtIndex:row] setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"shouldInstall"];
    [self setNumberOfPluginsToInstall:self.numberOfPluginsToInstall + ([sender state] == NSOffState ? -1 : 1)];
    
    // disable the install button if no plugins are checked to install
    if (self.numberOfPluginsToInstall == 0) {
        [installButton setTitle:NSLocalizedString(@"Skip Updates", @"Title of the button for 'skipping' plugin updates")];
    } else {
        [installButton setTitle:NSLocalizedString(@"Install Selected", @"Title of the button used for installing the selected plugins in the plugin updater")];
    }
}

@end

@implementation QSPluginUpdateTableCellView

@synthesize webView, pluginDetails, installedDetails;

- (void)setOptions:(NSDictionary *)options {
    QSPlugIn *thisPlugin = [options objectForKey:@"plugin"];

    _changesAreShowing = NO;
    [webView setHidden:!_changesAreShowing];
    [webView setAlphaValue:_changesAreShowing ? 1 : 0];
    if ([thisPlugin isObsolete]) {
        [changesTitle setHidden:YES];
        [toggleChangesButton setHidden:YES];
    } else {
        [webView setFrameLoadDelegate:self];
        [[[webView mainFrame] frameView] setAllowsScrolling:NO];
        [webView setDrawsBackground:NO];
        
        static NSString *css = nil;
        if (css == nil) {
            // CSS for making the web view blend in. !!-Not valid HTML (no <head>,<body>)
            css = @"<style>body {margin:0px;padding:0px;font-size:11px;font-family:\"lucida grande\";}ul {-webkit-padding-start:16px;list-style-type:square;margin:0px}</style>";
        }
        WebFrame *wf = self.webView.mainFrame;
        [wf loadHTMLString:[NSString stringWithFormat:@"%@%@",css,[thisPlugin releaseNotes]] baseURL:nil];
    }
    NSString *name = [options objectForKey:@"name"];
    if (!name) {
        name = [NSString stringWithFormat:@"%@ %@",[thisPlugin name],[thisPlugin latestVersion]];
    }
    self.installedDetails.stringValue = [NSString stringWithFormat:NSLocalizedString(@"(Installed: %@)", @"details of the installed plugin version (that is being updated"), [thisPlugin installedVersion]];
    [iconView setImage:[thisPlugin icon]];
    self.pluginDetails.stringValue = name;
    
}

// gets the height of the HTML in the webFrame, once it has loaded, to set the required height of the cell
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)webFrame {
    //get the rect for the rendered frame
    NSRect webFrameRect = [[[webFrame frameView] documentView] frame];
    webViewHeight = NSHeight(webFrameRect)+kPaddingHeight;
}


-(IBAction)toggleChanges:(id)sender {
    _changesAreShowing = !_changesAreShowing;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [wc setWindowHeight:ceil(webViewHeight)*(_changesAreShowing ? 1 : -1) animate:YES];
        [[self.webView animator] setHidden:!_changesAreShowing];
        [[self.webView animator] setAlphaValue:_changesAreShowing ? 1 : 0];
        if (_changesAreShowing) {
            [self updateHeight];
        }
    } completionHandler:^{
        if (!_changesAreShowing) {
            [self updateHeight];
        }
    }];

}

-(void)updateHeight {
    CGFloat height = _changesAreShowing ? webViewHeight + kExpandHeight : kExpandHeight;
    [wc setPluginView:self details:[NSNumber numberWithFloat:height] forKey:@"cellHeight"];
    [wc noteHeightOfRowChanged:self];
    
}


@end