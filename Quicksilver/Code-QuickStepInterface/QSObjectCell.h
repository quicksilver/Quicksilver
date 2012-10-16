#import <Foundation/Foundation.h>

@class QSObject;
@interface QSObjectCell : NSButtonCell <NSTextAttachmentCell> {
	BOOL selected;
	NSTextAttachment *attachment;
	BOOL showDetails;
	BOOL autosize;
	NSFont *nameFont;
	NSFont *detailsFont;
    CGFloat cellRadiusFactor;
	NSColor *textColor;
	NSColor *highlightColor;
	NSSize iconSize;
	NSSize padding;
 //   NSString *abbreviationString;
	NSDictionary *nameAttributes;
	NSDictionary *detailsAttributes;
    NSDictionary *rankedNameAttributes;
	NSTextView *fieldEditor;
}

- (NSDictionary *)typeImageDictionary;
- (BOOL)hasBadge;

- (BOOL)showDetails;
- (void)setShowDetails:(BOOL)flag;
- (NSFont *)nameFont;
- (void)setNameFont:(NSFont *)newNameFont;
- (NSFont *)detailsFont;
- (void)setDetailsFont:(NSFont *)newDetailsFont;
// (cell height / cellRadiusFactor) will become the radius for rounded corners
- (CGFloat)cellRadiusFactor;
- (void)setCellRadiusFactor:(CGFloat)newRadius;
- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)newTextColor;
- (NSColor *)highlightColor;
- (void)setHighlightColor:(NSColor *)aHighlightColor;
- (NSMenu *)menuForObject:(id)object;
- (NSSize)iconSize;
- (void)setIconSize:(NSSize)anIconSize;
//- (BOOL)objectIsInCollection:(QSObject *)thisObject;
- (void)drawTextForObject:(QSObject *)drawObject withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawObjectImage:(QSObject *)drawObject inRect:(NSRect)drawingRect cellFrame:(NSRect)cellFrame controlView:(NSView *)controlView flipped:(BOOL)flipped opacity:(CGFloat)opacity;
- (void)drawIconForObject:(QSObject *)object withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)buildStylesForFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end
