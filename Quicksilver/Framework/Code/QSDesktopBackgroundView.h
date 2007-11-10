//
//  QSDesktopBackgroundView.h
//  Doomsday
//
//  Created by Alcor on Fri Nov 22 2002.

//

#import <AppKit/AppKit.h>

typedef enum _QSBackgroundType {
    Crop=1,
    FillScreen=2,
    Centered=3,
    Tiled=4
} QSBackgroundType;


@interface QSDesktopBackgroundView : NSView {
    NSImage *backgroundImage;
    NSColor *backgroundColor;
    QSBackgroundType backgroundType;
	int screenNumber;
}
- (void)updateWithDictionary:(NSDictionary *)backgroundDict;

- (int)screenNumber;
- (void)setScreenNumber:(int)newScreenNumber;
//
- (NSImage *)backgroundImage;
- (void)setBackgroundImage:(NSImage *)newBackgroundImage;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newBackgroundColor;

- (QSBackgroundType)backgroundType;
- (void)setBackgroundType:(QSBackgroundType)newBackgroundType;


@end
