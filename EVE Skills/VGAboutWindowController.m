//
//  VGAboutWindowController.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 02/09/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGAboutWindowController.h"

@interface VGAboutWindowController ()

@end

@implementation VGAboutWindowController
@synthesize textView;

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
    
    // Load text from the Credits file
    NSString *rtfdPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtfd"];
    [self.textView readRTFDFromFile:rtfdPath];
}

@end
