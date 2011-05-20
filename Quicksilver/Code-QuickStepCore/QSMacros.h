#import <AvailabilityMacros.h>

#define ESS(x) (x == 1?@"":@"s")
//#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
//    #define foreach(x, y) id x; NSEnumerator *rwEnum = [y objectEnumerator]; while(x = [rwEnum nextObject])
//#else
//    // use fast enumeration on Mac OS X 10.5+
//    #define foreach(x, y) for (id (x) in (y)) 
//#endif
#define foreachkey(k, x, y) id x = nil; NSString *k = nil; NSEnumerator *kEnum = [y keyEnumerator]; while((k = [kEnum nextObject]) && (x = [y objectForKey:k]) )
#define defaultBool(x) [[NSUserDefaults standardUserDefaults] boolForKey:x]
#define mOptionKeyIsDown (GetCurrentKeyModifiers() &optionKey)
#define vLog(x) NSLog(@"x = %@", x)
#define DAYS 86400.0f
#define MINUTES 60.0f
#define HOURS 3600.0f
#define mSHARED_INSTANCE_CLASS_METHOD + (id)sharedInstance {static id _sharedInstance; if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init]; return _sharedInstance;}
#define QSLog(s, ...) \
[MLog logFile:__FILE__ lineNumber:__LINE__ \
	   format:(s), ##__VA_ARGS__]
