//
//  QSCIEffectOverlay.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/20/05.

//

#import <Cocoa/Cocoa.h>

@interface QSCIEffectOverlay : NSObject {
	CGSWindow wid;
	CGSWindowFilterRef fid;
	CGSConnection cid;
}
- (void)setFilter:(NSString *)filter;
- (void)setLevel:(int)level;
- (void)createOverlayInRect:(CGRect)r;
@end
