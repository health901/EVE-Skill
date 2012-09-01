//
//  VGSkillQueueQuery.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 16/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGSkillQueueQuery.h"
#import "VGAppDelegate.h"

#import "Queue.h"
#import "QueueElement.h"

@interface VGSkillQueueQuery () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // XML parsing
    NSXMLParser *_xmlParser;
    NSMutableString *_currentString;
    
    Queue *_currentQueue;
    QueueElement *_currentQueueElement;
    
    // Core Data stuff
    NSManagedObjectContext *_moc;
    
    // Completion handler
    void (^_completionHandler)(NSError *);
}

@end

@implementation VGSkillQueueQuery

#pragma mark -
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
    }
    return self;
}

- (id)initWithData:(NSData *)data
{
    self = [self init];
    if (self) {
        _xmlParser = [[NSXMLParser alloc] initWithData:data];
        _xmlParser.delegate = self;
    }
    return self;
}

#pragma mark -
#pragma mark - Public methods

- (void)readAndInsertDataInContext:(NSManagedObjectContext *)context
                 completionHandler:(void (^)(NSError *))completionHandler
{
    _moc = context;
    _completionHandler = completionHandler;
    [_xmlParser parse];
}

#pragma mark -
#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    // The rowset element represents the queue
    if ([elementName isEqualToString:@"rowset"]) {
        _currentQueue = [CoreDataController queueWithCharacterID:self.characterID
                                                       inContext:_moc
                                          notifyUserIfEmptyOrNil:NO];
        
        if (!_currentQueue) {
            // The queue for this characterID is not in the DB, we create it
            _currentQueue = [NSEntityDescription insertNewObjectForEntityForName:@"Queue"
                                                          inManagedObjectContext:_moc];
        } else {
            // The queue is already in the DB, we remove all QueueElement objects associated with it
            [_moc performBlockAndWait:^{
                for (QueueElement *element in _currentQueue.elements) {
                    [_moc deleteObject:element];
                }
            }];
        }
        
        // fill the attributes of the object
        _currentQueue.characterID = self.characterID;
    }
    
    // each 'row' element represents a skill in the skill queue
    if ([elementName isEqualToString:@"row"]) {
        // We always create a new object
        _currentQueueElement = [NSEntityDescription insertNewObjectForEntityForName:@"QueueElement"
                                                             inManagedObjectContext:_moc];
        
        // fill the attributes of the object
        NSDate *dateTmp = nil;
        dateTmp = [NSDate dateWithString:[NSString stringWithFormat:@"%@ +0000", attributeDict[@"startTime"]]];
        _currentQueueElement.startTime = (dateTmp ? dateTmp : [NSDate dateWithTimeIntervalSince1970:0]);
        dateTmp = [NSDate dateWithString:[NSString stringWithFormat:@"%@ +0000", attributeDict[@"endTime"]]];
        _currentQueueElement.endTime = (dateTmp ? dateTmp : [NSDate dateWithTimeIntervalSince1970:0]);
        _currentQueueElement.position = @([attributeDict[@"queuePosition"] intValue]);
        _currentQueueElement.skillLevel = @([attributeDict[@"level"] intValue]);
        _currentQueueElement.skillID = attributeDict[@"typeID"];
        
        _currentQueueElement.queue = _currentQueue;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!_currentString) {
        _currentString = [[NSMutableString alloc] init];
    }
    
    [_currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"error"]) {
        // the API query returned an error
        NSLog(@"The API query returned an error : %@", _currentString);
    }
    
    if ([elementName isEqualToString:@"cachedUntil"]) {
        NSDate *cachedUntilTmp = [NSDate dateWithString:[NSString stringWithFormat:@"%@ +0000",
                                                         _currentString]];
        _currentQueue.cachedUntil = cachedUntilTmp;
    }
    
    if (_currentString) {
        _currentString = nil;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    _completionHandler(nil);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    _completionHandler(parseError);
}
@end
