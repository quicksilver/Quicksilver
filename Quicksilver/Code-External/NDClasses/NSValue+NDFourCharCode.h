/*
	NSValue+NDFourCharCode.h

	Created by Nathan Day on 24.12.04 under a MIT-style license. 
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
	@header NSValue+NDFourCharCode.h
	@abstract Header file for the project  NDScriptData.
	@discussion Defines a category and private sub-class of the cluster class <tt>NSValue</tt> for dealing with sub types of <tt>FourCharCode</tt>
 
	Created by Nathan Day on 24/12/04.
	Copyright &#169; 2002 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

/*!
	@category NSValue(NDFourCharCode)
	@abstract Methods for creating instances of <tt>NSValue</tt> to represent any sub-types of <tt>FourCharCode</tt>.
	@discussion <tt>FourCharCode</tt> are simply <tt>unsigned long int</tt> but are usually represented as 4 <tt>char</tt>s for example <tt>'pnam'</tt>.
 */
@interface NSValue (NDFourCharCode)

/*!
	@method valueWithFourCharCode:
	@abstract Create a <tt>NSValue</tt> for a <tt>FourCharCode</tt>
	@discussion Creates and returns an <tt>NSValue</tt> object that contains the specified <tt><i>fourCharCode</i></tt> <tt>FourCharCode</tt> type (which represents a four char type).
	@param fourCharCode The four char code.
	@result A <tt>NSValue</tt>
 */
+ (NSValue *)valueWithFourCharCode:(FourCharCode)fourCharCode;

/*!
	@method valueWithOSType:
	 @abstract Create a <tt>NSValue</tt> for a <tt>OSType</tt>
	 @discussion Creates and returns an <tt>NSValue</tt> object that contains the specified <tt><i>anOSType</i></tt> <tt>OSType</tt> type. This is identical to <tt>+[NSValue valueWithFourCharCode:]</tt>.
	 @param anOSType The OSType.
	 @result A <tt>NSValue</tt>
	 */
+ (NSValue *)valueWithOSType:(OSType)anOSType;

/*!
	@method valueWithAEKeyword:
	@abstract Create a <tt>NSValue</tt> for a <tt>AEKeyword</tt>
	@discussion Creates and returns an <tt>NSValue</tt> object that contains the specified <tt><i>aeKeyword</i></tt> <tt>AEKeyword</tt> type (which represents a four-character code that uniquely identifies a descriptor record in an AE record or an Apple event). This is identical to <tt>+[NSValue valueWithFourCharCode:]</tt>.
	@param aeKeyword The key word.
	@result A <tt>NSValue</tt>
 */
+ (NSValue *)valueWithAEKeyword:(AEKeyword)aeKeyword;

/*!
	@method fourCharCode
	@abstract Return the <tt>FourCharCode</tt>
	@discussion Returns a <tt>FourCharCode</tt> type (which represents a four char type).
	@result The <tt>FourCharCode</tt>
 */
- (FourCharCode)fourCharCode;

/*!
	@method aeKeyword
	@abstract Return the <tt>AEKeyword</tt>
	@discussion Returns an <tt>AEKeyword</tt> type (which represents a four-character code that uniquely identifies a descriptor record in an AE record or an Apple event). This is identical to <tt>-[NSValue fourCharCode]</tt>.
	@result The <tt>AEKeyword</tt>
 */
- (AEKeyword)aeKeyword;

	/*!
	@method osType
	 @abstract Return the <tt>OSType</tt>
	 @discussion Returns an <tt>OSType</tt> type. This is identical to <tt>-[NSValue fourCharCode]</tt>.
	 @result The <tt>OSType</tt>
	 */
- (OSType)osType;

@end
