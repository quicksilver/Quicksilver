//
//  QSSimpleWebWindow.h
//  Quicksilver
//
//  Created by Alcor on 5/27/05.

//

#import <Cocoa/Cocoa.h>


@interface QSSimpleWebWindowController : NSWindowController {

}
- (void)openURL:(NSURL *)url;
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL;
@end
