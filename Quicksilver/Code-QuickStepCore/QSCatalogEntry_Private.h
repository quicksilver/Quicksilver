//
//  QSCatalogEntry_Private.h
//  Quicksilver
//
//  Created by Etienne on 15/09/13.
//
//

#import <QSCore/QSCore.h>

@interface QSCatalogEntry ()
/**
 * The receiver's private info dictionary
 *
 * This is considered private API (some other parts of QS access it directly).
 *
 * It contains the following keys:
 *
 * - kItemChildren - an array of QSCatalogEntry in dictionary format.
 * - @"requiresPath" - a path to a required "file-system object"
 * - @"requiresSettingsPath" - a BOOL indicating if the kItemPath in kItemSettings is required
 * - @"requiresBundle" - a required bundle identifier
 * - @"permanent"      - a BOOL indicating if the receiver can be deleted
 * - kItemSource       - the QSObjectSource identifier of the receiver
 * - kItemEnabled      - a BOOL representing the enabled state of the receiver
 * - kItemID           - the identifier for the receiver (will be assigned an UUID if missing)
 * - kItemName         - the name of the receiver (deprecated because it prevents localization)
 * - kItemIcon         - the name of the icon to use
 * - @"iconData"       - data for the icon to use
 * - kItemModificationDate - The last modification date of the receiver, as a time interval
 * - kItemSettings     - a dictionary containing source-specific keys
 *   - kItemPath       - a path to a required "file-system object"
 */
@property (readonly, retain) NSMutableDictionary *info;

@property (readonly) BOOL canBeDeleted;
@end

@interface QSCatalogEntry (OldStyleSourceSupport)
- (id)objectForKey:(NSString *)key QS_DEPRECATED_MSG("Sources now get QSCatalogEntry objects. Please use those");
@end
