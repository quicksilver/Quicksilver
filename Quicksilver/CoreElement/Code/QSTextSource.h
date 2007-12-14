
@interface QSTextActions : QSActionProvider
{
	
}
+(OSStatus)InitAscii2KeyCodeTable;
-(short)AsciiToKeyCode:(short)asciiCode;
-(void)typeString:(NSString *)string;
-(void)typeString2:(NSString *)string;

	
@end


