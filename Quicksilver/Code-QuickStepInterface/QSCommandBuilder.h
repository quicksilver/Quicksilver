

#import <AppKit/AppKit.h>
#import "QSInterfaceController.h"
#import "QSObjectView.h"

@interface QSCommandBuilder : QSInterfaceController {
  IBOutlet id		iFrame;
	QSCommand *representedCommand;
}
- (QSCommand *)representedCommand;
- (void)setRepresentedCommand:(QSCommand *)aRepresentedCommand;


- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
@end
