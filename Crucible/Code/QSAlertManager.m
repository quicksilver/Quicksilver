

#import "QSAlertManager.h"




@implementation QSAlertManager
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)theReturnCode 
        contextInfo:(void *)contextInfo
{
    returnCode = theReturnCode;
    [NSApp stopModal];
}

- (int)returnCode
{       return returnCode;      }

@end



int QSRunSheet(id panel, NSWindow *attachToWin, NSString *title, 
               NSString *msg, NSString *defaultButton, NSString *alternateButton, 
               NSString *otherButton)
{
    QSAlertManager *obj = [[[QSAlertManager alloc]init]autorelease];
    
    [NSApp  beginSheet:panel
        modalForWindow:attachToWin
         modalDelegate:obj
        didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
           contextInfo:nil];
    [NSApp runModalForWindow:panel];
    [NSApp endSheet:panel];
//	QSLog(@"end");
    [panel orderOut:nil];
    
    NSReleaseAlertPanel(panel);
    
    return [obj returnCode];
}

NSLock *onlyOneAlertSheetAtATimeLock = nil;

int QSRunAlertSheet(NSWindow *attachToWin, NSString *title, NSString 
                    *msg, NSString *defaultButton, NSString *alternateButton, NSString 
                    *otherButton)
{
    if(onlyOneAlertSheetAtATimeLock == nil)
        onlyOneAlertSheetAtATimeLock = [[NSLock alloc] init];
    [onlyOneAlertSheetAtATimeLock lock];
    
    int returnVal = -1;
    if(attachToWin == nil)
        returnVal = NSRunAlertPanel(title, msg, defaultButton, 
                                    alternateButton, otherButton);
    else
    {
        id panel = NSGetAlertPanel(title, msg, defaultButton, 
                                   alternateButton, otherButton);
        returnVal = QSRunSheet(panel, attachToWin, title, msg, 
                               defaultButton, alternateButton, otherButton);
    }
    
    [onlyOneAlertSheetAtATimeLock unlock];
    return returnVal;
}

int QSRunInformationalAlertSheet(NSWindow *attachToWin, NSString 
                                 *title, NSString *msg, NSString *defaultButton, NSString 
                                 *alternateButton, NSString *otherButton)
{
    if(onlyOneAlertSheetAtATimeLock == nil)
        onlyOneAlertSheetAtATimeLock = [[NSLock alloc] init];
    [onlyOneAlertSheetAtATimeLock lock];
    
    int returnVal = -1;
    if(attachToWin == nil)
        returnVal = NSRunInformationalAlertPanel(title, msg, 
                                                 defaultButton, alternateButton, otherButton);
    else
    {
        id panel = NSGetInformationalAlertPanel(title, msg, 
                                                defaultButton, alternateButton, otherButton);
        returnVal = QSRunSheet(panel, attachToWin, title, msg, 
                               defaultButton, alternateButton, otherButton);
    }
    
    [onlyOneAlertSheetAtATimeLock unlock];
    return returnVal;
}

int QSRunCriticalAlertSheet(NSWindow *attachToWin, NSString *title, 
                            NSString *msg, NSString *defaultButton, NSString *alternateButton, 
                            NSString *otherButton)
{
    if(onlyOneAlertSheetAtATimeLock == nil)
        onlyOneAlertSheetAtATimeLock = [[NSLock alloc] init];
    [onlyOneAlertSheetAtATimeLock lock];
//            QSLog(@"win %@",attachToWin);
    int returnVal = -1;
    if(attachToWin == nil)
        returnVal = NSRunCriticalAlertPanel(title, msg, 
                                            defaultButton, alternateButton, otherButton);
    else
    {

        id panel = NSGetCriticalAlertPanel(title, msg, defaultButton, 
                                           alternateButton, otherButton);
        returnVal = QSRunSheet(panel, attachToWin, title, msg, 
                               defaultButton, alternateButton, otherButton);
    }
    
    [onlyOneAlertSheetAtATimeLock unlock];
    return returnVal;
}
