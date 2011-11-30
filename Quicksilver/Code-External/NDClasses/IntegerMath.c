/*
	IntegerMath.c

	Created by Nathan Day on 29.06.03 under a MIT-style license. 
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

#include "IntegerMath.h"

unsigned short log10I( const unsigned long aValue )
{
	unsigned short		theExp = 0;
	unsigned long		theCmpValue[] = {10U,100U,1000U,10000U,100000U,1000000U,10000000U,100000000U,1000000000U};
	
	while( aValue >= theCmpValue[theExp] && theExp < sizeof(theCmpValue)/sizeof(unsigned long int) )
		theExp++;

	return theExp;
}

unsigned long greatestCommonDivisor( unsigned long a, unsigned long b )
{
	return b == 0 ? a : greatestCommonDivisor( b, a%b);
}

