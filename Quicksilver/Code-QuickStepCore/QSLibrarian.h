

#import <Foundation/Foundation.h>
#import "QSCatalogEntry.h"

#define kCustomCatalogID @"QSCatalogCustom"

extern float QSMinScore;

@class QSBasicObject;
@class QSObject;
@class QSActions;
@class QSAction;
@class QSTask;
@class QSTaskController;

@class QSLibrarian;
extern QSLibrarian *QSLib; // Shared Instance

@interface QSLibrarian : NSObject {
	QSCatalogEntry *catalog; //Root Catalog Entry

	NSMutableDictionary *enabledPresetsDictionary;
	NSMutableSet *defaultSearchSet;
	NSMutableSet *omittedIDs;
	QSTask *scanTask;
	QSTaskController *activityController;

	NSMutableDictionary *catalogArrays; // Arrays for each leaf catalog entry (Entry)
	NSMutableDictionary *typeArrays; // Type arrays (Type / Entry)

	NSArray *defaultSearchArrays; // (Entry)
	NSMutableDictionary *appSearchArrays; //Default Arrays for a given application (AppName / Entry)

	NSMutableDictionary *shelfArrays; //Arrays for User Shelves

	NSMutableArray *actionObjects;
	NSMutableDictionary *actionIdentifiers;

	NSMutableDictionary *objectSources;
	NSMutableDictionary *entriesBySource;
	NSMutableDictionary *entriesByID;

	NSMutableArray *invalidIndexes;
	int scannerCount;
}

+ (id)sharedInstance;
+ (void)removeIndexes;

- (void)loadDefaultCatalog;
- (id)init;
- (void)assignCustomAbbreviationForItem:(QSObject *)item;
//- (void)saveCatalogArrays;
- (void)registerPresets:(NSArray *)newPresets inBundle:(NSBundle *)bundle scan:(BOOL)scan;
//- (void)loadCatalog;
- (void)dealloc;
- (void)writeCatalog:(id)sender;
//- (NSArray *)entriesForSource:(NSString *)source;
- (void)reloadSource:(NSNotification *)notif;
- (void)reloadEntrySources:(NSNotification *)notif;
- (void)reloadIDDictionary:(NSNotification *)notif;
- (void)reloadSets:(NSNotification *)notif;
- (QSCatalogEntry *)firstEntryContainingObject:(QSObject *)object;
- (void)loadShelfArrays;
- (BOOL)loadCatalogArrays;
//- (BOOL)loadIndexesForEntries:(NSArray *)theEntries;
- (void)recalculateTypeArraysForItem:(QSCatalogEntry *)entry;
- (NSArray *)arrayForType:(NSString *)string;
- (NSDictionary *)typeArraysFromArray:(NSArray *)array;
- (void)loadMissingIndexes;
- (void)savePasteboardHistory;
- (void)saveShelf:(NSString *)key;
- (void)scanCatalogIgnoringIndexes:(BOOL)force;
- (void)startThreadedScan;
- (void)startThreadedAndForcedScan;
- (IBAction)forceScanCatalog:(id)sender;
- (IBAction)scanCatalog:(id)sender;
- (void)scanCatalogWithDelay:(id)sender;
- (BOOL)itemIsOmitted:(QSBasicObject *)item;
- (void)setItem:(QSBasicObject *)item isOmitted:(BOOL)omit;
- (float) estimatedTimeForSearchInSet:(id)set;
- (NSMutableArray *)scoreTest:(id)sender;
- (NSMutableArray *)scoredArrayForString:(NSString *)string;
- (NSMutableArray *)scoredArrayForString:(NSString *)string inNamedSet:(NSString *)setName;
- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(id)set;
- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(NSArray *)set mnemonicsOnly:(BOOL)mnemonicsOnly;
//- (NSMutableArray *)scoredArrayForString:(NSString *)searchString inSet:(NSArray *)set mnemonicsOnly:(BOOL)mnemonicsOnly;
- (NSMutableArray *)shelfNamed:(NSString *)shelfName;
//- (void)registerActions:(id)actionObject;
//- (void)loadActionsForObject:(id)actionObject;
- (QSCatalogEntry *)catalogCustom;
- (void)enableEntries;
- (QSCatalogEntry *)catalog ;
- (void)setCatalog:(QSCatalogEntry *)newCatalog ;
- (NSMutableSet *)defaultSearchSet ;
- (void)setDefaultSearchSet:(NSMutableSet *)newDefaultSearchSet ;
- (NSMutableDictionary *)appSearchArrays ;
- (void)setAppSearchArrays:(NSMutableDictionary *)newAppSearchArrays ;
- (NSMutableDictionary *)catalogArrays ;
- (void)setCatalogArrays:(NSMutableDictionary *)newCatalogArrays ;
- (NSMutableDictionary *)typeArrays ;
- (void)setTypeArrays:(NSMutableDictionary *)newTypeArrays ;
- (NSMutableDictionary *)shelfArrays ;
- (void)setShelfArrays:(NSMutableDictionary *)newShelfArrays ;
- (NSNumber *)presetIsEnabled:(QSCatalogEntry *)preset;
- (void)setPreset:(QSCatalogEntry *)preset isEnabled:(BOOL)flag;
- (QSCatalogEntry *)entryForID:(NSString *)theID;
- (void)pruneInvalidChildren:(id)sender;
- (void)loadCatalogInfo;
- (void)initCatalog;
- (QSTask *)scanTask;
- (void)setScanTask:(QSTask *)value;

@end
