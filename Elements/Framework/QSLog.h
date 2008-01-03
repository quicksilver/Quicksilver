/**
 *  @file QSLog.h
 *  @brief Quicksilver Logging facility
 *  This provides logging macros that use the underlying BLogManager.
 *  All the following macros ends in a QSLog-style format and arguments
 *  
 *  QSElements
 *
 *  Created by alchemist on 3/3/07.
 *  Copyright 2007 Blacktree. All rights reserved.
 *  
 */

#import "BLog.h"

/**
 *  @brief Log an informational message
 */
#define QSLog(...) [BLogManager logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
/**
 *  @brief Log a debug message
 */
#define QSLogDebug(...) [BLogManager logWithLevel:BLoggingDebug LOCATION_PARAMETERS message:__VA_ARGS__]
/**
 *  @brief Log an informational message
 */
#define QSLogInfo(...) [BLogManager logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
/**
 *  @brief Log a warning
 */
#define QSLogWarn(...) [BLogManager logWithLevel:BLoggingWarn LOCATION_PARAMETERS message:__VA_ARGS__]
/**
 *  @brief Log an error
 */
#define QSLogError(...) [BLogManager logWithLevel:BLoggingError LOCATION_PARAMETERS message:__VA_ARGS__]
/**
 *  @brief Log a fatal error
 */
#define QSLogFatal(...) [BLogManager logWithLevel:BLoggingFatal LOCATION_PARAMETERS message:__VA_ARGS__]

/**
 *  @brief Log an error caused by an exception
 *  @param e The exception that caused the error.
 */
#define QSLogErrorWithException(e, ...) [BLogManager logErrorWithException:e LOCATION_PARAMETERS message:__VA_ARGS__]

/**
 *  @brief Log an assertion failure
 *  @param assertion The assertion to test.
 */
#define QSLogAssert(assertion, ...) [BLogManager assert:assertion LOCATION_PARAMETERS message:__VA_ARGS__]
