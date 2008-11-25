
// Standard Quicksilver data types

extern NSString *QSFilePathType; 		//NSString
extern NSString *QSTextType; 			//NSString
extern NSString *QSAliasDataType; 		//NSData
extern NSString *QSAliasFilePathType; 	//NSString
extern NSString *QSURLType; 				//NSString
extern NSString *QSEmailAddressType; 	//NSString
//extern NSString *QSContactEmailType; 	//NSString
extern NSString *QSContactPhoneType; 	//NSString
extern NSString *QSContactAddressType; 	//NSString
extern NSString *QSFormulaType; 			//NSString
extern NSString *QSActionType; 			//NSDictionary
extern NSString *QSProcessType; 			//NSDictionary (NSWorkspace Style)
extern NSString *QSABPersonType; 		//NSString (UID)
extern NSString *QSNumericType; 			//NSNumber
extern NSString *QSIMAccountType; 				//NSString ("AIM:accountname") also MSN, ICQ, Jabber, Yahoo
extern NSString *QSIMMultiAccountType; 				//NSSet of ("AIM:accountname") also MSN, ICQ, Jabber, Yahoo
extern NSString *QSCommandType; 			//QSCommand
extern NSString *QSHandledType; 			//NSDictionary

// Pasteboard types
#define QSPrivatePboardType @"QSPrivatePboardType" // This pasteboard type prevents recording by the Clip History


#define standardPasteboardTypes [NSArray arrayWithObjects:@"Apple URL pasteboard type", NSColorPboardType, NSFileContentsPboardType, NSFilenamesPboardType, NSFontPboardType, NSHTMLPboardType, NSPDFPboardType, NSPICTPboardType, NSPostScriptPboardType, NSRulerPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, NSTabularTextPboardType, NSTIFFPboardType, NSURLPboardType, NSVCardPboardType, NSFilesPromisePboardType, nil]

#define clippingTypes [NSSet setWithObjects:@"textClipping", @"pictClipping", @"'clpp'", @"'clpt'", @"webloc", @"inetloc", @"'ilht'", @"'ilaf'", nil]
#define PLISTTYPES [NSArray arrayWithObjects:NSFilenamesPboardType, @"ABPeopleUIDsPboardType", @"WebURLsWithTitlesPboardType", @"AddressesPboardType", nil]
#define TEXTTYPES [NSSet setWithObjects:@"QSObjectID", NSStringPboardType, @"NeXT plain ascii pasteboard type", NSTabularTextPboardType, NSHTMLPboardType, nil]
#define SYLETYPES [NSSet setWithObjects:NSStringPboardType, @"NeXT Rich Text Format v1.0 pasteboard type", @"NeXT Rich Text Format v1.0 pasteboard type", nil]
#define URLTYPES [NSSet setWithObjects:NSURLPboardType, nil]
#define IMAGETYPES [NSSet setWithArray:[NSImage imagePasteboardTypes]]
#define OTHERTYPES [NSSet setWithObjects:NSColorPboardType, nil]
#define CONTACTTYPES [NSSet setWithObjects:NSVCardPboardType, nil]

