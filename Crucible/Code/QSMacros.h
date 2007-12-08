#define ESS(x) (x==1?@"":@"s")
#define foreach(x,y) for (id x in y) 
//id x;NSEnumerator *rwEnum=[y objectEnumerator];while(x=[rwEnum nextObject])
#define foreachr(x,y) id x;NSEnumerator *rwEnum=[y reverseObjectEnumerator];while(x=[rwEnum nextObject])
#define foreachkey(k,x,y) id x=nil;NSString *k=nil;NSEnumerator *kEnum=[y keyEnumerator];while((k=[kEnum nextObject]) && (x=[y objectForKey:k]))
#define defaultBool(x) [[NSUserDefaults standardUserDefaults]boolForKey:x]
#define mOptionKeyIsDown (GetCurrentKeyModifiers()&optionKey)
#define vLog(x) QSLog(@"x=%@",x)
#define DAYS 86400.0f
#define MINUTES 60.0f
#define HOURS 3600.0f
#define mSHARED_INSTANCE_CLASS_METHOD \
+ (id)sharedInstance{ \
	static id _sharedInstance = nil; \
	 @synchronized(self) { \
	if (!_sharedInstance)  \
		_sharedInstance = [[self allocWithZone:[self zone]] init]; \
	}\
	return _sharedInstance; \
}



