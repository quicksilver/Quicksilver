//
//  QSUserDefinedProxySource.m
//  Quicksilver
//
//  Created by Rob McBroom on 2012/12/04.
//
//

#import "QSUserDefinedProxySource.h"

@implementation QSUserDefinedProxySource

#pragma mark Catalog Entry

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry
{
    // rescan only if the indexDate is prior to the last launch
    NSDate *launched = [[NSRunningApplication currentApplication] launchDate];
    if (launched) {
        return ([launched compare:indexDate] == NSOrderedAscending);
    } else {
        // Quicksilver wasn't launched by LaunchServices - date unknown - rescan to be safe
        return NO;
    }
}

- (BOOL)entryCanBeIndexed:(QSCatalogEntry *)theEntry
{
    return NO;
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry
{
    // create a proxy object with this class as its provider
    NSString *provider = NSStringFromClass([self class]);
    NSDictionary *proxyDetails = [NSDictionary dictionaryWithObject:provider forKey:@"providerClass"];
    QSProxyObject *proxy = [QSProxyObject proxyWithDictionary:proxyDetails];
    // assign values to the proxy object
    NSDictionary *settings = theEntry.sourceSettings;
    NSString *targetID = [settings objectForKey:@"target"];
    NSString *name = [settings objectForKey:@"name"];
    [proxy setIdentifier:[NSString stringWithFormat:@"QSUserDefinedProxy:%@", name]];
    [proxy setName:name];
    [proxy setObject:targetID forMeta:@"target"];
    return [NSArray arrayWithObject:proxy];
}

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry
{
    NSDictionary *settings = theEntry.sourceSettings;
    NSString *targetID = [settings objectForKey:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    if (target) {
        [target loadIcon];
        return [target icon];
    }
    return [QSResourceManager imageNamed:@"Object"];
}

#pragma mark Proxy Object

- (QSObject *)resolveProxyObject:(QSProxyObject *)proxy
{
    NSString *targetID = [proxy objectForMeta:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    if (target) {
        return target;
    } else {
        NSLog(@"The synonym '%@' refers to something that isn't in the catalog: %@", [proxy name], targetID);
    }
    return nil;
}

- (NSTimeInterval)cacheTimeForProxy:(id)proxy
{
    // these proxies always point to the same object, so give it a long cache time
    return 1800.0; // 30 minutes
}

- (NSArray *)typesForProxyObject:(QSProxyObject *)proxy
{
    NSString *targetID = [proxy objectForMeta:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    if (target) {
        return [target types];
    }
    return nil;
}

- (NSString *)detailsOfObject:(QSObject *)object
{
    NSString *targetID = [object objectForMeta:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    if (target) {
        NSString *localizedDetails = NSLocalizedStringFromTableInBundle(@"Synonym for %@", nil, [NSBundle bundleForClass:[self class]], nil);
        return [NSString stringWithFormat:localizedDetails, [target displayName]];
    }
    return nil;
}

#pragma mark Target QSObject Impersonation

- (BOOL)loadChildrenForObject:(QSObject *)proxy
{
    // make this object act as much like the target as possible
    // (show the target's children instead of the target)
    NSString *targetID = [proxy objectForMeta:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    if (target) {
        [proxy setChildren:[target children]];
        [proxy setAltChildren:[target altChildren]];
        return YES;
    }
    return NO;
}

#pragma mark Catalog Entry UI

- (BOOL)isVisibleSource
{
    return YES;
}

- (NSView *)settingsView
{
    if (![super settingsView]) {
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
    }
    return [super settingsView];
}

- (void)populateFields
{
    NSMutableDictionary *settings = self.selectedEntry.sourceSettings;
    NSString *name = [settings objectForKey:@"name"];
    [synonymName setStringValue:name?name:@""];
    NSString *targetID = [settings objectForKey:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    if (target) {
        [targetIcon setImage:[target icon]];
        [targetLabel setStringValue:[target displayName]];
    } else {
        [targetIcon setImage:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
        [targetLabel setStringValue:@""];
    }
}

- (IBAction)showTargetPicker:(id)sender
{
    
    if ([targetPickerWindow isVisible]) {
        // don't make the window appear again if it's already visible
        return;
    }
    [targetPickerController setEntrySource:self];
    NSMutableDictionary *settings = self.selectedEntry.sourceSettings;
    NSString *targetID = [settings objectForKey:@"target"];
    QSObject *target = [QSLib objectWithIdentifier:targetID];
    [[targetPickerWindow searchObjView] selectObjectValue:target];
    
    // Convert the sender (NSButton)'s rect to screen co-ords
    NSRect relativeToWindow = [sender convertRect:[sender bounds] toView:nil];
    // the position of the button on screen
    NSRect targetRect = [self.settingsView.window convertRectToScreen:relativeToWindow];
    [targetPickerWindow setFrame:targetRect display:YES];
    [[targetPickerWindow searchObjView] setFrame:NSMakeRect(0, 0, targetRect.size.width, targetRect.size.height)];
    [targetPickerWindow makeKeyAndOrderFront:self];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self save];
}

- (void)save
{
	// update catalog entry
    NSMutableDictionary *settings = self.selectedEntry.sourceSettings;
    QSObject *target = [[targetPickerController dSelector] objectValue];
    if (!target) {
        // refer to the established target if a new one wasn't set
        NSString *targetID = [settings objectForKey:@"target"];
        target = [QSLib objectWithIdentifier:targetID];
    }
    NSString *localizedPlaceholder = NSLocalizedStringFromTableInBundle(@"Synonym for %@", nil, [NSBundle bundleForClass:[self class]], nil);
    NSString *synonym = [synonymName stringValue] ? [synonymName stringValue] : [NSString stringWithFormat:localizedPlaceholder, [target displayName]];
    if ([synonym length] && target) {
        NSString *entryName = [NSString stringWithFormat:@"%@ %C %@", synonym, (unsigned short)0x2192, [target displayName]];
        self.selectedEntry.name = entryName;
    }
    [settings setObject:synonym forKey:@"name"];
    if (target) {
        [settings setObject:[target identifier] forKey:@"target"];
        [settings setObject:[target primaryType] forKey:@"targetType"];
    }
    [self.selectedEntry refresh:YES];
	[self populateFields];
}
@end
