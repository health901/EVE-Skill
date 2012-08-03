//
//  VGAppDelegate.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreDataController.h"

@interface VGAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong, readonly) CoreDataController *coreDataController;

@end
