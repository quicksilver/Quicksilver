/*
 *  QLPrivate.h
 *  Quicksilver01
 *
 *  Created by Nicholas Jitkoff on 6/15/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

extern const NSString *kQLThumbnailOptionContentTypeUTI;
//extern const NSString *kQLThumbnailOptionIconModeKey;

typedef void *QLThumbnailRef;
extern QLThumbnailRef QLThumbnailCreate(void *unknownNULL, CFURLRef fileURL, CGSize iconSize, CFDictionaryRef options);
extern CGImageRef QLThumbnailCopyImage(QLThumbnailRef thumbnail);

