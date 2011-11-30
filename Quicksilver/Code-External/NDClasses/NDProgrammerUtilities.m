/*
	NDProgrammerUtilities.m

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

#include "NDProgrammerUtilities.h"

BOOL NDLogFalseBody( const BOOL aCond, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine )
{
#ifdef NDAssertLogging
	if( aCond == NO )
		[[NSException raise:NSInternalInconsistencyException format:@"[%@] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [NSDate date], aFuncName, aCodeLine, aFileName, aLine];
#else
	if( aCond == NO )
		fprintf( stderr, "[%s] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [[[NSDate date] description] UTF8String], aFuncName, aCodeLine, aFileName, aLine );
#endif

	return aCond;
}

BOOL NDLogOSStatusBody( const OSStatus anError, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine, NSString*(*aErrToStringFunc)(const OSStatus) )
{
#ifdef NDAssertLogging
	if( anError != noErr )
		[NSException raise:NSInternalInconsistencyException format:@"Error result [%@] OSStatus %ld:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [NSDate date], anError, aCodeLine, aFileName, aFuncName, aLine];
#else
	if( anError != noErr )
	{
		if( aErrToStringFunc != NULL )
			fprintf( stderr, "Error result [%s] OSStatus %d:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u\n\tdescription: %s\n", [[[NSDate date] description] UTF8String], anError, aCodeLine, aFileName, aFuncName, aLine, [aErrToStringFunc(anError) UTF8String] );
		else
			fprintf( stderr, "Error result [%s] OSStatus %d:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u\n", [[[NSDate date] description] UTF8String], anError, aCodeLine, aFileName, aFuncName, aLine );
	}
#endif

	return anError == noErr;
}

#ifndef NDTurnLoggingOff
void NDUntestedMethodBody( const char * aFileName, const char * aFuncName, const unsigned int aLine )
{
	fprintf( stderr, "WARRING: The function %s has not been tested\n\tfile: %s\n\tline: %u.\n", aFileName, aFuncName, aLine );
}
#endif
		 
BOOL NDSoftParamAssertBody( const BOOL aCond, const char * aFileName, const char * aFuncName, const unsigned int aLine, const char * aCodeLine )
{
#ifdef NDAssertLogging
	if( aCond == NO )
		[[NSException raise:NSInternalInconsistencyException format:@"[%@] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [NSDate date], aFuncName, aCodeLine, aFileName, aLine];
#else
	if( aCond == NO )
		fprintf( stderr, "[%s] Condition false:\n\t%s\n\tfile: %s\n\tfunction: %s\n\tline: %u.\n", [[[NSDate date] description] UTF8String], aFuncName, aCodeLine, aFileName, aLine );
#endif

	return aCond;
}
