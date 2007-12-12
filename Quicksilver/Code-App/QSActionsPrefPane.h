#import <Cocoa/Cocoa.h>
#import "QSPreferencePane.h"

@interface QSActionsPrefPane : QSPreferencePane {
	NSMutableArray *actions;
	NSMutableArray *groups;
	int displayMode;
	IBOutlet NSArrayController *groupController;
	IBOutlet NSArrayController *actionController;
}
- (NSMutableArray *)actions;
- (void)setActions:(NSMutableArray *)newActions;
- (NSMutableArray *)groups;
- (void)setGroups:(NSMutableArray *)newGroups;
- (int) displayMode;
- (void)setDisplayMode:(int)newDisplayMode;
- (IBAction)setFilterText:(id)sender;
- (void)updateGroups;
- (void)selectCategories:(NSArray *)categories;
@end
