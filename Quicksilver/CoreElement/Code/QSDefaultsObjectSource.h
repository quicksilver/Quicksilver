/* QSDefaultsObjectSource */


typedef enum QSDefaultsType {
    DefaultsPathEntry = 1,
    DefaultsURLEntry = 2,
    DefaultsAliasEntry = 3,
    DefaultsTextEntry = 4,
    DefaultsFileDataEntry = 5
} QSDefaultsType;

@interface QSDefaultsObjectSource : QSObjectSource
{
    IBOutlet NSTextField *bundleIDField;
    IBOutlet NSTextField *keyField;
    IBOutlet NSPopUpButton *entryTypePopUp;
}
- (void)addObjectsForKeyList:(NSArray *)keyList keyNumber:(int)index ofType:(int)type inObject:(id)thisObject toArray:(NSMutableArray *)array;

- (IBAction)setValueForSender:(id)sender;
- (NSString *)prefFileForBundle:(NSString *)bundleID;
@end
