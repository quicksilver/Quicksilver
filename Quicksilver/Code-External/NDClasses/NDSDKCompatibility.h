/*
	NDSDKCompatibility.h

	Created by Nick Zitzmann on 2007-10-22 as a contrbution to NDAlias under a MIT-style license.
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

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
