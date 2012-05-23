//
//  QSEffects.h
//  Quicksilver
//
//  Created by Alcor on 9/27/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QSWindowAnimation;

CGFloat QSStandardAlphaBlending(QSWindowAnimation *h, CGFloat f);
CGFloat QSStandardBrightBlending(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSStandardTransformBlending(QSWindowAnimation *h, CGFloat f);

CGAffineTransform QSShrinkEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSGrowEffect(QSWindowAnimation *hl, CGFloat f);

CGAffineTransform QSVillainousKryptonianEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSShakeItLikeAPolaroidPictureEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSLudicrousSpeedEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSExtraExtraEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSBoobTubeEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSMMBlowEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSBingeEffect(QSWindowAnimation *h, CGFloat f);
CGAffineTransform QSPurgeEffect(QSWindowAnimation *h, CGFloat f);

void CGSTransformLog(CGAffineTransform t);
