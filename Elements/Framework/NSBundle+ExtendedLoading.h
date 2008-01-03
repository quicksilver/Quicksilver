/**
 *  @file NSBundle+ExtendedLoading.h
 *  @brief Extended loading category on NSBundle
 *
 *  QSElements
 *  
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

/**
 *  @brief Extended Loading Category on NSBundle
 */
@interface NSBundle (ExtendedLoading)
/**
 *  @brief Register a bundle's defaults at loading.
 */
- (BOOL)registerDefaults;
@end
