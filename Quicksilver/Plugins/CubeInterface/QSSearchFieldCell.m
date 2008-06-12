//
//  QSSearchFieldCell.m
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 7/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSSearchFieldCell.h"


@implementation QSSearchFieldCell

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
  
  textObj = [super setUpFieldEditorAttributes:textObj];
  [(NSTextView*)textObj setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithDeviceWhite:1.0 alpha:1.0], NSBackgroundColorAttributeName, nil]];
  [textObj setDelegate:self];
  return textObj;
}
//- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {}
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [[NSColor colorWithDeviceWhite:1.0 alpha:0.5] setFill];
  [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] setStroke];

  NSRect rect = NSInsetRect(cellFrame, 0.5, 0.5);
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect
                                                       xRadius:NSHeight(rect)/2 yRadius:NSHeight(rect)/2];

//	NSArray *colorArray = [NSArray arrayWithObjects: [NSColor blueColor], [NSColor yellowColor], [NSColor orangeColor], nil];
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]
                                                       endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.25]] autorelease];
	[gradient drawInBezierPath: path angle: 270];
   [path stroke];
  
//  NSFrameRect(cellFrame);
  [self drawInteriorWithFrame:cellFrame inView:controlView];
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
  NSLog(@"performc");
  BOOL retval = NO;
  if (commandSelector == @selector(insertNewline:)) {
    retval = YES;
    [fieldEditor insertNewlineIgnoringFieldEditor:nil];
  }
  return retval;
}

@end
