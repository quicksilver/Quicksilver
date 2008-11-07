/*
 *  QSFeatureLevel.h
 *  Quicksilver
 *
 *  Created by Alcor on 2/3/05.
 *  Copyright 2005 Blacktree. All rights reserved.
 *
 */

#define fDEV ((int) [NSApp featureLevel] >2)
#define fALPHA ((int) [NSApp featureLevel] >1)
#define fBETA ((int) [NSApp featureLevel] >0)
#define fSPECIAL 0
