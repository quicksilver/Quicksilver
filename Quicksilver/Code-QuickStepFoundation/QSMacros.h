#define foreachkey(k, x, y) id x = nil; NSString *k = nil; NSEnumerator *kEnum = [y keyEnumerator]; while((k = [kEnum nextObject]) && (x = [y objectForKey:k]) )
#define defaultBool(x) [[NSUserDefaults standardUserDefaults] boolForKey:x]
#define mOptionKeyIsDown (GetCurrentKeyModifiers() &optionKey)
#define vLog(x) NSLog(@"x = %@", x)
#define DAYS 86400.0f
#define MINUTES 60.0f
#define HOURS 3600.0f
#define QSLog(s, ...) \
[MLog logFile:__FILE__ lineNumber:__LINE__ \
	   format:(s), ##__VA_ARGS__]

#define SuppressPerformSelectorLeakWarning(Code) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Code; \
_Pragma("clang diagnostic pop") \
} while (0)

//#define QS_DEPRECATED __attribute__((deprecated))
//#define QS_DEPRECATED_MSG(s) __attribute__((deprecated(s)))

