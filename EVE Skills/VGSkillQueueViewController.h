//
//  VGSkillQueueViewController.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 15/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VGAppDelegate.h"

@interface VGSkillQueueViewController : NSViewController

// GUI
@property (strong) IBOutlet NSTableView *characterTableView;

// Core Data
@property (nonatomic, strong, readonly) CoreDataController *coreDataController;
@property (nonatomic, strong, readonly) NSArray *tableSortDescriptors;


@end
