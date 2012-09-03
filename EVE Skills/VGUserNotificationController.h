//
//  VGUserNotificationController.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VGUserNotificationController : NSObject <NSUserNotificationCenterDelegate>

@property (nonatomic, readonly) dispatch_queue_t dispatchQueue;

- (void)reloadAllNotifications;

@end
