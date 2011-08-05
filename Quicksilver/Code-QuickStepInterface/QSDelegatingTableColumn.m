//
// QSDelegatingTableColumn.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 5/6/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSDelegatingTableColumn.h"

@interface NSObject (QSDelegatingTableColumn)
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item;
- (NSCell *)tableView:(NSTableView *)aTableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
@end

@implementation QSDelegatingTableColumn
- (id)dataCellForRow:(NSInteger)row {
	id delegate = [[self tableView] delegate];
	NSCell *cell = nil;
	if ([[self tableView] isKindOfClass:[NSOutlineView class]]) {
		if ([delegate respondsToSelector:@selector(outlineView:dataCellForTableColumn:byItem:)]) {
			id item = [(NSOutlineView *)[self tableView] itemAtRow:row];
			cell = [delegate outlineView:(NSOutlineView *)[self tableView] dataCellForTableColumn:self byItem:item];
		}
	} else {
		if ([delegate respondsToSelector:@selector(tableView:dataCellForTableColumn:row:)]) {
			cell = [delegate tableView:[self tableView] dataCellForTableColumn:self row:row];
		}
	}
	return (cell) ? cell : [super dataCellForRow:row];
}
@end
