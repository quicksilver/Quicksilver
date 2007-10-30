#import <Cocoa/Cocoa.h>




@protocol NSServiceMasterProto
- objectForServicePath:fp8;
@end
@protocol NSServiceListenerProto
- (oneway void)serviceError:fp8 error:fp12;
- (char)invokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 menu:fp24 remoteServices:fp28;
- (char)invokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 error:(id *)fp24;
- (oneway void)asyncInvokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 menu:fp24 remoteServices:fp28 unhide:(char)fp32;
- _doInvokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 error:(id *)fp24 unhide:(char)fp28;
@end
@interface NSServiceMaster:NSObject 
{
    NSMutableDictionary *_localObjects;
    NSConnection *_cxn;
}
+ sharedServiceMaster;
- init;
- (void)dealloc;
- (void)registerObject:fp8 withServicePath:fp12;
- (void)unregisterObjectWithServicePath:fp8;
- serviceListener;
- objectForServicePath:fp8;
- objectForServicePath:fp8 app:fp12 doLaunch:(char)fp16 limitDate:fp20;
@end
@interface NSServiceListener:NSObject <NSServiceListenerProto>
{
    NSMutableArray *serviceProviders;
}
- (void)addServiceProvider:fp8;
- (void)removeServiceProvider:fp8;
- providerRespondingToSelector:(SEL)fp8;
- _doInvokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 error:(id *)fp24 unhide:(char)fp28;
- (int)invokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 error:(id *)fp24;
- (int)invokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 menu:fp24 remoteServices:fp28;
- (void)asyncInvokeServiceIn:fp8 msg:fp12 pb:fp16 userData:fp20 menu:fp24 remoteServices:fp28 unhide:(char)fp32;
- (void)serviceError:fp8 error:fp12;
@end