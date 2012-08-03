//
//  VGManagerWindowController.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VGAppDelegate.h"

@interface VGManagerWindowController : NSWindowController

// Core Data
@property (nonatomic, strong, readonly) CoreDataController *coreDataController;

// KVO
@property (strong) NSString *keyID;
@property (strong) NSString *vCode;
@property  BOOL animateProgress;
@property  BOOL authErrorHidden;

- (IBAction)queryAction:(id)sender;

@end
