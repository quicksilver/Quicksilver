#import "QSObjectSource.h"
#import "QSObject.h"

#import "QSObject_FileHandling.h"
#import "NSWorkspace_BLTRExtensions.h"
#import "QSObject_URLHandling.h"
#import "QSResourceManager.h"
#import "QSNotifications.h"
#import "QSCatalogEntry.h"
#import "QSCatalogEntry_Private.h"

@implementation QSObjectSource

// KVO
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"currentEntry"]) {
        keyPaths = [keyPaths setByAddingObject:@"selection"];
    }
    return keyPaths;
}

- (NSImage *)iconForEntry:(NSDictionary *)theEntry {return nil;}

- (NSString *)nameForEntry:(NSDictionary *)theEntry {return nil;}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {return nil;}

- (void)invalidateSelf {
	//  NSLog(@"invalidated %@", self);
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogSourceInvalidated object:NSStringFromClass([self class])];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
//	 NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[[theEntry objectForKey:kItemModificationDate] floatValue]];
//	  return ([specDate compare:indexDate] == NSOrderedDescending);
//	  //return NO; //Catalog Specification is more recent than index
	// ***warning  * should switch to using this!
	return NO;
}
- (void)populateFields {return;}

- (NSMutableDictionary *)currentEntry {
    return self.selection.info;
}

- (void)updateCurrentEntryModificationDate {
    self.selectedEntry.sourceSettings[kItemModificationDate] = @([NSDate timeIntervalSinceReferenceDate]);
}

- (QSCatalogEntry *)selection { return self.selectedEntry; }
- (void)setSelection:(QSCatalogEntry *)selection { self.selectedEntry = selection; }

@end
