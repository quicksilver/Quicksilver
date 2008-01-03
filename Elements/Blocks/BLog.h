/**
 *  @file BLog.h
 *  @brief Blocks logging manager
 *  This class provides useful methods wrapped inside easy-to-use macros for printing geek stuff.
 *
 *  Blocks
 *
 *  Copyright 2006 Blocks. All rights reserved.
 */

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

/**
 *  @brief The BLlogManager log level
 */
typedef enum _BLoggingLevel {
    BLoggingDebug = 0,
    BLoggingInfo = 10,
    BLoggingWarn = 20,
    BLoggingError = 30,
    BLoggingFatal = 40
} BLoggingLevel;

/**
 *  @brief The public BLogManager interface
 */
@interface BLogManager : NSObject {

}

/**
 * @brief Returns the current logging level
 */
+ (BLoggingLevel)loggingLevel;

/**
 * @brief Set the logging level to @param level
 */
+ (void)setLoggingLevel:(BLoggingLevel)level;

/**
 * @brief Log a format + va_list message at level at lineNumber in fileName inside functionName
 */
+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName format:(NSString *)format arguments:(va_list)args;

/**
 * @brief Log a format + varargs message at level at lineNumber in fileName inside functionName
 */
+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;

/**
 * @brief Log an exception + format + varargs at lineNumber in fileName inside functionName
 */
+ (void)logErrorWithException:(NSException *)exception lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;

/**
 * @brief Log an assertion + format + varargs at lineNumber in fileName inside functionName
 */
+ (void)assert:(BOOL)assertion lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)methodName message:(NSString *)formatStr, ... ;

@end
