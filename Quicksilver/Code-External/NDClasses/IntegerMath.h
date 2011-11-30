/*
	IntegerMath.h

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

/*!
	@header IntegerMath.h
	@abstract Function to perform integer maths.
	@discussion Contains function that are integer version of float math opperations, e.g. <tt>log10I</tt> or function that are really only applicaple as integer opperations, e.g. <tt>greatestCommonDivisor</tt>

	Created by Nathan Day on Sun Jun 29 2003.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */

/*!
	@function log10I
	@abstract Returns the base 10 logarithm for <tt><i>num</i></tt>.
	@discussion <tt>log10I</tt> returns the largest integer less than 10 base logarithm of the unsigned long int <tt><i>num</i></tt>. It is equivelent to <code>(int)logf( num )</code>
	@param num The integer for which the logarithm is desired. 
	@result largest integer less than 10 base logarithm.
 */
unsigned short log10I( const unsigned long num );

/*!
	@function greatestCommonDivisor
	@abstract Return the greatest common divisor
	@discussion The function <tt>greatestCommonDivisor</tt> returns the greatest common divisor of the two integers <tt><i>a</i></tt> and <tt><i>b</i></tt>.
	@param a A <tt>unsigned long int</tt>
	@param b A <tt>unsigned long int</tt>
	@result The greatest common divisor.
 */
unsigned long greatestCommonDivisor( unsigned long a, unsigned long b );
