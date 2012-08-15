//
//  VGManagerWindowController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGManagerWindowController.h"
#import "VGAppDelegate.h"

@interface VGManagerWindowController () {
    VGAppDelegate *_appDelegate;
}

@end

@implementation VGManagerWindowController
@synthesize characterTableView = _characterTableView;
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
    
    // AppDelegate
    _appDelegate = (VGAppDelegate *)[NSApp delegate];
    
    // UI defaults
    self.authErrorHidden = YES;
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:APICALL_QUERY_DID_START_NOTIFICATION
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        self.animateProgress = YES;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:APICALL_QUERY_DID_END_NOTIFICATION
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        self.animateProgress = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                                      object:self.coreDataController.mainThreadContext
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.characterTableView reloadData];
                                                      
    }];
    
    
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
    dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
        [_appDelegate.apiController addAPIWithKeyID:self.keyID vCode:self.vCode];
    });
}

@end
