

#import "QSCatalogSwitchButtonCell.h"
#import "QSWindow.h"
@implementation QSCatalogSwitchButtonCell
//- (void)setObjectValue:(NSNumber *)newState{
//	NSLog(@"xstate %@",newState);	
//	[super setObjectValue:newState];
//}
//- (id)objectValue{
//	return [NSNumber numberWithInt:state];
//}

- (int)nextState{
   // NSLog(@"state?");
    if ([self state]==NSMixedState) return NSOffState;
    if ([self state]==NSOffState) return NSMixedState;
    return NSOffState;
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
  //  NSLog(@"%d",[self state]);
  //  NSLog(@"%@",[self _buttonImageSource]);
   if ([self state]==NSMixedState && falseMixedState) [(QSWindow *)[controlView window]setLiesAboutKey:YES];
    [super drawInteriorWithFrame:cellFrame inView:controlView];
    if ([self state]==NSMixedState && falseMixedState) [(QSWindow *)[controlView window]setLiesAboutKey:NO];
    
}

- (bool)falseMixedState { return falseMixedState; }
- (void)setFalseMixedState:(bool)flag {falseMixedState = flag;}

@end
