#import "QSCatalogEntrySource.h"
#import "QSCatalogPrefPane.h"

#import "QSLibrarian.h"

#import "QSResourceManager.h"
#import "QSNotifications.h"
#import "QSObject.h"
#import "QSAction.h"
#import "QSController.h"

#import "QSRegistry.h"

#import "QSObjCMessageSource.h"

#define QSCatalogEntryPboardType @"qs.catalogentry"

#define kQSCatalogEntryShowAction @"QSCatalogEntryShowAction"
#define kQSCatalogEntryRescanAction @"QSCatalogEntryRescanAction"
#define kQSCatalogAddEntryAction @"QSCatalogAddEntryAction"

static BOOL firstCheck = NO;
static NSImage *prefsCatalogImage = nil;

@implementation QSCatalogEntrySource

+ (void)initialize {
	if (prefsCatalogImage == nil) {
		prefsCatalogImage = [[QSResourceManager imageNamed:@"prefsCatalog"] retain];
	}
}

- (id)init {
	if((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateSelf) name:QSCatalogStructureChanged object:nil];
	}
	return self;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	if (!firstCheck) {
		firstCheck = YES;
		return NO;
	}
	return YES;
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry { return NO; }

- (NSImage *)iconForEntry:(NSDictionary *)dict { return [QSResourceManager imageNamed:@"prefsCatalog"]; }

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	return [self objectsFromCatalogEntries:[[[QSLibrarian sharedInstance] catalog] deepChildrenWithGroups:YES leaves:YES disabled:YES]];
}

// FIXME: What is this meant for?
- (void)showCatalog:(id)sender { NSLog(@"show"); }

- (NSArray *)objectsFromCatalogEntries:(NSArray *)catalogObjects {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];

	QSObject *newObject;
	QSCatalogEntry *thisEntry;
	NSString *name;
	NSString *theID;
	for(thisEntry in catalogObjects) {
		name = [thisEntry name];
		theID = [thisEntry identifier];
		if (!theID || [theID isEqualToString:@"QSSeparator"])
			continue;
		if ([name isEqualToString:@"QSCATALOGROOT"])
			name = @"Quicksilver Catalog";
		else
			name = [NSString stringWithFormat:@"%@ (Catalog) ", name];
		newObject = [QSObject objectWithName:name];
		[newObject setObject:theID forType:QSCatalogEntryPboardType];
		[newObject setPrimaryType:QSCatalogEntryPboardType];
		[newObject setIdentifier:theID];
		[objects addObject:newObject];
	}
	return objects;
}

// Object Handler Methods

- (BOOL)loadIconForObject:(QSObject *)object {
	[object setIcon:[[[QSLibrarian sharedInstance] entryForID:[object objectForType:QSCatalogEntryPboardType]] icon]];
	return YES;
}

- (BOOL)objectHasChildren:(QSObject *)object { return YES; }

- (BOOL)objectHasValidChildren:(QSObject *)object { return YES; }

- (BOOL)loadChildrenForObject:(QSObject *)object {
	NSArray *children = [self childrenForObject:object];
	if (children) {
		[object setChildren:children];
		return YES;
	} else
		return NO;
}

- (NSString *)identifierForObject:(QSObject *)object { return [object objectForType:QSCatalogEntryPboardType]; }

- (NSArray *)childrenForObject:(QSBasicObject *)object {
	QSCatalogEntry *theEntry = [[QSLibrarian sharedInstance] entryForID:[object objectForType:QSCatalogEntryPboardType]];

	if ([theEntry isGroup])
		return [self objectsFromCatalogEntries:[theEntry contents]];
	else
		return [theEntry contentsScanIfNeeded:YES];
}

// Action Provider Methods
- (NSArray *)types { return [NSArray arrayWithObject:QSCatalogEntryPboardType]; }

- (NSArray *)actions {
	QSAction *action = [QSAction actionWithIdentifier:kQSCatalogEntryShowAction];
	[action setIcon:[QSResourceManager imageNamed:@"prefsCatalog"]];
	[action setProvider:self];
	[action setAction:@selector(show:)];
	QSAction *action2 = [QSAction actionWithIdentifier:kQSCatalogEntryRescanAction];
	[action2 setIcon:[QSResourceManager imageNamed:@"prefsCatalog"]];
	[action2 setProvider:self];
	[action2 setAction:@selector(rescan:)];
    QSAction *action3 = [QSAction actionWithIdentifier:kQSCatalogAddEntryAction];
    [action3 setIcon:[QSResourceManager imageNamed:@"prefsCatalog"]];
    [action3 setProvider:self];
    [action3 setAction:@selector(addCatalogEntry:)];
    return [NSArray arrayWithObjects:action, action2, action3, nil];
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
    if ([dObject count] == 1) {
        return [NSArray arrayWithObjects:kQSCatalogEntryShowAction, kQSCatalogEntryRescanAction, kQSCatalogAddEntryAction, nil];
    }
    return nil;
}

- (QSObject *)show:(QSObject *)dObject {
	
    dispatch_sync(dispatch_get_main_queue(), ^{
        id catalogPrefsClass = NSClassFromString(@"QSCatalogPrefPane");
        [catalogPrefsClass showEntryInCatalog:[QSLib entryForID:[dObject objectForType:QSCatalogEntryPboardType]]];
        [[catalogPrefsClass sharedInstance] reloadData];
        [[catalogPrefsClass sharedInstance] selectEntry:[QSLib entryForID:[dObject objectForType:QSCatalogEntryPboardType]]];
        [[catalogPrefsClass sharedInstance] showOptionsDrawer];
    });
    return nil;
}

- (QSObject *)addCatalogEntry:(QSObject *)dObject {
    QSCatalogEntry *parentEntry = [[QSLibrarian sharedInstance] catalogCustom];
    
    NSString *file = [[dObject objectForType:NSFilenamesPboardType] stringByStandardizingPath];
    NSString *uniqueString = [NSString uniqueString];
    
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict setObject:uniqueString forKey:kItemID];
	[childDict setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];

    [childDict setObject:[file lastPathComponent] forKey:kItemName];
	[childDict setObject:@"QSFileSystemObjectSource" forKey:kItemSource];

    [childDict setObject:[dObject arrayForType:NSFilenamesPboardType] forKey:kItemPath];
    [childDict setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
    
    QSCatalogEntry *childEntry = [QSCatalogEntry entryWithDictionary:childDict];
    
    [[parentEntry children] addObject:childEntry];
    [[childEntry info] setObject:[NSMutableDictionary dictionaryWithObject:file forKey:kItemPath] forKey:kItemSettings];
    [[childEntry info] setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
    [childEntry scanForced:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:childEntry];
    [dObject setObject:uniqueString forType:QSCatalogEntryPboardType];
    
    [self show:dObject];
    return nil;
}

- (QSObject *)rescan:(QSObject *)dObject {
	[[[QSLibrarian sharedInstance] entryForID:[dObject objectForType:QSCatalogEntryPboardType]] scanForced:YES];
	return nil;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


@end
