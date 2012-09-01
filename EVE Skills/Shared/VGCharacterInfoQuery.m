//
//  VGCharacterInfoQuery.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 22/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGCharacterInfoQuery.h"
#import "VGAppDelegate.h"

@interface VGCharacterInfoQuery () {
    // Core Data
    NSManagedObjectContext *_moc;
    
    // XML parsing
    NSXMLParser *_xmlParser;
    NSMutableString *_currentString;
    
    Corporation *_currentCorporation;
    
    // Completion handler
    void (^_completionHandler)(NSError *, Corporation *);
}

@property (strong, nonatomic) VGAppDelegate *appDelegate;

@end

@implementation VGCharacterInfoQuery

#pragma mark -
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        
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

- (VGAppDelegate *)appDelegate
{
    if (_appDelegate == nil) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
    }
    
    return _appDelegate;
}

#pragma mark -
#pragma mark - Public methods

- (void)readAndInsertDataInContext:(NSManagedObjectContext *)context
                 completionHandler:(void (^)(NSError *, Corporation *))completionHandler
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

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!_currentString) {
        _currentString = [[NSMutableString alloc] init];
    }
    
    [_currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"error"]) {
        // the API query returned an error
        NSLog(@"The API query returned an error : %@", _currentString);
    }
    
    if ([elementName isEqualToString:@"corporationID"]) {
        _currentCorporation = [CoreDataController corporationlWithCorporationID:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                                                      inContext:_moc
                                                         notifyUserIfEmptyOrNil:NO];
        
        if (_currentCorporation == nil) {
            _currentCorporation = [NSEntityDescription insertNewObjectForEntityForName:@"Corporation"
                                                                inManagedObjectContext:_moc];
        }
        
        _currentCorporation.corporationID = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if ([elementName isEqualToString:@"corporation"]) {
        _currentCorporation.corporationName = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    
    if (_currentString) {
        _currentString = nil;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    _completionHandler(nil, _currentCorporation);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    _completionHandler(parseError, nil);
}

@end
