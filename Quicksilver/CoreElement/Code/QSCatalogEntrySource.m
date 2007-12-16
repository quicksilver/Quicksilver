

#import "QSCatalogEntrySource.h"
#import "QSCatalogPrefPane.h"

//#import "QSPrefsController.h"
#import "QSController.h"

#define QSCatalogEntryPboardType @"qs.catalogentry"

#define kQSCatalogEntryShowAction @"QSCatalogEntryShowAction"
#define kQSCatalogEntryRescanAction @"QSCatalogEntryRescanAction"


static BOOL firstCheck=NO;

@implementation QSCatalogEntrySource


+ (void)initialize{
    [[QSResourceManager imageNamed:@"prefsCatalog"]retain];
    [[QSResourceManager imageNamed:@"prefsCatalog"]createIconRepresentations];
}


-(id)init{
	if ((self=[super init])){
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateSelf) name:QSCatalogStructureChanged object:nil];
	}
return self;	
}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
//	if (VERBOSE)QSLog(@"rescan catalog %d",firstCheck);
	if (!firstCheck){
		
		firstCheck=YES;
		return NO;
	}
    return YES;
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry{
	return NO;	
}
- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [QSResourceManager imageNamed:@"prefsCatalog"];
}
- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{
	NSArray *theEntries=[[QSLib catalog] deepChildrenWithGroups:YES leaves:YES disabled:YES];
    return [self objectsFromCatalogEntries:theEntries];
}

- (void)showCatalog:(id)sender{
	QSLog(@"show");	
}

- (NSArray *)objectsFromCatalogEntries:(NSArray *)catalogObjects{
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	
    QSObject *newObject;

	//newObject=[QSObject messageObjectWithTargetClass:NSStringFromClass([self class]) selectorString:@"showCatalog:"];
	//[newObject setName:@"Show Catalog"];
	
	//[objects addObject:newObject];
	
	    QSCatalogEntry *thisEntry;
    NSString *name;
    NSString *theID;
    for(thisEntry in catalogObjects){
        name=[thisEntry name];
        theID=[thisEntry identifier];
        if (!theID) continue;
        if ([theID isEqualToString:@"QSSeparator"]) continue;
        if ([name isEqualToString:@"QSCATALOGROOT"])
            name=@"Quicksilver Catalog";
        else
            name=[NSString stringWithFormat:@"%@ (Catalog)",name];
        newObject=[QSObject objectWithName:name];
        [newObject setObject:theID forType:QSCatalogEntryPboardType];
        [newObject setPrimaryType:QSCatalogEntryPboardType];
        [newObject setIdentifier:theID];
        [objects addObject:newObject];
    }
    return objects;
}

// Object Handler Methods

- (BOOL)loadIconForObject:(QSObject *)object{

    QSCatalogEntry *theEntry=[QSLib entryForID:[object objectForType:QSCatalogEntryPboardType]];
	
    //QSLog(@"%@",[object objectForType:QSCatalogEntryPboardType]);
    [object setIcon:[theEntry icon]];
    return YES;
}

- (BOOL)objectHasChildren:(QSBasicObject *)object{
    return YES;
}
- (BOOL)objectHasValidChildren:(QSBasicObject *)object{
    return YES;
}
- (BOOL)loadChildrenForObject:(QSObject *)object{
    NSArray *children=[self childrenForObject:object];
    
    if (children){
        [object setChildren:children];
        return YES;   
    }
    return NO;
}
- (NSString *)identifierForObject:(QSBasicObject *)object{
    return [object objectForType:QSCatalogEntryPboardType];
}
- (NSArray *)childrenForObject:(QSBasicObject *)object{
    QSLibrarian *librarian=QSLib;
    QSCatalogEntry *theEntry=[librarian entryForID:[object objectForType:QSCatalogEntryPboardType]];

    if ([theEntry isGroup])
        return [self objectsFromCatalogEntries:[theEntry contents]];
    else
        return [theEntry contentsScanIfNeeded:YES];
    return NO;
}




// Action Provider Methods
- (NSArray *) types{
    return [NSArray arrayWithObject:QSCatalogEntryPboardType];
}
- (NSArray *) actions{
    
    QSAction *action=[QSAction actionWithIdentifier:kQSCatalogEntryShowAction];
    [action setIcon:[QSResourceManager imageNamed:@"prefsCatalog"]];
    [action setProvider:self];
    [action setAction:@selector(show:)];
    [action setArgumentCount:1];
    
    QSAction *action2=[QSAction actionWithIdentifier:kQSCatalogEntryRescanAction];
    [action2 setIcon:[QSResourceManager imageNamed:@"prefsCatalog"]];
    [action2 setProvider:self];
    [action2 setAction:@selector(rescan:)];
    [action2 setArgumentCount:1];
    
    return [NSArray arrayWithObjects:action,action2,nil];
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
    return [NSArray arrayWithObjects:kQSCatalogEntryShowAction,kQSCatalogEntryRescanAction,nil];
}

- (QSObject *) show:(QSObject *)dObject{
    QSLibrarian *librarian=QSLib;
    QSCatalogEntry *theEntry=[librarian entryForID:[dObject objectForType:QSCatalogEntryPboardType]];
    [NSClassFromString(@"QSCatalogPrefPane") showEntryInCatalog:theEntry];
    return nil;
}

- (QSObject *) rescan:(QSObject *)dObject{
    QSLibrarian *librarian=QSLib;
    QSCatalogEntry *theEntry=[librarian entryForID:[dObject objectForType:QSCatalogEntryPboardType]];
    [theEntry scanForced:YES];
    return nil;
}


@end
