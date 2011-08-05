/*
 *  QSFeatureLevel.h
 *  Quicksilver
 *
 *  Created by Alcor on 2/3/05.
 *  Copyright 2005 Blacktree. All rights reserved.
 *
 */

#define fDEV ((NSInteger) [NSApp featureLevel] >2)
#define fALPHA ((NSInteger) [NSApp featureLevel] >1)
#define fBETA ((NSInteger) [NSApp featureLevel] >0)
#define fSPECIAL 0
