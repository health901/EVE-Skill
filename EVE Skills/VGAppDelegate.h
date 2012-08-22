//
//  VGAppDelegate.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreDataController.h"
#import "VGAPIController.h"
#import "VGAppNotifications.h"
#import "VGUserNotificationController.h"

@interface VGAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readonly) CoreDataController *coreDataController;
@property (nonatomic, strong, readonly) VGAPIController *apiController;
@property (nonatomic, strong, readonly) VGUserNotificationController *userNotificationController;

- (void)openManagerWindow;

- (void)showMenuBarMenu;

@end
