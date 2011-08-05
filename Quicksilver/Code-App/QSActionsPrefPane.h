#import <Cocoa/Cocoa.h>
#import "QSPreferencePane.h"

@interface QSActionsPrefPane : QSPreferencePane {
	NSMutableArray *actions;
	NSMutableArray *groups;
	NSInteger displayMode;
	IBOutlet NSArrayController *groupController;
	IBOutlet NSArrayController *actionController;
}
- (NSMutableArray *)actions;
- (void)setActions:(NSMutableArray *)newActions;
- (NSMutableArray *)groups;
- (void)setGroups:(NSMutableArray *)newGroups;
- (NSInteger) displayMode;
- (void)setDisplayMode:(NSInteger)newDisplayMode;
- (IBAction)setFilterText:(id)sender;
- (void)updateGroups;
- (void)selectCategories:(NSArray *)categories;
@end
