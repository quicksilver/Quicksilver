

#import <Foundation/Foundation.h>
@interface NSObject (QSObjectSourceInformal)
- (NSImage *)iconForEntry:(NSDictionary *)theEntry;
//- (NSString *)nameForEntry:(NSDictionary *)theEntry;
- (NSArray *)objectsForEntry:(NSDictionary *)theEntry;
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry;
- (void)populateFields;
- (NSMutableDictionary *)currentEntry;
- (void)setCurrentEntry:(NSMutableDictionary *)newCurrentEntry;
- (NSView *)settingsView;
- (void)setSettingsView:(NSView *)newSettingsView;
- (BOOL)isVisibleSource;
- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry;
@end

@class QSCatalogEntry;
@interface QSObjectSource : NSObject {
	IBOutlet NSView *settingsView;
	QSCatalogEntry *selection;
	NSMutableDictionary *currentEntry;
}
- (void)invalidateSelf;
- (NSImage *)iconForEntry:(NSDictionary *)theEntry;
//- (NSString *)nameForEntry:(NSDictionary *)theEntry;
- (NSArray *)objectsForEntry:(NSDictionary *)theEntry;
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry;
- (void)populateFields;

- (void)updateCurrentEntryModificationDate;
- (NSMutableDictionary *)currentEntry;
//- (void)setCurrentEntry:(NSMutableDictionary *)newCurrentEntry;
- (NSView *)settingsView;
- (void)setSettingsView:(NSView *)newSettingsView;

- (QSCatalogEntry *)selection;
- (void)setSelection:(QSCatalogEntry *)newSelection;

@end




