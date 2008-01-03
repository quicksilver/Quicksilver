//
//  BLog.m
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import "BLog.h"

@implementation BLogManager

static BLoggingLevel LoggingLevel = BLoggingWarn;

+ (BLoggingLevel)loggingLevel {
	return LoggingLevel;
}

+ (void)setLoggingLevel:(BLoggingLevel)level {
	LoggingLevel = level;
}

+ (NSString *)typeStringForLevel:(BLoggingLevel)level {
	if (level >= BLoggingFatal) return @"F";
	else if (level >= BLoggingError) return @"E";
	else if (level >= BLoggingWarn) return @"W";
	else if (level >= BLoggingInfo) return @"I";
	else return @"D";
}

+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName format:(NSString *)format arguments:(va_list)args {
	if ([self loggingLevel] > level) return;
	
	CFStringRef message = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, 
															   NULL, 
															   (CFStringRef)format, 
															   args);
    
	NSLog(@"%@ %-32s %@", [self typeStringForLevel:level], functionName, message);
    CFRelease(message);
}

+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ... {
	if ([self loggingLevel] > level) return;
	
	va_list args;
	va_start(args, message);
	[self logWithLevel:level lineNumber:lineNumber fileName:fileName function:functionName format:message arguments:(va_list)args];
	va_end(args);
}

+ (void)logErrorWithException:(NSException *)exception lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ... {
	if ([self loggingLevel] > BLoggingError) return;
	
	va_list args;
	va_start(args, message);
	[self logWithLevel:BLoggingError lineNumber:lineNumber fileName:fileName function:functionName format:message arguments:(va_list)args];
	va_end(args);	
}

+ (void)assert:(BOOL)assertion lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ... {
	if ([self loggingLevel] > BLoggingError) return;
	if (assertion) return;
	
	va_list args;
	va_start(args, message);
	message = [@"ASSERT " stringByAppendingString:message];
	[self logWithLevel:BLoggingError lineNumber:lineNumber fileName:fileName function:functionName format:message arguments:(va_list)args];
	va_end(args);	
	
}

@end
