/* QSController */


#import <Cocoa/Cocoa.h>
#import <QSCore/QSCore.h>
#import <QSInterface/QSResizingInterfaceController.h>
#import <QSInterface/QSInterface.h>

@interface QSPrimerInterfaceController : QSResizingInterfaceController {
	//	 NSRect standardRect;
	IBOutlet QSBackgroundView *background;

	IBOutlet NSButton *executeButton;

	IBOutlet NSTextField *dSearchText;
	IBOutlet NSTextField *aSearchText;
	IBOutlet NSTextField *iSearchText;

	IBOutlet NSTextField *dSearchCount;
	IBOutlet NSTextField *aSearchCount;
	IBOutlet NSTextField *iSearchCount;

	IBOutlet NSButton *dSearchResultDisclosure;
	IBOutlet NSButton *aSearchResultDisclosure;
	IBOutlet NSButton *iSearchResultDisclosure;

	IBOutlet NSView *indirectView;
  }
@end
