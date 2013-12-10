//
//  QSUserDefinedProxySource.h
//  Quicksilver
//
//  Created by Rob McBroom on 2012/12/04.
//
//

#import <QSCore/QSCore.h>

@class QSUserDefinedProxyTargetPicker;

@interface QSUserDefinedProxySource : QSObjectSource <QSProxyObjectProvider>
{
    IBOutlet NSTextField *synonymName;
    IBOutlet NSImageView *targetIcon;
    IBOutlet NSTextField *targetLabel;
    IBOutlet QSTargetPickerPanel *targetPickerWindow;
    QSUserDefinedProxyTargetPicker *targetPickerController;
}
- (IBAction)showTargetPicker:(id)sender;
- (void)save;
@end
