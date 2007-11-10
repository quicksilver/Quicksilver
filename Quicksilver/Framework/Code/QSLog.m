//
//  QSLog.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 1/27/06.

//

#import "QSLog.h"
//QSLog();

//void QSLog(char *sourceFile, int,lineNumberNSString *format, ...);


@implementation QSLog
+(void)logFile:(char*)sourceFile lineNumber:(int)lineNumber
		format:(NSString*)format, ...;
{
	va_list ap;
	NSString *print,*file;
//	if(__MLogOn==NO)
//		return;
	va_start(ap,format);
	file=[[NSString alloc] initWithBytes:sourceFile 
								  length:strlen(sourceFile) 
								encoding:NSUTF8StringEncoding];
	print=[[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	//QSLog handles synchronization issues
	QSLog(@"%s:%d %@",[[file lastPathComponent] UTF8String],
		  lineNumber,print);
	[print release];
	[file release];
	
	return;
}
@end

//void QuietLog (NSString *format, ...)
//{
//    // get a reference to the arguments on the stack that follow
//    // the format paramter
//    va_list argList;
//    va_start (argList, format);
//	
//    // NSString luckily provides us with this handy method which
//    // will do all the work for us, including %@
//    NSString *string;
//    string = [[NSString alloc] initWithFormat: format
//									arguments: argList];
//    va_end  (argList);
//	
//    // send it to standard out.
//    printf ("%s\n", [string UTF8String]);
//	
//    [string release];
//	
//} // QuietLog
