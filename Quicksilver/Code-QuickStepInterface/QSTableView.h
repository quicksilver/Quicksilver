

#import <AppKit/AppKit.h>

@class QSTableView;
@protocol QSTableViewDelegate <NSTableViewDelegate>

@optional
- (BOOL)tableView:(QSTableView *)aTableView shouldDrawRow:(NSInteger)rowIndex inClipRect:(NSRect)clipRect;
- (BOOL)tableView:(QSTableView *)aTableView rowIsSeparator:(NSInteger)rowIndex;
- (NSMenu *)tableView:(QSTableView*)tableView menuForTableColumn:(NSTableColumn *)column row:(NSInteger)row;
- (void)tableView:(QSTableView *)tv dropEndedWithOperation:(NSDragOperation)operation;
- (void)drawSeparatorForRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect;
@end

@protocol QSTableViewDataSource <NSTableViewDataSource>

@optional
- (void)tableView:(QSTableView *)aTableView dropEndedWithOperation:(NSDragOperation)operation;
@end

@interface QSTableView : NSTableView {
	NSInteger drawingRowIsSelected;
	NSColor *highlightColor;
	id draggingDelegate;
	BOOL opaque;
	BOOL drawsBackground;
}
- (NSColor *)highlightColor;
- (void)setHighlightColor:(NSColor *)aHighlightColor;
- (id)draggingDelegate;
- (void)setDraggingDelegate:(id)aDraggingDelegate;
- (void)setOpaque:(BOOL)flag;
- (id <QSTableViewDelegate>)delegate;
- (id <QSTableViewDataSource>)dataSource;
@end

@interface NSTableView (MenuExtensions)
- (NSMenu*)menuForEvent:(NSEvent*)evt;
@end
