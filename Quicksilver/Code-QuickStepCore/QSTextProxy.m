

#import "QSTextProxy.h"

#import "QSObject_PropertyList.h"

@implementation QSObject (TextProxy)
+ (id)textProxyObjectWithDefaultValue:(NSString *)string{
	QSObject *object=[self objectWithType:QSTextProxyType value:string name:@""];
	[object setIcon:[[NSWorkspace sharedWorkspace]iconForFileType:@"'clpt'"]];
	return object;
}
@end
