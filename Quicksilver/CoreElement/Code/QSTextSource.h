
typedef struct {
    short kchrID;
    Str255 KCHRname;
    short transtable[256];
} Ascii2KeyCodeTable;
enum {
    kTableCountOffset = 256+2,
    kFirstTableOffset = 256+4,
    kTableSize = 128
};

@interface QSTextActions : QSActionProvider
{
	
}
+(OSStatus)InitAscii2KeyCodeTable;
-(short)AsciiToKeyCode:(short)asciiCode;
-(void)typeString:(NSString *)string;
-(void)typeString2:(NSString *)string;

	
@end


