/* QSActionsPrefPane */

@interface QSActionsPrefPane : QSPreferencePane{
	
	NSMutableArray *actions;
	NSMutableArray *groups;
	int displayMode;
	IBOutlet NSArrayController *groupController;
	IBOutlet NSArrayController *actionController;
	//NSArray *currentGroup;
}
- (IBAction)selectType:(id)sender;

- (NSMutableArray *)actions;
- (void)setActions:(NSMutableArray *)newActions;
- (NSMutableArray *)groups;
- (void)setGroups:(NSMutableArray *)newGroups;
- (int)displayMode;
- (void)setDisplayMode:(int)newDisplayMode;
- (IBAction)setFilterText:(id)sender;
//- (NSDictionary *)currentGroup;
//- (void)setCurrentGroup:(NSDictionary *)newCurrentGroup;
- (void)updateGroups;
- (void)selectCategories:(NSArray *)categories;
@end
