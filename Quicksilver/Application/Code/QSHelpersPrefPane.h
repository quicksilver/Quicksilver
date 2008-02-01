//
//  QSHelpersPrefPane.h
//  Quicksilver
//
//  Created by Alcor on 10/3/04.

//

@interface QSHelpersPrefPane : QSPreferencePane {
	NSMutableArray *helperInfo;
	IBOutlet NSTableView *helperTable;
}
- (NSArray *)helperInfo;
- (void)setHelperInfo:(NSArray *)aHelperInfo;
- (void)reloadHelpersList:(id)sender;
@end
