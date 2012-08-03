//
//  VGManagerWindowController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGManagerWindowController.h"
#import "VGAppDelegate.h"

@interface VGManagerWindowController ()

@end

@implementation VGManagerWindowController
@synthesize coreDataController = _coreDataController;
@synthesize keyID = _keyID;
@synthesize vCode = _vCode;
@synthesize animateProgress = _animateProgress;
@synthesize authErrorHidden = _authErrorHidden;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // FIXME : temporary debug values
    self.keyID = @"1161457";
    self.vCode = @"P1DO18zfr5KNQ6E1HBXrPdaffDOg3FEcTflyx5anw144dDp7VGff9FL12mAjzoE4";
}

#pragma mark -
#pragma mark - CoreDataController

- (CoreDataController *)coreDataController
{
    if (!_coreDataController) {
        _coreDataController = ((VGAppDelegate *)[NSApp delegate]).coreDataController;
    }
    return _coreDataController;
}

#pragma mark -
#pragma mark - IBActions

- (void)queryAction:(id)sender
{
    
}

@end
