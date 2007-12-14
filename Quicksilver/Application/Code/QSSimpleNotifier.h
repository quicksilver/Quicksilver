//
//  QSGrowlNotifier.h
//  QSGrowlNotifier
//
//  Created by Alcor on 7/12/04.

//

#import "QSSimpleNotifier.h"

@interface QSSilverNotifier : NSWindowController{
	NSTimer *curTimer;
	IBOutlet NSTextView *textView;
	IBOutlet NSImageView *imageView;
	
	NSString *thisTitle;
	NSString *lastTitle;
}
- (NSString *)thisTitle;
- (void)setThisTitle:(NSString *)value;

- (NSString *)lastTitle;
- (void)setLastTitle:(NSString *)value;


@end

