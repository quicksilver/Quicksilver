

#import <Foundation/Foundation.h>

@interface NSObject (OutlineViewSeparator)
- (BOOL)outlineView:(NSTableView *)aTableView itemIsSeparator:(id)item;
@end

@interface QSOutlineView : NSOutlineView {
	NSColor *highlightColor;
}
- (NSColor *)highlightColor;

@end
