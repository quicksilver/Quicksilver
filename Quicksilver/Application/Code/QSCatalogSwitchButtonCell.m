

#import "QSCatalogSwitchButtonCell.h"

@implementation QSCatalogSwitchButtonCell
//- (void)setObjectValue:(NSNumber *)newState {
//	QSLog(@"xstate %@", newState); 	
//	[super setObjectValue:newState];
//}
//- (id)objectValue {
//	return [NSNumber numberWithInt:state];
//}

- (int) nextState {
   // QSLog(@"state?");
    if ([self state] == NSMixedState) return NSOffState;
    if ([self state] == NSOffState) return NSMixedState;
    return NSOffState;
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  //  QSLog(@"%d", [self state]);
  //  QSLog(@"%@", [self _buttonImageSource]);
   if ([self state] == NSMixedState && falseMixedState) [(QSWindow *)[controlView window] setLiesAboutKey:YES];
    [super drawInteriorWithFrame:cellFrame inView:controlView];
    if ([self state] == NSMixedState && falseMixedState) [(QSWindow *)[controlView window] setLiesAboutKey:NO];
    
}

- (bool) falseMixedState { return falseMixedState;  }
- (void)setFalseMixedState:(bool)flag {falseMixedState = flag;}

@end
