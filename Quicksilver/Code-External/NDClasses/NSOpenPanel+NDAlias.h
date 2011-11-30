/*
	NSOpenPanel+NDAlias.h

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
	@header NSOpenPanel+NDAlias
	@abstract Decalres the category <tt>NSOpenPanel (NDAlias)</tt>
	@discussion Thanks to Sean McBride for providing this 
	@date Thursday August 16 2007
	@author Sean McBride
 */

#import <Cocoa/Cocoa.h>
#import "NDSDKCompatibility.h"

/*!
	@category NSOpenPanel(NDAlias)
	@abstract Additional methods of <tt>NSOpenPanel</tt> to deal with <tt>NDAlias</tt> instances.
	@discussion Adds the single method <tt>aliases</tt>
 */
@interface NSOpenPanel (NDAlias)

/*!
	@method aliases
	@abstract Returns an array containing aliases to the selected files and directories.
	@discussion If multiple selections aren’t allowed, the array contains a single alias. The <tt>aliases</tt> works in a similiar way to -[NSOpenPanel filenames].
	@result <tt>NSArray</tt> of <tt>NDAlias<//t>
  */
- (NSArray *)aliases;

@end
