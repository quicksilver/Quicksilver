//
//  QSPluginUpdaterWindowController.h
//  Quicksilver
//
//  Created by Patrick Robertson on 26/01/2013.
//
//

#import <Cocoa/Cocoa.h>

@class WebView;
@class QSPluginUpdateTableCellView;

@interface QSPluginUpdaterWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet NSTableView *pluginTableView;
    IBOutlet NSButton *installButton;
    NSArray *pluginsArray;
    NSUInteger numberOfPluginsToInstall;
    NSMutableArray *pluginsToInstall;
}
@property (readonly) NSArray *pluginsArray;
@property (readonly) NSTableView *pluginTableView;

-(void)setPluginView:(QSPluginUpdateTableCellView*)view details:(id)details forKey:(id<NSCopying>)key;
-(id)initWithPlugins:(NSArray *)plugins;
-(NSArray *)showModal;
-(void)setWindowHeight:(CGFloat)aHeight animate:(BOOL)animate;
-(void)noteHeightOfRowChanged:(QSPluginUpdateTableCellView *)cell;
-(IBAction)toggleInstallPlugin:(id)sender;

@end


@interface QSPluginUpdateTableCellView : NSTableCellView {
    IBOutlet QSPluginUpdaterWindowController* wc;
    IBOutlet WebView *webView;
    IBOutlet NSTextField *changesTitle;
    IBOutlet NSButton *triangleDisclosure;
    IBOutlet NSTextField *pluginDetails;
    BOOL _changesAreShowing;
    CGFloat webViewHeight;
}

@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSTextField *pluginDetails;

-(BOOL)changesAreShowing;
-(void)setOptions:(NSDictionary *)options;

@end