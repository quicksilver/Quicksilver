//
//  QSAdvancedPrefPane.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/28/06.

//

@interface QSAdvancedPrefPane : QSPreferencePane {
	IBOutlet NSTableView *prefSetsTable;
	IBOutlet NSArrayController *prefSetsController;
	
	NSMutableDictionary *currentInfo;
}
- (NSMutableDictionary *)currentInfo;
- (void)setCurrentInfo:(NSMutableDictionary *)newCurrentInfo;
@end
