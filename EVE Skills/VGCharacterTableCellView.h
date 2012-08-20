//
//  VGCharacterTableCellView.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 20/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VGCharacterSkillQueueCellView.h"

@interface VGCharacterTableCellView : NSTableCellView

// KVO
@property (strong) NSString *currentSkillName;
@property (strong) NSString *timeRemaining;

// Outlets
@property (strong) IBOutlet VGCharacterSkillQueueCellView *skillQueueView;

@end
