//
// NSException_TraceExtensions.m
// Quicksilver
//
// Created by Alcor on 7/20/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NSException_TraceExtensions.h"
#import <ExceptionHandling/NSExceptionHandler.h>

@implementation NSException (Tracing)

// printStackTrace adapted from http://code.google.com/p/j2objc/source/browse/jre_emul/Classes/NSException%2BStackTrace.m?r=1496c1c02d708c136e32b7c19907df621d01c8ad
// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  NSException+StackTrace.m
//  JreEmulation
//
//  Created by Tom Ball on 11/5/11.
//

- (void)printStackTrace {
    NSString *atosPath = @"/usr/bin/atos";
    if ([[NSFileManager defaultManager] fileExistsAtPath:atosPath]) {
        NSString *stack = [[self userInfo] objectForKey:NSStackTraceKey];
        
        if (stack != nil && ![stack isEqualToString:@"(null)"]) {
            NSString *pid = [[NSNumber numberWithInt:getpid()] stringValue];
            NSMutableArray *args = [NSMutableArray arrayWithCapacity:20];
            
            [args addObject:@"-p"];
            [args addObject:pid];
            
            // Function addresses are separated by double spaces.
            [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]];
            
            NSTask *task = [NSTask taskWithLaunchPath:atosPath
                                            arguments:args];
            
            // Fix for XCode bug from http://lists.apple.com/archives/xcode-users/2012/Sep/msg00023.html
            NSDictionary* environment = [[NSProcessInfo processInfo] environment] ;
            NSMutableDictionary* taskEnvironment = [[NSMutableDictionary alloc] init] ;
            for (NSString* key in environment) {
                if (![key hasPrefix:@"DYLD_"]) {
                    [taskEnvironment setObject:[environment valueForKey:key]
                                        forKey:key] ;
                }
            }
            [task setEnvironment:taskEnvironment] ;
            [taskEnvironment release];
            [task launch];
            [task waitUntilExit];
        }
    }
}
@end
