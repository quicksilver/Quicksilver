

#import <Foundation/Foundation.h>

@interface NSObject (QSOutlineViewDelegate)
- (BOOL)outlineView:(NSOutlineView *)aTableView itemIsSeparator:(id)item;
@end

@interface QSOutlineView : NSOutlineView {
	NSColor *highlightColor;
}
- (NSColor *)highlightColor;
- (void)setHighlightColor:(NSColor *)aHighlightColor;
@end
