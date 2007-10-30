//
//  QSTextViewer.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 7/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSTextViewer : NSWindowController
- (void)setString:(NSString *)string;
- (NSTextView *)textView;
@end

QSTextViewer * QSShowTextViewerWithString(NSString *string);
QSTextViewer * QSShowTextViewerWithFile(NSString *path);
