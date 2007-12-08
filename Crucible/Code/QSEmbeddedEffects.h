//
//  QSEffects.h
//  Quicksilver
//
//  Created by Alcor on 9/27/04.

//

#import <Cocoa/Cocoa.h>





@class QSWindowAnimation;

float QSStandardAlphaBlending(QSWindowAnimation *h,float f);
float QSStandardBrightBlending(QSWindowAnimation *h,float f);
CGAffineTransform QSStandardTransformBlending(QSWindowAnimation *h,float f);

CGAffineTransform QSShrinkEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSGrowEffect(QSWindowAnimation *hl,float f);

CGAffineTransform QSVillainousKryptonianEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSShakeItLikeAPolaroidPictureEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSLudicrousSpeedEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSExtraExtraEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSBoobTubeEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSMMBlowEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSBingeEffect(QSWindowAnimation *h,float f);
CGAffineTransform QSPurgeEffect(QSWindowAnimation *h,float f);

void CGSTransformLog(CGAffineTransform t);