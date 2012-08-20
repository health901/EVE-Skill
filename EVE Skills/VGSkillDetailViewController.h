//
//  VGSkillDetailViewController.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Skill.h"
#import "QueueElement.h"

@interface VGSkillDetailViewController : NSViewController

@property (strong) Skill *skill;
@property (strong) QueueElement *queueElement;

@property (strong) NSString *timerString;

@end
