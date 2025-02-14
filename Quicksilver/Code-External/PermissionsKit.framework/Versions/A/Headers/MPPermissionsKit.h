//
//  MPPermissionsKit.h
//  PermissionsKit
//
//  Created by Sergii Kryvoblotskyi on 9/12/18.
//  Copyright © 2018 MacPaw. All rights reserved.
//

@import Foundation;

#import <PermissionsKit/MPPermissionType.h>
#import <PermissionsKit/MPAuthorizationStatus.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PermissionsKit)
@interface MPPermissionsKit : NSObject

/**
 * Requests current authorization status for a given type.
 *
 * @discussion It is safe to call this method on system where permission type is not supported. MPAuthorizationStatusAuthorized will be returned.
 *
 * @param permissionType MPPermissionType
 * @return MPAuthorizationStatus
 */
+ (MPAuthorizationStatus)authorizationStatusForPermissionType:(MPPermissionType)permissionType;

/**
 * Requests user authorization for a given permission. Completion will be invoked with a user decision. Completion queue is undefined.
 * @discussion There will be no completion when requesting MPPermissionTypeFullDiskAccess, because its status is unknown. You should implement your own callback mechanism, for example - polling authorization. It is safe to call this method on system where permission type is not supported. MPAuthorizationStatusAuthorized will be returned.
 *
 * @param permissionType MPPermissionType
 * @param completionHandler void (^)(MPAuthorizationStatus status)
 */
+ (void)requestAuthorizationForPermissionType:(MPPermissionType)permissionType withCompletion:(void (^)(MPAuthorizationStatus status))completionHandler;

@end

NS_ASSUME_NONNULL_END
