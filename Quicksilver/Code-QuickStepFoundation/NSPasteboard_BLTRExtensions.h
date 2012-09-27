//
//  NSPasteboard_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Sun Nov 09 2003.
//  Copyright (c) 2003 Blacktree, Inc.. All rights reserved.
//

void QSForcePaste();

@interface NSPasteboard (Clippings)
+ (NSPasteboard *)pasteboardByFilteringClipping:(NSString *)pacg;
@end

#define QSPrivatePboardType @"QSPrivatePboardType" // This pasteboard type prevents recording by the Clip History

#define standardPasteboardTypes [NSArray arrayWithObjects:@"Apple URL pasteboard type", NSColorPboardType, NSFileContentsPboardType, NSFilenamesPboardType, NSFontPboardType, NSHTMLPboardType, NSPDFPboardType, NSPostScriptPboardType, NSRulerPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, NSTabularTextPboardType, NSTIFFPboardType, NSURLPboardType, NSVCardPboardType, NSFilesPromisePboardType, nil]

#define clippingTypes [NSSet setWithObjects:@"textClipping", @"pictClipping", @"'clpp'", @"'clpt'", @"webloc", @"inetloc", @"'ilht'", @"'ilaf'", nil]
#define PLISTTYPES [NSArray arrayWithObjects:NSFilenamesPboardType, @"ABPeopleUIDsPboardType", @"WebURLsWithTitlesPboardType", @"AddressesPboardType", nil]
#define TEXTTYPES [NSSet setWithObjects:@"QSObjectID", NSStringPboardType, @"NeXT plain ascii pasteboard type", NSTabularTextPboardType, NSHTMLPboardType, nil]
#define SYLETYPES [NSSet setWithObjects:NSStringPboardType, @"NeXT Rich Text Format v1.0 pasteboard type", @"NeXT Rich Text Format v1.0 pasteboard type", nil]
#define URLTYPES [NSSet setWithObjects:NSURLPboardType, nil]
#define IMAGETYPES [NSSet setWithArray:[NSImage imagePasteboardTypes]]
#define OTHERTYPES [NSSet setWithObjects:NSColorPboardType, nil]
#define CONTACTTYPES [NSSet setWithObjects:NSVCardPboardType, nil]
