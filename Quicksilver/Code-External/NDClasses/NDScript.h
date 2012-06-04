/*
	NDScript.h

	Created by Nathan Day on 07.01.06 under a MIT-style license. 
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
	@header NDScript.h
	@abstract Cocoa wrapper classes for AppleScripts
	@discussion The <i><tt>NDScript</tt></i> class are a set of class to provide Objective-C access to AppleScripts, it provides much more functionality than Apples own NSAppleScript and my previous NDAppleScriptObject. There are four main classes within NDScript, NDScriptData, NDScriptHandler, NDScriptContext and NDComponentInstance.
	<blockquote>
		<table>
			<tr>
				<td><tt><b>NDScriptData</b></tt></td>
				<td><tt>NDScriptData</tt> is the base class fo all script data, direct instances of NDScriptData represent simple data like numbers, strings, list and records</td>
			</tr>
			<tr>
				 <td><tt><b>NDScriptHandler</b></tt></td>
				 <td><tt>NDScriptHandler</tt> represents a script proceedure content, it does not have a context and so needs to be executed with a context to be executed</td>
			 </tr>
			 <tr>
				<td><tt><b>NDScriptContext</b></tt></td>
				<td>A script context represent everyting people normally associate with an AppleScript, it can contain handlers and properties. <tt>NDScriptContext</tt> is the class you use in place of NSAppleScript of NDAppleScriptObject</td>
			</tr>
			<tr>
				<td><tt><b>NDComponentInstance</b></tt></td>
				<td>This class represents a connection to a scripting component, for <tt>NDScriptData</tt> objects to be used together they have to use the same connection to the scripting component ie the same <tt>NDComponentInstance</tt>, though if one <tt>NDScriptData</tt> object is passed to another <tt>NDScriptData</tt> that has a different <tt>NDComponentInstance</tt> then the <tt>NDScriptData</tt> object is copied into the same <tt>NDComponentInstance</tt> and the copy is used instead.</td>
			</tr>
		</table>
	</blockquote>
	@related NDComponentInstance
	@related NDScriptData
	@related NDComponentInstance
	@version 1.0.0
	@updated 2005-05-31
 */
#import "NDScriptData_Protocols.h"
#import "NDComponentInstance.h"
#import "NDScriptData.h"
#import "NSValue+NDFourCharCode.h"
#import "NSAppleEventDescriptor+NDCoercion.h"


