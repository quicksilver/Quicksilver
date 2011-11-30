/*
	NSSavePanel+NDAlias.h

	Created by Sean McBride on 18.08.07 under a MIT-style license. 
	Copyright (c) 2008-2009 Nathan Day

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
	@header NSSavePanel+NDAlias
	@abstract Decalres the category <tt>NSSavePanel (NDAlias)</tt>
	@discussion Thanks to Sean McBride for providing this 
	@date Thursday March 18 2008
	@author Sean McBride
 */

#import <Cocoa/Cocoa.h>
#import "NDSDKCompatibility.h"

@class NDAlias;

/*!
	@category NSSavePanel(NDAlias)
	@abstract Additional methods of <tt>NSSavePanel</tt> to deal with <tt>NDAlias</tt> instances.
	@discussion Adds the methods <tt>directoryAlias</tt> and <tt>setDirectoryAlias</tt>.
 */
@interface NSSavePanel (NDAlias)

/*!
	@method directoryAlias
	@abstract Returns an NDAlias of the directory currently shown in the receiver.
	@discussion Works in a similiar way to -[NSSavePanel directory].
	@result <tt>NDAlias<//t>
  */
- (NDAlias *)directoryAlias;

/*!
	@method setDirectoryAlias
	@abstract Sets the current directory currently shown in the receiver to the alias given. Does nothing if the alias cannot be resolved.
	@discussion Works in a similiar way to -[NSSavePanel setDirectory].
	@result
  */
- (void)setDirectoryAlias:(NDAlias*)alias;

@end
