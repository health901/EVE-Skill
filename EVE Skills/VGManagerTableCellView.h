//
//  VGManagerTableCellView.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 21/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Portrait.h"
#import "Corporation.h"

@interface VGManagerTableCellView : NSTableCellView

@property (strong) Corporation *corporation;
@property (strong) Portrait *portrait;

@end
