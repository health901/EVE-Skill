//
//  VGCharacterSkillQueueCellView.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterSkillQueueCellView.h"
#import "VGAppDelegate.h"
#import "Character.h"
#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"

#define ARROW_SIZE 3

@interface VGCharacterSkillQueueCellView () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // Dispatch queue
//    dispatch_queue_t dispatchQueue;
    
    // Core Data
    NSManagedObjectContext *_moc;
    Character *_character;
    Queue *_queue;
    NSArray *_queueElementArray;
}

// Core Data
- (void)fetchQueue;

// Drawing
- (void)drawEmptyQueue;

@end

@implementation VGCharacterSkillQueueCellView

#pragma mark -
#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
    
    // Initializations
    _appDelegate = (VGAppDelegate *)[NSApp delegate];
    
    _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_moc setParentContext:_appDelegate.coreDataController.mainThreadContext];
    
    _character = nil;
    _queue = nil;
    _queueElementArray = nil;
    
    // Focus ring
//    [self setFocusRingType:NSFocusRingTypeNone];
//    [self.superview setFocusRingType:NSFocusRingTypeNone];
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:EVE_SKILLS_TIMER_TICK object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self setNeedsDisplayInRect:[self visibleRect]];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:SKILL_QUEUE_SHOULD_RELOAD_DATA_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self fetchQueue];
    }];
}

#pragma mark -
#pragma mark - Core Data

- (void)fetchQueue
{
    // Get the Queue associated with the Character
    [_moc performBlock:^{
        // If _character is nil, return immediately
        if (_character == nil) {
            return;
        }
        
        // objectValue is an NSString and not nil, we create a MOC and fetch the character's Queue
        
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Queue" inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", _character.characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Queue with characterID = '%@' : %@, %@",
                  _character.characterID, error, [error userInfo]);
        }
        
        // If there is no Queue object, we call the API
        if (fetchedObjects.count == 0) {
            NSLog(@"NOT IMPLEMENTED");
            abort();
        }
        
        // We found the queue object
        self->_queue = fetchedObjects.lastObject;
        
        if (self->_queue.elements != nil && self->_queue.elements.count > 0) {
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"position"
                                                                             ascending:YES];
            
            self->_queueElementArray = [self->_queue.elements.allObjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        }
    }];
}

#pragma mark -
#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Check if the character has changed
    if (_character != [(NSTableCellView *)self.superview objectValue]) {
        _character = [(NSTableCellView *)self.superview objectValue];
        _queue = nil;
        [self fetchQueue];
    }
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGFloat width = self.frame.size.width - 1;
    CGFloat height = self.frame.size.height - 1;
    
    BOOL arrowShaped = NO;
    
    // Draw the skills in the queue
    if (_queue != nil && _queue.elements != nil && _queue.elements.count > 0 && _queueElementArray){
        // Drawing
        CGFloat xPos = 0;
        
        for (int i = 0; i < _queueElementArray.count; i++) {
            QueueElement *queueElement = [_queueElementArray objectAtIndex:i];
            
            double timeInterval;
            if (i == 0) {
                timeInterval = [queueElement.endTime timeIntervalSinceDate:[NSDate date]];
            } else {
                timeInterval = [queueElement.endTime timeIntervalSinceDate:queueElement.startTime];
            }
            
            // width of the skill
            CGFloat skillWidth = width * timeInterval / (60*60*24);
            
            // get the color of the skill
            if (i % 2 == 0) {
                CGContextSetFillColorWithColor(context,
                                               [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"colorSkill1"]] CGColor]);
            } else {
                CGContextSetFillColorWithColor(context,
                                               [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"colorSkill2"]] CGColor]);
            }
            
            arrowShaped = xPos + skillWidth > width;
            
            if (arrowShaped) {
                // The skill is bigger than the rectangle, we draw a shape
                CGContextSaveGState(context);
                
                CGGradientRef gradient;
                size_t num_locations = 2;
                CGFloat locations[2] = { 0.0, 1.0 };
                CGFloat components[8] =
                    {1.0, 0.0, 0.0, 1,  // Start color
                     1.0, 0.0, 0.0, 0}; // End color
                
                gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), components, locations, num_locations);
                
                CGPoint start = CGPointMake(xPos, 0.0f);
                CGPoint end = CGPointMake(xPos, height);
                
                CGContextBeginPath(context);
                CGContextMoveToPoint(context, xPos, 0);
                CGContextAddLineToPoint(context, width - ARROW_SIZE , 0);
                CGContextAddLineToPoint(context, width              , height/2);
                CGContextAddLineToPoint(context, width - ARROW_SIZE , height);
                CGContextAddLineToPoint(context, xPos               , height);
//                CGContextFillPath(context);
                
                CGContextClip(context);
                
                CGContextDrawLinearGradient(context, gradient, start, end, 0) ;
                
                
//                CGContextDrawLinearGradient(context, glossGradient, topCenter, midCenter, 0);
                
                
                
                
                CGContextRestoreGState(context);
                
            } else {
                // fill the skill's rectangle
                CGContextFillRect(context, CGRectMake(xPos, 0.0, skillWidth, height));
                xPos += skillWidth;
            }
        }
    }
    
    CGFloat xShift = 0;
    CGFloat yShift = 0;
    
    // Draw the empty queue
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0);
    if (arrowShaped) {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, width - ARROW_SIZE + xShift, 0 + yShift);
        CGContextAddLineToPoint(context, width + xShift             , height/2 + yShift);
        CGContextAddLineToPoint(context, width - ARROW_SIZE + xShift, height + yShift);
        CGContextAddLineToPoint(context, 0 + xShift                 , height + yShift);
        CGContextAddLineToPoint(context, 0 + xShift                 , 0 + yShift);
        CGContextStrokePath(context);
    } else {
        CGContextStrokeRect(context, CGRectMake(0, 0, width, height));
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)drawEmptyQueue
{
    // Getting the drawing context
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0);
    CGContextStrokeRect(context, CGRectMake(0, 0, width, height));
}

@end
