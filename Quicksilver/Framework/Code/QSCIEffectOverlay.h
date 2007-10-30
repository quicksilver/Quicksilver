//
//  QSCIEffectOverlay.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CGSPrivate.h"
#import "CGSPrivate+QSMods.h"

@interface QSCIEffectOverlay : NSObject {
	CGSWindow wid;
	CGSWindowFilterRef fid;
	CGSConnection cid;
}
- (void)setFilter:(NSString *)filter;
-(void)setLevel:(int)level;
- (void)createOverlayInRect:(CGRect) r;
@end
