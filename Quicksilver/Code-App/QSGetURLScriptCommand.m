

#import "QSGetURLScriptCommand.h"
/*
#import "HLGetURLScriptCommand.h"
#import "HLCommand.h"
#import "HLConnectionMethod.h"

#define HLSAssert(condition, errno, desc) \
if (!(condition)) return [self scriptError: (errno) description: (desc)];
#define HLSAssert1(condition, errno, desc, arg1) \
if (!(condition)) return [self scriptError: (errno) description: \
    [NSString stringWithFormat: (desc), (arg1)]];
*/

@implementation QSGetURLScriptCommand

- (id)performDefaultImplementation {
    NSString *urlString = [self directParameter];
    [[NSApp delegate]openURL:[NSURL URLWithString: urlString]];
    return nil;
}
/*
- (id)scriptError:(int)errorNumber description:(NSString *)description {
    [self setScriptErrorNumber: errorNumber];
    [self setScriptErrorString: description];
    return nil;
}


// Perform somewhat redundant checks here.
// The NSScriptClassDescription should do this as well, but there may be
// pathological cases where it is unable to do so, someone has modified
// the script suite, etc.

- (id)performDefaultImplementation {
    NSString *command = [[self commandDescription] commandName];
    NSString *verb;
    NSString *urlString = [self directParameter];
    NSURL *url;
    HLConnectionMethod *method;
    
    // XXX should be read from .scriptTerminology, but Cocoa provides no way to do this
    if ([command isEqualToString: @"GetURL"]) {
        verb = @"get URL";
    } else if ([command isEqualToString: @"OpenURL"]) {
        verb = @"open URL";
    }
    HLSAssert1(verb != nil, errAEEventNotHandled,
               @"HostLauncher does not respond to R%@S.", command);
    
    // XXX should ignore arguments instead, if the GURL/OURL is coming from a Web browser?
    HLSAssert1([self arguments] == nil || [[self arguments] count] == 0, errAEParamMissed,
               @"CanUt handle arguments for %@", verb);
    HLSAssert(urlString != nil, errAEParamMissed, @"No URL to open was specified.");
    url = [NSURL URLWithString: urlString];
    // XXX CFURLCreateStringByAddingPercentEscapes is more permissive
    // wrt URL formats; may want to use it instead (see release notes)
    HLSAssert(url != nil, kURLInvalidURLError,
              @"URL format is invalid; must be fully qualified (scheme://host...).");
    
    method = [HLConnectionMethod methodForURL: url];
    
    HLSAssert1(method != nil, kURLUnsupportedSchemeError,
               @"URL scheme '%@' not supported", [url scheme]);
    
    HLSAssert1([method invoke], kURLExtensionFailureError,
               @"Unable to connect with URL R%@S", url);
    return nil;
}
*/
@end