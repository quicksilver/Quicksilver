//
//  NSException_TraceExtensions.m
//  Quicksilver
//
//  Created by Alcor on 7/20/04.

//

#import "NSException_TraceExtensions.h"

#import <ExceptionHandling/NSExceptionHandler.h>

@implementation NSException (Tracing)
- (void)printStackTrace
{

    NSString *stackTrace = [[self userInfo] objectForKey:NSStackTraceKey];
	if (!stackTrace) return;
	
    NSString *str = [NSString stringWithFormat:@"/usr/bin/atos -p %d %@ | tail -n +3 | head -n +%d | c++filt | cat -n",
        [[NSProcessInfo processInfo] processIdentifier],
        stackTrace,
        ([[stackTrace componentsSeparatedByString:@"  "] count] - 4)];
    FILE *file = popen( [str UTF8String], "r" );
	
    if( file )
    {
        char buffer[512];
        size_t length;
		
        fprintf( stderr, "An exception of type %s occured.\n%s\n", [[self name] UTF8String], [[self reason] UTF8String] );
        fprintf( stderr, "Stack trace:\n" );
		
        while( ( length = fread( buffer, 1, sizeof( buffer ), file ) ) )
        {
            fwrite( buffer, 1, length, stderr );
        }
		
        pclose( file );
    }
}
@end
