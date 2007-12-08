#import "QSCollection.h"

#import "QSPreferenceKeys.h"
#import "QSSearchObjectView.h"
#import "QSLibrarian.h"
#import "QSResultController.h"
#import "QSInterfaceController.h"
#import "QSFSBrowserMediator.h"
#import "QSMnemonics.h"
#import "QSWindow.h"
#import "QSRegistry.h"
//#import "QSFinderProxy.h"

#import <QSFoundation/QSFoundation.h>
#import "QSCollection.h"
//#import "QSFSBrowserMediator.h"

#import "QSObject.h"
#import "QSObject_Drag.h"
#import "QSAction.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"

#import "QSSeparatorObject.h"

#import "QSObject_Pasteboard.h"
#import "NSString_Purification.h"
#import "QSObject_PropertyList.h"
#import "QSBackgroundView.h"
#import "QSController.h"

#include "QSGlobalSelectionProvider.h"


#import "QSTextProxy.h"
#define pUserKeyBindingsPath [@"~/Library/Application Support/Quicksilver/KeyBindings.qskeys" stringByStandardizingPath]
NSMutableDictionary *bindingsDict=nil;



@implementation QSSearchObjectView 


- (void)awakeFromNib{
	[super awakeFromNib];
	resultController=nil;
	sController=[[QSIncrementalSearchController alloc]init];
	rController=[[NSArrayController alloc]init];
	[rController setAvoidsEmptySelection:YES];
	
	//[rController bind:@"contentArray" toObject:sController withKeyPath:@"resultArray" options:nil];
	//[self bind:@"objectValue" toObject:results withKeyPath:@"selectedObjects" options:nil];
//	[sController addObserver:self
//				  forKeyPath:@"resultArray"
//					 options:0
//					 context:nil];
//	[rController addObserver:self
//				  forKeyPath:@"selectedObjects"
//					 options:0
//					 context:nil];
	
	
	


}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([object isEqual:sController]){
		
	}else{
		
	}
	NSLog(@"change %@ %@ %@",keyPath,object,[object valueForKeyPath:keyPath]);

}

- (void)insertText:(id)aString{
	[sController insertText:aString];
#warning	if (![partialString length])[self updateHistory];
}

- (NSMutableArray *)results {
    return [[results retain] autorelease]; 
}
- (void)setResults:(NSMutableArray *)newResults {
    if (results != newResults) {
        [results release];
        results = [newResults copy];
    }
}



- (void)setSearchMode:(QSSearchMode)newSearchMode {
	[sController setSearchMode:newSearchMode];
}

- (void)reset:(id)sender{
	
}
- (void)setResultArray:(NSMutableArray *)newResultArray {
	[self setResults:newResultArray];
//	if ([[resultController window] isVisible])
//		[self reloadResultTable];
	
	if ([[self controller]respondsToSelector:@selector(searchView:changedResults:)])
		[(id)[self controller]searchView:self changedResults:newResultArray];
	
}

- (void)clearObjectValue{
	//[self updateHistory];
	[super setObjectValue:nil];
	//selection--;
	//	[[NSNotificationCenter defaultCenter] postNotificationNamse:@"SearchObjectChanged" object:self];
}


-(void)clearSearch{
	[sController clearSearch];
	[self setVisibleString:@""];
	[self setMatchedString:nil];
}
- (IBAction) toggleResultView:sender{
//	if([[resultController window] isVisible])
//		[self hideResultView:sender];
//	else
//		[self showResultView:sender];
}
- (void)setVisibleString:(NSString *)string{
	//[resultController->searchStringField setStringValue:string];
	if ([[self controller]respondsToSelector:@selector(searchView:changedString:)])
		[(id)[self controller]searchView:self changedString:string];
}
//- (void)setResultArray:(NSArray *)newResultArray {
//	[sController setResultArray:nil];
//}

- (void)setSearchArray:(NSArray *)newSearchArray {
	[sController setSearchArray:nil];
}


@end


@implementation QSSearchObjectView (Accessors)
- (NSArrayController *)results {
    return [[results retain] autorelease]; 
}
- (void)setResults:(NSArrayController *)newResults {
    if (results != newResults) {
        [results release];
        results = [newResults copy];
    }
}


- (void)setResultsPadding:(float)aResultsPadding
{
	resultsPadding = aResultsPadding;
}




- (NSRectEdge)preferredEdge { return preferredEdge; }
- (void)setPreferredEdge:(NSRectEdge)newPreferredEdge {
	preferredEdge = newPreferredEdge;
}




//- (id)selectedObject { return selectedObject; }
//
//- (void)setSelectedObject:(id)newSelectedObject {
//	[selectedObject release];
//	selectedObject = [newSelectedObject retain];
//}



- (NSText *)currentEditor {
	if ([super currentEditor])
		return [super currentEditor];
	else
		return [[currentEditor retain] autorelease]; 
}

- (void)setCurrentEditor:(NSText *)aCurrentEditor
{
    if (currentEditor != aCurrentEditor) {
        [currentEditor release];
        currentEditor = [aCurrentEditor retain];
    }
}
- (BOOL)allowText { return allowText; }
- (void)setAllowText:(BOOL)flag {
	allowText = flag;
}

- (BOOL)allowNonActions { return allowNonActions; }
- (void)setAllowNonActions:(BOOL)flag{
    allowNonActions = flag;
}


- (NSString *)matchedString { return [[matchedString retain] autorelease]; }

- (void)setMatchedString:(NSString *)newMatchedString {
	[matchedString release];
	matchedString = [newMatchedString copy];
	[self setNeedsDisplay:YES];
}


@end
