//
//  BLog.h
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LOCATION_PARAMETERS lineNumber:__LINE__ fileName:(char *)__FILE__ function:(char *)__PRETTY_FUNCTION__

#define BLog(...) [BLogManager logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogDebug(...) [BLogManager logWithLevel:BLoggingDebug LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogInfo(...) [BLogManager logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogWarn(...) [BLogManager logWithLevel:BLoggingWarn LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogError(...) [BLogManager logWithLevel:BLoggingError LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogFatal(...) [BLogManager logWithLevel:BLoggingFatal LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogErrorWithException(e, ...) [BLogManager logErrorWithException:e LOCATION_PARAMETERS message:__VA_ARGS__]

#define BLogAssert(assertion, ...) [BLogManager assert:assertion LOCATION_PARAMETERS message:__VA_ARGS__]

typedef enum _BLoggingLevel {
    BLoggingDebug = 0,
    BLoggingInfo = 10,
    BLoggingWarn = 20,
    BLoggingError = 30,
    BLoggingFatal = 40
} BLoggingLevel;

@interface BLogManager : NSObject {

}

+ (BLoggingLevel)loggingLevel;
+ (void)setLoggingLevel:(BLoggingLevel)level;

+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName format:(NSString *)format arguments:(va_list)args;
+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;
+ (void)logErrorWithException:(NSException *)exception lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;
+ (void)assert:(BOOL)assertion lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)methodName message:(NSString *)formatStr, ... ;

@end
