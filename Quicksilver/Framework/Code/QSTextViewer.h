//
//  QSTextViewer.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 7/2/05.

//

#import <Cocoa/Cocoa.h>

@interface QSTextViewer : NSWindowController
- (void)setString:(NSString *)string;
- (NSTextView *)textView;
@end

QSTextViewer * QSShowTextViewerWithString(NSString *string);
QSTextViewer * QSShowTextViewerWithFile(NSString *path);
