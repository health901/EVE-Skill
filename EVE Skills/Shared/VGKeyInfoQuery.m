//
//  VGKeyInfoQuery.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 04/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGKeyInfoQuery.h"
#import "VGAppDelegate.h"
#import "API.h"
#import "Character.h"
#import "Corporation.h"

@interface VGKeyInfoQuery () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    // XML parsing
    NSXMLParser *_xmlParser;
    NSMutableString *_currentString;
    
    API *_currentAPI;
    Character *_currentCharacter;
    Corporation *_currentCorporation;
    
    // Core Data stuff
    NSManagedObjectContext *_moc;
    
    // Completion handler
    void (^_completionHandler)(NSError *);
}

@end

@implementation VGKeyInfoQuery


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
    if ([elementName isEqualToString:@"key"]) {
        // is this API already in the MOC
        _currentAPI = [CoreDataController apiWithKeyID:self.keyID
                                             inContext:_moc
                                notifyUserIfEmptyOrNil:NO];
        
        if (!_currentAPI) {
            // this API is not in the MOC, we create it
            _currentAPI = [NSEntityDescription insertNewObjectForEntityForName:@"API"
                                                        inManagedObjectContext:_moc];
        }
        
        // fill the attributes of the object
        _currentAPI.keyID       = self.keyID;
        _currentAPI.vCode       = self.vCode;
        _currentAPI.accessMask  = attributeDict[@"accessMask"];
        NSDate *expiresTmp = [NSDate dateWithString:[NSString stringWithFormat:@"%@ +0000",
                                                     attributeDict[@"expires"]]];
        _currentAPI.expires     =  (expiresTmp ? expiresTmp : [NSDate dateWithTimeIntervalSince1970:0]);
        _currentAPI.timestamp   = [NSDate date];
    }
    
    // each 'row' element represents a character associated with this API
    if ([elementName isEqualToString:@"row"]) {
        // is this Character already in the MOC
        _currentCharacter = [CoreDataController characterWithCharacterID:attributeDict[@"characterID"]
                                                               inContext:_moc
                                                  notifyUserIfEmptyOrNil:NO];
        
        if (!_currentCharacter) {
            // this Character is not in the MOC, we create it
            _currentCharacter = [NSEntityDescription insertNewObjectForEntityForName:@"Character"
                                                              inManagedObjectContext:_moc];
        }
        
        // fill the attributes of the object
        _currentCharacter.characterID   = attributeDict[@"characterID"];
        _currentCharacter.characterName = attributeDict[@"characterName"];
        _currentCharacter.corporationID = attributeDict[@"corporationID"];
        _currentCharacter.timestamp     = [NSDate date];
        _currentCharacter.api           = _currentAPI;

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
