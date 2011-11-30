/*
	NSPathControl+NDAlias.h

	Created by Sean McBride on 16.08.07 under a MIT-style license. 
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
	@header NSPathControl+NDAlias.h
	@abstract Decalres the category <tt>NSPathControl (NDAlias)</tt>
	@discussion Thanks to Sean McBride for providing this 
	@date Thursday August 16 2007
	@author Sean McBride
 */

#import <Cocoa/Cocoa.h>
#import "NDSDKCompatibility.h"

@class NDAlias;

/*!
	@category NSPathControl(NDAlias)
	@abstract Additional meethods of <tt>NSPathControl</tt> to deal with <tt>NDAlias</tt> instances.
	@discussion Adds three methods to <tt>NSPathControl</tt>
	@author Sean McBride
	@date Saturday, 16 August 2007
 */
@interface NSPathControl (NDAlias)

/*!
	@method path
	@abstract Returns the path value displayed by the receiver.
	@discussion <tt>path</tt> is equivelent to <tt>-[NSPathControl URL]</tt> but returning a POSIX path <tt>NSString</tt>
	@author Sean McBride
	@date Saturday, 16 August 2007
	@result A POSIX path.
 */
- (NSString*)path;

/*!
	@method alias
	@abstract Returns the path value displayed by the receiver as an alias.
	@discussion <tt>alias</tt> is equivelent to <tt>-[NSPathControl URL]</tt> but returning a <tt>NDAlias</tt>
	@author Sean McBride
	@date Saturday, 16 August 2007
	@result A <tt>NDAlias</tt>.
 */
- (NDAlias*)alias;

/*!
	@method setAlias:
	@abstract Sets the path value displayed by the receiver.
	@discussion <#discussion#>
	@author Sean McBride
	@date Saturday, 16 August 2007
	@param alias <#result#>
 */
- (void)setAlias:(NDAlias*)alias;

@end
