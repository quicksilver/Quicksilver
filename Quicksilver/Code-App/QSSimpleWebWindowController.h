//
//  QSSimpleWebWindow.h
//  Quicksilver
//
//  Created by Alcor on 5/27/05.
//  Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSSimpleWebWindowController : NSWindowController 
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
   <NSToolbarDelegate>
#endif
{

}
- (void)openURL:(NSURL *)url;
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL;
@end
