

#import <Foundation/Foundation.h>
#import "QSCell.h"

@class QSObject;
@interface QSObjectCell : NSButtonCell <NSTextAttachmentCell>{
    BOOL selected;
    NSTextAttachment *attachment;
    BOOL showDetails;
    BOOL autosize;
    NSColor *textColor;
    NSColor *highlightColor;
    NSSize iconSize;
    NSSize padding;
 //   NSString *abbreviationString;
	NSDictionary *nameAttributes;
	NSDictionary *detailsAttributes;
	NSRect lastFrame;
}

- (NSDictionary *)typeImageDictionary;
- (BOOL)hasBadge;

- (BOOL)showDetails;
- (void)setShowDetails:(BOOL)flag;
- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)newTextColor;
- (NSColor *)highlightColor;
- (void)setHighlightColor:(NSColor *)aHighlightColor;
- (NSMenu *)menuForObject:(id)object;
- (NSSize)iconSize;
- (void)setIconSize:(NSSize)anIconSize;
//- (BOOL)objectIsInCollection:(QSObject *)thisObject;
- (void)drawTextForObject:(QSObject *)drawObject withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawObjectImage:(QSObject *)drawObject inRect:(NSRect)drawingRect cellFrame:(NSRect)cellFrame controlView:(NSView *)controlView flipped:(BOOL)flipped opacity:(float)opacity;
- (void)drawIconForObject:(QSObject *)object withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)buildStylesForFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end
