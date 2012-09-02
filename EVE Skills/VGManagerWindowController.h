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

// GUI
@property (strong) IBOutlet NSTableView *characterTableView;
@property (strong) IBOutlet NSTextField *hyperlinkTextField;

// Core Data
@property (nonatomic, strong, readonly) CoreDataController *coreDataController;
@property (nonatomic, strong, readonly) NSArray *tableSortDescriptors;
@property (strong) IBOutlet NSArrayController *characterArrayController;

// KVO
@property (strong) NSString *keyID;
@property (strong) NSString *vCode;
@property  BOOL animateProgress;
@property  BOOL authErrorHidden;

- (IBAction)deleteAction:(id)sender;
- (IBAction)queryAction:(id)sender;
- (IBAction)applyAction:(id)sender;
- (IBAction)showHelpPopover:(id)sender;

@end
