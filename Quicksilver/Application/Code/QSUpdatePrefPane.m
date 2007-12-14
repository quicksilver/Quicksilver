

#import "QSUpdatePrefPane.h"


#import "QSUpdateController.h"

static int bundleNameSort(id item1, id item2, void *self) {
	return [[item1 objectForInfoDictionaryKey:@"CFBundleName"] caseInsensitiveCompare:[item2 objectForInfoDictionaryKey:@"CFBundleName"]];
}

@implementation QSUpdatePrefPane
- (id)init {
    self = [super initWithBundle:[NSBundle bundleForClass:[QSUpdatePrefPane class]]];
    if (self) {
		
		plugInArray = [[[QSReg identifierBundles] allValues] mutableCopy];
		[plugInArray removeObject:[NSBundle mainBundle]];
		[plugInArray sortUsingFunction:(int (*)(id, id, void *))bundleNameSort context:(void *)self];
		
    }
    return self;
}

- (NSImage *)icon {
	return [QSResourceManager imageNamed:@"prefsUpdate"];
}

- (NSString *)paneDescription {
	return @"Modify update frequency";
}

- (NSString *)mainNibName {
	return @"QSUpdatePrefPane";
}

- (void)mainViewDidLoad {
	
}


- (IBAction)checkNow:(id)sender {
	[[QSUpdateController sharedInstance] checkForUpdate:sender]; 	
	if ([[[QSUpdateController sharedInstance] updatedPlugIns] count])
		[installButton setEnabled:YES];
	[plugInTable reloadData];
}

- (IBAction)install:(id)sender {

}



- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int) rowIndex {
	
	if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
		return [NSNumber numberWithBool:YES];
	} else {
	return [[[[QSUpdateController sharedInstance] updatedPlugIns] objectAtIndex:rowIndex] objectForInfoDictionaryKey:[aTableColumn identifier]];
    }
	return nil;  
}


- (int) numberOfRowsInTableView:(NSTableView *)tableView {
         return [[[QSUpdateController sharedInstance] updatedPlugIns] count];
    
    return 0;
}


- (void)tableView:(NSTableView *)aTableView
   setObjectValue:anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int) rowIndex
{
    return;
}

@end
