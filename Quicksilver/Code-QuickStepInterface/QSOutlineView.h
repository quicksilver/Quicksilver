

#import <Foundation/Foundation.h>

@class QSOutlineView;
@protocol QSOutlineViewDelegate <NSObject>
@optional
- (BOOL)outlineView:(QSOutlineView *)aTableView itemIsSeparator:(id)item;
@end

@interface QSOutlineView : NSOutlineView {
	NSColor *highlightColor;
}
- (NSColor *)highlightColor;
- (void)setHighlightColor:(NSColor *)aHighlightColor;
- (id <QSOutlineViewDelegate>)delegate;
@end
