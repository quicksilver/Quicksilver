/*
 *  QSLog.h
 *  Elements
 *
 *  Created by alchemist on 3/3/07.
 *  Copyright 2007 Blacktree. All rights reserved.
 *
 */

#import "BLog.h"

#define QSLog(...) [BLogManager logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogDebug(...) [BLogManager logWithLevel:BLoggingDebug LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogInfo(...) [BLogManager logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogWarn(...) [BLogManager logWithLevel:BLoggingWarn LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogError(...) [BLogManager logWithLevel:BLoggingError LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogFatal(...) [BLogManager logWithLevel:BLoggingFatal LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogErrorWithException(e, ...) [BLogManager logErrorWithException:e LOCATION_PARAMETERS message:__VA_ARGS__]
#define QSLogAssert(assertion, ...) [BLogManager assert:assertion LOCATION_PARAMETERS message:__VA_ARGS__]
