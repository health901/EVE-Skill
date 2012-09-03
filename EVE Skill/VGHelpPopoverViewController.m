//
//  VGHelpPopoverViewController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/09/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGHelpPopoverViewController.h"

@interface VGHelpPopoverViewController ()

@end

@implementation VGHelpPopoverViewController
@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    // Load text from the Help file
    NSString *rtfdPath = [[NSBundle mainBundle] pathForResource:@"APIHelp" ofType:@"rtf"];
    [self.textView readRTFDFromFile:rtfdPath];
}

@end
