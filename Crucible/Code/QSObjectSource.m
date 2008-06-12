

#import "QSObjectSource.h"
#import "QSObject.h"

#import "QSObject_FileHandling.h"
#import "NSWorkspace_BLTRExtensions.h"
//#import "QSObject_ContactHandling.h"
#import "QSObject_URLHandling.h"
#import "QSResourceManager.h"
//#import "DRColorPermutator.h"
#import "QSNotifications.h"
#import "QSCatalogEntry.h"

@implementation QSObjectSource
+ (void)initialize{
	[self setKeys:[NSArray arrayWithObject:@"selection"] triggerChangeNotificationsForDependentKey:@"currentEntry"];
}
- (NSImage *) iconForEntry:(NSDictionary *)theEntry{return nil;}
- (NSString *) nameForEntry:(NSDictionary *)theEntry{return nil;}
- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{return nil;}
- (void)invalidateSelf{
	//   QSLog(@"invalidated %@",self);
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogSourceInvalidated object:NSStringFromClass([self class])];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
//	  NSDate *specDate=[NSDate dateWithTimeIntervalSinceReferenceDate:[[theEntry objectForKey:kItemModificationDate]floatValue]];
//	   return ([specDate compare:indexDate]==NSOrderedDescending);
//	   //return NO; //Catalog Specification is more recent than index
	// ***warning   * should switch to using this!    
    return NO;
}
- (void) populateFields{return;}

- (void) updateCurrentEntryModificationDate{
    [currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];	
}

- (NSMutableDictionary *)currentEntry { 
	return [[self selection]info];
}



- (QSCatalogEntry *)selection { return [[selection retain] autorelease]; }
- (void)setSelection:(QSCatalogEntry *)newSelection
{
    [selection autorelease];
    selection = [newSelection retain];
}

- (NSView *)settingsView { return [[settingsView retain] autorelease]; }
- (void)setSettingsView:(NSView *)newSettingsView {
    [settingsView release];
    settingsView = [newSettingsView retain];
}
- (BOOL)shouldScanOnMainThread { return NO; }
@end





