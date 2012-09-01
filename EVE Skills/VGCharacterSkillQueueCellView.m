//
//  VGCharacterSkillQueueCellView.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterSkillQueueCellView.h"
#import "VGAppDelegate.h"
#import "VGSkillDetailViewController.h"
#import "Character.h"
#import "Queue+VGEVE.h"
#import "QueueElement+VGEVE.h"

#define ARROW_SIZE 3

@interface VGCharacterSkillQueueCellView () {
    // Mouse tracking
    NSTrackingArea *_trackingArea;
    
    // Popover
    VGSkillDetailViewController *_skillDetailViewController;
    NSPopover *_skillDetailPopover;
}

@property (strong, nonatomic) VGAppDelegate *appDelegate;
@property (strong, nonatomic) NSManagedObjectContext *moc;
@property (strong, nonatomic) NSArray *queueElementArrayOrdered;

@property (strong, nonatomic) NSMutableDictionary *skillDict;

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
    
    
    
    // Mouse tracking
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp)
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
    
    // Popover
    _skillDetailViewController = [[VGSkillDetailViewController alloc] initWithNibName:@"VGSkillDetailViewController" bundle:nil];
    _skillDetailPopover = [[NSPopover alloc] init];
    _skillDetailPopover.contentViewController = _skillDetailViewController;
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:EVE_SKILLS_TIMER_TICK object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self setNeedsDisplayInRect:[self visibleRect]];
    }];
}

#pragma mark -
#pragma mark - Mouse tracking

- (void)mouseEntered:(NSEvent *)theEvent
{
    // Search for the Skill and QueueElement under the mouse pointer
    if (self.queue != nil && self.queue.elements != nil && self.queue.elements.count > 0 && self.queueElementArrayOrdered){
        
        CGFloat width = self.frame.size.width - 1;
        CGFloat height = self.frame.size.height - 1;
        CGFloat xPos = 0;
        
        NSPoint point = theEvent.locationInWindow;
        
        for (int i = 0; i < self.queueElementArrayOrdered.count; i++) {
            QueueElement *queueElement = self.queueElementArrayOrdered[i];
            
            double timeInterval;
            if (i == 0) {
                timeInterval = [queueElement.endTime timeIntervalSinceDate:[NSDate date]];
            } else {
                timeInterval = [queueElement.endTime timeIntervalSinceDate:queueElement.startTime];
            }
            
            // width of the skill
            CGFloat skillWidth = width * timeInterval / (60*60*24);
            
            if (point.x >= xPos && point.x < xPos + skillWidth) {
                // Search for the associated skill and display the popover
                [self.moc performBlock:^{
                    _skillDetailViewController.skill = nil;
                    _skillDetailViewController.queueElement = nil;
                    
                    // Search for the skill
                    _skillDetailViewController.skill = self.skillDict[queueElement.skillID];
                    
                    if (self.skillDict[queueElement.skillID] == nil) {
                        Skill *skill = [CoreDataController skillWithSkillID:queueElement.skillID
                                                                  inContext:_moc
                                                     notifyUserIfEmptyOrNil:YES];
                        
                        self.skillDict[queueElement.skillID] = skill;
                        _skillDetailViewController.skill = skill;
                    }
                    
                    _skillDetailViewController.queueElement = queueElement;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        // Display the popover
                        [_skillDetailPopover showRelativeToRect:CGRectMake(xPos, 0.0, skillWidth, height)
                                                         ofView:self
                                                  preferredEdge:NSMinYEdge];
                    });
                }];
                
                return;
            }
            
            xPos += skillWidth;
        }
        
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [_skillDetailPopover performClose:self];
}

#pragma mark -
#pragma mark - Core Data

- (VGAppDelegate *)appDelegate
{
    if (_appDelegate == nil) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
    }
    
    return _appDelegate;
}

- (NSManagedObjectContext *)moc
{
    if (_moc == nil) {
        _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_moc setParentContext:self.appDelegate.coreDataController.mainThreadContext];
    }
    
    return _moc;
}

- (NSArray *)queueElementArrayOrdered
{
    if (self.queue == nil) {
        _queueElementArrayOrdered = nil;
        return nil;
    }
    
    if (_queueElementArrayOrdered == nil) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        _queueElementArrayOrdered = [self.queue.elements sortedArrayUsingDescriptors:@[sortDescriptor]];
    }
    
    return _queueElementArrayOrdered;
}

- (NSMutableDictionary *)skillDict
{
    if (_skillDict == nil) {
        _skillDict = [@{} mutableCopy];
    }
    
    return _skillDict;
}

#pragma mark -
#pragma mark - Queue

- (void)setQueue:(Queue *)queue
{
    [self willChangeValueForKey:@"queue"];
    _queue = queue;
    _queueElementArrayOrdered = nil;
    [self didChangeValueForKey:@"queue"];
    
    [self setNeedsDisplayInRect:[self visibleRect]];
}

#pragma mark -
#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGFloat width = self.frame.size.width - 1;
    CGFloat height = self.frame.size.height - 1;
    
    BOOL arrowShaped = NO;
    
    // Draw the skills in the queue
    if (self.queue != nil && self.queue.elements != nil && self.queue.elements.count > 0 && self.queueElementArrayOrdered){
        // Drawing
        CGFloat xPos = 0;
        
        for (int i = 0; i < self.queueElementArrayOrdered.count; i++) {
            QueueElement *queueElement = self.queueElementArrayOrdered[i];
            
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
            
//            arrowShaped = xPos + skillWidth > width;
            arrowShaped = NO;
            
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
