//
//  MPAuthorizationStatus.h
//  PermissionsKit
//
//  Created by Sergii Kryvoblotskyi on 9/12/18.
//  Copyright © 2018 MacPaw. All rights reserved.
//

typedef NS_ENUM(NSUInteger, MPAuthorizationStatus) {
    MPAuthorizationStatusNotDetermined,
    MPAuthorizationStatusDenied,
    MPAuthorizationStatusAuthorized,
	MPAuthorizationStatusLimited API_AVAILABLE(macos(10.11))
} NS_SWIFT_NAME(AuthorizationStatus);
