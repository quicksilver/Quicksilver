//
//  QSHelpersPrefPane.h
//  Quicksilver
//
//  Created by Alcor on 10/3/04.

//

#import <Cocoa/Cocoa.h>


#import <PreferencePanes/PreferencePanes.h>
#import "QSPreferencePane.h"

@interface QSHelpersPrefPane : QSPreferencePane{
	NSMutableArray *helperInfo;
	IBOutlet NSTableView *helperTable;
}
- (NSMutableArray *)helperInfo;
- (void)setHelperInfo:(NSMutableArray *)aHelperInfo;
- (void)reloadHelpersList:(id)sender;
@end
