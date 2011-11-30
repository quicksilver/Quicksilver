/*
	NDProgrammerUtilities.h

	Created by Nathan Day on 01.05.04 under a MIT-style license. 
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
	@header NDProgrammerUtilities
	@abstract Collection of function to help with developement and testing.
	@discussion These function will by default display a message when an error condition occurs, this can be disabled by defining the macro varible <tt>NDTurnLoggingOff</tt>. Errors condition can be made to throw an <tt>NSInternalInconsistencyException</tt> by defining the macro varible <tt>NDAssertLogging</tt>.
	@copyright 2004 Nathan Day. All rights reserved.
*/

#include <Carbon/Carbon.h>
#include <Cocoa/Cocoa.h>

/*!
	@function NDLogFalseBody
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param CONDITION_ An expression that can is evaluated as <tt>YES</tt> or <tt>NO</tt>, evaluated only once. The macro varible <tt>NDTurnLoggingOff</tt> can be defined to turn off this message. The <tt>NSInternalInconsistencyException</tt> can be thrown instead by defining the macro varible <tt>NDAssertLogging</tt>.
	@result if <tt><i>CONDITION_</i></tt> evaluates to <tt>YES</tt> then <tt>NDLogFalseBody</tt> returns <tt>YES</tt> otherwise it return <tt>NO</tt>.
	@throws NSInternalInconsistencyException
 */
#ifdef NDTurnLoggingOff
#define NDLogFalse( CONDITION_ ) (CONDITION_)
#else
#define NDLogFalse( CONDITION_ ) NDLogFalseBody( (BOOL)( CONDITION_ ), __FILE__, __func__, __LINE__, # CONDITION_ )
#endif
BOOL NDLogFalseBody( const BOOL cond, const char * fileName, const char * funcName, const unsigned int line, const char * codeLine );

/*!
	@function NDLogOSStatus
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param OS_ERROR_ An expression that returns a <tt>OSStatus</tt>, evaluated only once. The macro varible <tt>NDTurnLoggingOff</tt> can be defined to turn off this message. The <tt>NSInternalInconsistencyException</tt> can be thrown instead by defining the macro varible <tt>NDAssertLogging</tt>.
	@result if <tt><i>OS_ERROR_</i></tt> evaluates to <tt>noErr</tt> then <tt>NDLogOSStatus</tt> returns <tt>YES</tt> otherwise it return <tt>NO</tt>.
	@throws NSInternalInconsistencyException
 */
#ifdef NDTurnLoggingOff
#define NDLogOSStatus( OS_ERROR_ ) ((OS_ERROR_) == noErr)
#else
#define NDLogOSStatus( OS_ERROR_ ) NDLogOSStatusBody( (OS_ERROR_), __FILE__, __func__, __LINE__, # OS_ERROR_, NULL )
#endif
BOOL NDLogOSStatusBody( const OSStatus anError, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine, NSString*(*aErrToStringFunc)(const OSStatus) );

/*!
	@function NDUntestedMethod
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
#ifdef NDTurnLoggingOff
#define NDUntestedMethod( )
#else
#define NDUntestedMethod( ) NDUntestedMethodBody( __FILE__, __func__, __LINE__ )
void NDUntestedMethodBody( const char * fileName, const char * funcName, const unsigned int line );
#endif

/*!
	@function NDSoftParamAssert
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
#ifdef NDTurnLoggingOff
#define NDSoftParamAssert( CONDITION_, ... ) if( !(CONDITION_) ) return __VA_ARGS__;
#else
#define NDSoftParamAssert( CONDITION_, ... ) if( NDSoftParamAssertBody( !( CONDITION_ ), __FILE__, __func__, __LINE__, # CONDITION_ )  ) return __VA_ARGS__;
BOOL NDSoftParamAssertBody( const BOOL cond, const char * fileName, const char * funcName, const unsigned int line, const char * codeLine );
#endif
