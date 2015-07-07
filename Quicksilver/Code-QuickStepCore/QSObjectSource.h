

#import <Foundation/Foundation.h>


@protocol QSObjectSource

/**
 * Return the icon appropriate for the entry
 *
 * @param theEntry The entry whose icon should be returned.
 *
 * @return The image to use as icon.
 */
- (NSImage *)iconForEntry:(NSDictionary *)theEntry;

/**
 * Return the objects scanned by the source
 *
 * @param theEntry The entry to be scanned.
 *
 * @return An array of QSObjects.
 */
- (NSArray *)objectsForEntry:(NSDictionary *)theEntry;

/**
 * Check if an entry has changed before scanning
 *
 * @param indexDate The last indexation date.
 * @param theEntry  The entry currently being scanned.
 *
 * @return YES if the entries' contents should be refreshed, NO otherwise.
 */
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry;

@optional

/**
 * Can the entry's contents be stored to disk
 *
 * @param theEntry The entry currently being considered for indexation.
 *
 * @return YES if saving the current contents of the entry makes sense (to speed up QS startup)
 *          NO if the entry's contents are something transient.
 */
- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry;

/**
 * Informs the source that the entry was enabled
 */
- (void)enableEntry:(QSCatalogEntry *)entry;
/**
 *  Informs the source that the entry was disabled
 */
- (void)disableEntry:(QSCatalogEntry *)entry;

/**
 * Can this object source be created by the user.
 *
 * @return YES to show the source in the Catalog's pref pane Add button
 */
- (BOOL)isVisibleSource;

/**
 * Does the source stores its settings globally.
 *
 * @note Right now it's only used by the Process source, because it stores settings
 *       in the pref file.
 *
 * @return YES, if you care.
 */
- (BOOL)usesGlobalSettings;

@end

@class QSCatalogEntry;

@interface QSObjectSource : NSObject <QSObjectSource> {
    /* The following is deprecated because it duplicates -selection.
     * But it can't be removed because dyld will notice and plugins will fail to load
     */
    NSMutableDictionary *currentEntry QS_DEPRECATED;
}

- (void)invalidateSelf;

- (void)updateCurrentEntryModificationDate;

/* Catalog settings pane-related methods */
/* XXX: This would feel better in some NSViewController subclass ;-) */

- (void)populateFields;

@property (retain) QSCatalogEntry *selectedEntry;
@property (retain) IBOutlet NSView *settingsView;

// Please use -selectedEntry instead of those
// The rational being that between -currentEntry, -selection and direct Ivar
// everything can go wrong.
@property (retain) NSMutableDictionary *currentEntry QS_DEPRECATED;
@property (retain) QSCatalogEntry *selection QS_DEPRECATED;

@end




