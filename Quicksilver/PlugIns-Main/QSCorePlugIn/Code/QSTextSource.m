

#import "QSTextSource.h"
#import "QSTypes.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"
#import "QSObject_PropertyList.h"

#import "NSUserDefaults_BLTRExtensions.h"
#import "QSLargeTypeDisplay.h"
#import "QSFoundation.h"

#import "QSTextProxy.h"

#import "QSObject_PropertyList.h"
#define textTypes [NSArray arrayWithObjects:@"'TEXT'",@"txt",@"html",@"htm",nil]

#define kQSTextTypeAction @"QSTextTypeAction"

#define kQSTextDiffAction @"QSTextDiffAction"
#define kQSLargeTypeAction @"QSLargeTypeAction"

Ascii2KeyCodeTable keytable;
@implementation QSTextActions
+(void) initialize{
    [self InitAscii2KeyCodeTable];
}



- (QSObject *)showLargeType:(QSObject *)dObject{
	QSShowLargeType([dObject stringValue]);
	return nil;
}



- (QSObject *)showDialog:(QSObject *)dObject{
	[NSApp activateIgnoringOtherApps:YES];
	NSRunInformationalAlertPanel(@"Quicksilver", [dObject stringValue], @"OK", nil, nil);
	
	return nil;
}

- (QSObject *)speakText:(QSObject *)dObject{
	
	NSString *string=[dObject stringValue];
	string=[string stringByReplacing:@"\"" with:@"\\\""];
	string=[NSString stringWithFormat:@"say \"%@\"",string];

	[[[[NSAppleScript alloc]initWithSource:string]autorelease]executeAndReturnError:nil];


	return nil;
}


- (QSObject *) typeObject:(QSObject *)dObject{
    //  NSLog( AsciiToKeyCode(&ttable, "m") {
    //  short AsciiToKeyCode(Ascii2KeyCodeTable *ttable, short asciiCode) {
    
    NSLog([dObject objectForType:QSTextType]);
    
    [self typeString2:[dObject objectForType:QSTextType]];
    
    return nil;
    }



+(OSStatus)InitAscii2KeyCodeTable
{
    unsigned char *theCurrentKCHR, *ithKeyTable;
    short count, i, j, resID;
    Handle theKCHRRsrc;
    ResType rType;
    /* set up our table to all minus ones */
    for (i=0;i<256; i++) keytable.transtable[i] = -1;
    /* find the current kchr resource ID */
    keytable.kchrID = (short) GetScriptVariable(smCurrentScript,
                                                smScriptKeys);
    /* get the current KCHR resource */
    theKCHRRsrc = GetResource('KCHR', keytable.kchrID);
    if (theKCHRRsrc == NULL) return resNotFound;
    GetResInfo(theKCHRRsrc,&resID,&rType,keytable.KCHRname);
    /* dereference the resource */
    theCurrentKCHR = (unsigned char *) (*theKCHRRsrc);
    /* get the count from the resource */
    count = * (short *) (theCurrentKCHR + kTableCountOffset);
    /* build inverse table by merging all key tables */
    for (i=0; i<count; i++) {
        ithKeyTable = theCurrentKCHR + kFirstTableOffset + (i * kTableSize);
        for (j=0; j<kTableSize; j++) {
            if ( keytable.transtable[ ithKeyTable[j] ] == -1)
                keytable.transtable[ ithKeyTable[j] ] = j;
        }
    }
    /* all done */
    
    return noErr;
}

-(short)AsciiToKeyCode:(short)asciiCode
{    
    if (asciiCode >= 0 && asciiCode <= 255) return
        keytable.transtable[asciiCode];
    else return -1;
}

-(void)typeString:(NSString *)string{
	const char *s=[string UTF8String];
	int i;
	BOOL upper;
	for (i=0;i<strlen(s);i++){
		CGKeyCode code=[self AsciiToKeyCode:s[i]];
		// NSLog(@"%d",code);   
		upper=isupper(s[i]);
		if (upper) CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)56, true ); // shift down
		CGPostKeyboardEvent( (CGCharCode)s[i], (CGKeyCode)code, true ); // 'z' down
		CGPostKeyboardEvent( (CGCharCode)s[i], (CGKeyCode)code, false ); // 'z' up
		if (upper) CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)56, false ); // 'shift up
	}
}


-(void)typeString2:(NSString *)string{
	string=[string stringByReplacing:@"\n"with:@"\r"];
	NSAppleScript *sysEventsScript=[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"System Events" ofType:@"scpt"]] error:nil];
	NSDictionary *errorDict=nil;
	//NSAppleEventDescriptor *desc=
	[sysEventsScript executeSubroutine:@"type_text" arguments:string error:&errorDict];
	if (errorDict) NSLog(@"Execute Error: %@",errorDict);
}
@end




