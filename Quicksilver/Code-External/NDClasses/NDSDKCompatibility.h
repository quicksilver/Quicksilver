/*
	NDSDKCompatibility.h

	Created by Nick Zitzmann on 2007-10-22.


	NDAlias uses types that were introduced with the 10.5 SDK.
	This allows older SDKs to be used.
 */

#import <Foundation/Foundation.h>

#ifndef NSINTEGER_DEFINED
	#ifdef NS_BUILD_32_LIKE_64
		typedef long NSInteger;
		typedef unsigned long NSUInteger;
	#else
		typedef int NSInteger;
		typedef unsigned int NSUInteger;
	#endif
	#define NSIntegerMax    LONG_MAX
	#define NSIntegerMin    LONG_MIN
	#define NSUIntegerMax   ULONG_MAX
	#define NSINTEGER_DEFINED 1
#endif

#ifndef CGFLOAT_DEFINED
	typedef float CGFloat;
	#define CGFLOAT_MIN FLT_MIN
	#define CGFLOAT_MAX FLT_MAX
	#define CGFLOAT_IS_DOUBLE 0
	#define CGFLOAT_DEFINED 1
#endif
