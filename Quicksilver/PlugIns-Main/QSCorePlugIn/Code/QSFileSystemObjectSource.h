#import <Foundation/Foundation.h>
#import "QSObjectSource.h"

#if 0
@interface QSEncapsulatedTextCell : NSTextFieldCell @end
#endif

#define kQSWatchTarget @"watchTarget"
#define kQSWatchPaths @"watchPaths"

@interface QSFileSystemObjectSource : QSObjectSource {
	IBOutlet NSButton *itemSkipItemSwitch, *itemLocationChooseButton, *itemLocationShowButton;
	IBOutlet NSTextField *itemLocationField;
	IBOutlet NSPopUpButton *itemParserPopUp;
	IBOutlet NSBox *itemOptionsView;
	IBOutlet NSView *itemFolderOptions;
	IBOutlet NSSlider *itemFolderDepthSlider;
}
+ (NSMenu *)parserMenuForPath:(NSString *)path;
- (void)populateFields;
- (IBAction)setValueForSender:(id)sender;
- (IBAction)showFile:(id)sender;
- (IBAction)chooseFile:(id)sender;
- (BOOL)chooseFile;

- (NSString *)fullPathForSettings:(NSDictionary *)settings;
- (IBAction)endContainingSheet:(id)sender;

@end

@interface QSCatalogEntry (QSFileSystemObjectSource)

@property (nonatomic) BOOL watchTarget;
-(void)enableWatching;
-(void)disableWatching;
@property (readonly) NSString *fullWatchPath;
@end
