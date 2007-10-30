/* QSPlugInsPrefPane */

#import <Cocoa/Cocoa.h>

#import "QSPreferencePane.h"
@interface QSUpdatePrefPane : QSPreferencePane
{
    IBOutlet id plugInTable;
	NSMutableArray *plugInArray;
	IBOutlet NSButton *installButton;
}
-(IBAction)checkNow:(id)sender;
-(IBAction)install:(id)sender;
@end
