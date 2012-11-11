/*
 *  QSUTI.h
 *  Quicksilver
 *
 *  Created by Alcor on 4/5/05.
 *  Copyright 2005 Blacktree. All rights reserved.
 *
 */


NSString *QSUTIOfFile(NSString *path);
NSString *QSUTIOfURL(NSURL *url);
NSString *QSUTIWithLSInfoRec(NSString *path, LSItemInfoRecord *infoRec);
NSString *QSUTIForAnyTypeString(NSString *type);
NSString *QSUTIForExtensionOrType(NSString *extension, OSType filetype);
