//
//  QSPreferencePane.m
//  Quicksilver
//
//  Created by Alcor on 11/2/04.

//

#import "QSPreferencePane.h"

#import "QSResourceManager.h"
#import "QSMacros.h"
#import "QSHelp.h"
#import "NTViewLocalizer.h"
#import "QSNotifications.h"

#import "QSLocalization.h"


#import "QSLoginItemFunctions.h"
#import "QSInterfaceMediator.h"
#import "QSPreferenceKeys.h"

#import "NSBundle_BLTRExtensions.h"

//@implementation NSPreferencePane (QSPrefPaneInformal)
//- (NSImage *)  paneIcon{
//	NSImage *image=[QSResourceManager imageNamed:NSStringFromClass([self class])];
//	if (!image)image=[QSResourceManager imageNamed:@"DocPrefs"];
//	return image;
//}
//- (NSString *) paneName{
//	NSString *paneClass=NSStringFromClass([self class]);
//	NSString *locName=[[QSReg bundleForClassName:paneClass]safeLocalizedStringForKey:paneClass value:paneClass table:nil];
//	return locName;
//}
//- (NSNumber *) panePriority{
//	return nil;	
//}
//- (NSString *) paneDescription{
//	return @"Preferences";
//}
//- (int)featureLevel{
//	return 1;	
//}
//- (NSString *)identifier{
//	return NSStringFromClass([self class]);
//}
//
//- (void)paneLoadedByController:(id)controller{}
//@end

@implementation QSPreferencePane
- (id)initWithInfo:(NSDictionary *)info {
    self = [self init];
    if (self) {
		_info=[info retain];
	}
    return self;
}
- (id)initWithBundle:(NSBundle *)bundle {
	return [super init];
}

- (void)setInfo:(NSDictionary *)info{
	if (_info!=info){
		[info autorelease];
		_info=[info retain];
	}
}
- (void)dealloc {
    [_info release];
	_info=nil;
	[_mainView release];
	_mainView=nil;
    [super dealloc];
}

//- (id)icon{return [self paneIcon];}

- (NSString *) mainNibName{
	NSString *nibName=[_info objectForKey:@"nibName"];
	if (!nibName)nibName = NSStringFromClass([self class]);
	return nibName;
}
- (NSBundle *)mainNibBundle{
	NSString *bundleID=[_info objectForKey:@"nibBundle"];
	NSBundle *bundle=nil;
	if (bundleID)
		bundle=[NSBundle bundleWithIdentifier:bundleID];
	//QSLog(@"%@ %@",bundleID, _info);
	if (!bundle)
		bundle=[NSBundle bundleForClass:[self class]];
	return bundle;
}

- (NSView *)mainView{
	return _mainView;
}

- (NSView *)loadMainView{
	
	//[[self mainNibBundle]loadNibFile:[self mainNibName] 
//				   externalNameTable:[NSDictionary dictionaryWithObject:self forKey:@"NSOwner"] 
//							withZone:[self zone]];
	NSNib *nib=[[NSNib alloc] initWithNibNamed:[self mainNibName] bundle:[self mainNibBundle]];
	NSArray *objects=nil;
	[nib instantiateNibWithOwner:self topLevelObjects:&objects];
	//QSLog(@"objects %@",objects);
	//QSLog(@"window %@",_window);
	_mainView=[[_window contentView]retain];
	if (QSIsLocalized)
		[NTViewLocalizer localizeView:_mainView 
							table:[[self mainNibName]stringByAppendingPathExtension:@"nib"]
						   bundle:[self mainNibBundle]];

	[_window release];
	_window=nil;
	[nib release];
	[self mainViewDidLoad];
	return _mainView;
}

- (IBAction) showPaneHelp:(id)sender{
	QSShowHelpPage([self helpPage]);
}

- (NSString *)helpPage{return [@"quicksilver/preferences/" stringByAppendingString:NSStringFromClass([self class])];}

- (void)paneWillMoveToWindow:(NSWindow *)newWindow{}
- (void)paneDidMoveToWindow:(NSWindow *)newWindow{}

- (void) mainViewDidLoad{}
- (void) willSelect{}
- (void) didSelect{}

- (void) willUnselect{}
- (void) didUnselect{}
- (void) didReselect{}
- (void)paneLoadedByController:(id)controller{}
- (void)requestRelaunch{
	[NSApp requestRelaunch:nil];
}
@end