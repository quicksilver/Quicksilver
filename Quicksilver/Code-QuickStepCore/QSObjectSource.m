#import "QSObjectSource.h"
#import "QSObject.h"

#import "QSObject_FileHandling.h"
#import "NSWorkspace_BLTRExtensions.h"
#import "QSObject_URLHandling.h"
#import "QSResourceManager.h"
#import "QSNotifications.h"
#import "QSCatalogEntry.h"

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
- (QSObject *)recreateObjectOfType:(NSString *)aType withIdentifier:(NSString *)anIdentifier {return nil;}
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

- (void)updateCurrentEntryModificationDate {
	[currentEntry setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
}

- (NSMutableDictionary *)currentEntry {
	return [[self selection] info];
}

- (QSCatalogEntry *)selection { return selection;  }
- (void)setSelection:(QSCatalogEntry *)newSelection {
	if(newSelection != selection){
		[selection release];
		selection = [newSelection retain];
	}
}

- (NSView *)settingsView { return settingsView;  }
- (void)setSettingsView:(NSView *)newSettingsView {
	[settingsView release];
	settingsView = [newSettingsView retain];
}

@end
