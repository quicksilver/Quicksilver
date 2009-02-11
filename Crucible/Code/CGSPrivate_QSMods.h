extern CGError CGSRegisterConnectionNotifyProc(const CGSConnection cid,
                                               CGConnectionNotifyProc function,
                                               CGSConnectionNotifyEvent event,
                                               void* userParameter);

#pragma mark Hotkeys
    
typedef enum {
    CGSGlobalHotKeyEnable = 0,
    CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;
    
extern CGError CGSGetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode *mode);
    
extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode mode);

// Contexts
extern void CGContextSetCompositeOperation(CGContextRef context, int unknown);
