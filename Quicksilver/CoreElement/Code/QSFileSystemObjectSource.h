

@interface QSEncapsulatedTextCell : NSTextFieldCell 

@end

@interface QSFileSystemObjectSource : QSObjectSource {
    IBOutlet NSButton *itemSkipItemSwitch;
    IBOutlet NSTextField *itemLocationField;
    IBOutlet NSButton *itemLocationChooseButton;
    IBOutlet NSButton *itemLocationShowButton;
    
    IBOutlet NSPopUpButton *itemParserPopUp;
    IBOutlet NSBox *itemOptionsView;
    IBOutlet NSView *itemFolderOptions;
    IBOutlet NSTextView *typesTextView;
    
    IBOutlet NSTextField *typesTextField;
    IBOutlet NSSlider *itemFolderDepthSlider;
    IBOutlet NSPopUpButton *typeSetsPopUp;
    
    
    IBOutlet NSPanel *typeSetsPanel;
    IBOutlet NSTableView *typeSetsTable;
    IBOutlet NSButton *addSetButton;
    IBOutlet NSButton *removeSetButton;
}
+ (NSMenu *)parserMenuForPath:(NSString *)path;
- (void)populateFields;
- (IBAction)setValueForSender:(id)sender;
- (IBAction)showFile:(id)sender;
- (IBAction)chooseFile:(id)sender;
- (BOOL)chooseFile;

- (NSString *)fullPathForSettings:(NSDictionary *)settings;
- (IBAction)editSets:(id)sender;
- (IBAction)addSet:(id)sender;
- (IBAction)removeSet:(id)sender;
- (IBAction)endContainingSheet:(id)sender;

@end



