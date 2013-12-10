

#import <Foundation/Foundation.h>

# define kFileOpenAction @"FileOpenAction"
# define kFileOpenWithAction @"FileOpenWithAction"
# define kFileAlwaysOpenWithAction @"FileAlwaysOpenWithAction"


# define kAppOpenFileAction @"AppOpenFileAction"
# define kFileRevealAction @"FileRevealAction"
# define kFileRenameAction @"FileRenameAction"
# define kFileMoveToAction @"FileMoveToAction"
# define kFileCopyToAction @"FileCopyToAction"
# define kFileMakeLinkInAction @"FileMakeLinkInAction"
# define kFileMakeAliasInAction @"FileMakeAliasInAction"

# define kFileDeleteAction @"FileDeleteAction"
# define kFileToTrashAction @"FileToTrashAction"
# define kFileGetPathAction @"FileGetPathAction"
# define kFileGetInfoAction @"FileGetInfoAction"


@interface FSActions : QSActionProvider {
}
- (BOOL)filesExist:(NSArray *)paths;
- (QSObject *)moveFiles:(QSObject *)dObject toFolder:(QSObject *)iObject;
- (QSObject *)copyFiles:(QSObject *)dObject toFolder:(QSObject *)iObject NS_RETURNS_NOT_RETAINED;
- (QSObject *)moveFiles:(QSObject *)dObject toFolder:(QSObject *)iObject shouldCopy:(BOOL)copy;
@end
@interface FSDiskActions : QSActionProvider
@end
@interface URLActions : QSActionProvider <QSProxyObjectProvider> {
}
- (void)performJavaScript:(NSString *)jScript;
@end

@interface EditorActions : QSActionProvider
@end

@interface AppActions : QSActionProvider
@end

@interface ClipboardActions : QSActionProvider
-(QSObject *)pasteObject:(QSObject *)dObject;
-(QSObject *)pasteObjectAsPlainText:(QSObject *)dObject;
-(QSObject *)pasteObject:(QSObject *)dObject asPlainText:(BOOL)plainText;
@end


