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

- (API *)apiWithKeyID:(NSString *)keyID;
- (Character *)characterWithCharacterID:(NSString *)characterID;
- (Corporation *)corporationWithCorporationID:(NSString *)corporationID;

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
#pragma mark - Private methods

- (API *)apiWithKeyID:(NSString *)keyID
{
    __block API *api = nil;
    
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"API"
                                                  inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyID == %@", keyID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"apiWithKeyID: '%@' error fetching objects: %@, %@",
                  keyID, error, [error userInfo]);
            return;
        }
        
        if ([fetchedObjects count] == 0) {
            NSLog(@"No API in DB with keyID = '%@'", keyID);
            return;
        }
        
        api = [fetchedObjects lastObject];
    }];
    
    
    
    return api;
}

- (Character *)characterWithCharacterID:(NSString *)characterID
{
    __block Character *character = nil;
    
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Character"
                                                  inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"characterWithCharacterID: '%@' error fetching objects: %@, %@",
                  characterID, error, [error userInfo]);
            return;
        }
        
        if ([fetchedObjects count] == 0) {
            NSLog(@"No Character in DB with characterID = '%@'", characterID);
            return;
        }
        
        character = [fetchedObjects lastObject];
    }];
    
    return character;
}

- (Corporation *)corporationWithCorporationID:(NSString *)corporationID
{
    __block Corporation *corporation = nil;
    
    [_moc performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Corporation"
                                                  inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"corporationID == %@", corporationID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects == nil) {
            NSLog(@"corporationWithCorporationID: '%@' error fetching objects: %@, %@",
                  corporationID, error, [error userInfo]);
            return;
        }
        
        if ([fetchedObjects count] == 0) {
            NSLog(@"No corporation in DB with corporationID = '%@'", corporationID);
            return;
        }
        
        corporation = [fetchedObjects lastObject];
    }];
    
    return corporation;
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
        _currentAPI = [self apiWithKeyID:self.keyID];
        
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
        _currentCharacter = [self characterWithCharacterID:attributeDict[@"characterID"]];
        
        if (!_currentCharacter) {
            // this Character is not in the MOC, we create it
            _currentCharacter = [NSEntityDescription insertNewObjectForEntityForName:@"Character"
                                                              inManagedObjectContext:_moc];
        }
        
        // fill the attributes of the object
        _currentCharacter.characterID   = attributeDict[@"characterID"];
        _currentCharacter.characterName = attributeDict[@"characterName"];
        _currentCharacter.timestamp     = [NSDate date];
        _currentCharacter.api           = _currentAPI;
        
        // is this Character's Corporation already in the MOC
        _currentCorporation = [self corporationWithCorporationID:attributeDict[@"corporationID"]];
        
        if (!_currentCorporation) {
            // this Character's Corporation is not in the MOC, we create it
            _currentCorporation = [NSEntityDescription insertNewObjectForEntityForName:@"Corporation"
                                                                inManagedObjectContext:_moc];
        }
        
        // fill the attributes of the object
        _currentCorporation.corporationID   = attributeDict[@"corporationID"];
        _currentCorporation.corporationName = attributeDict[@"corporationName"];
        _currentCorporation.timestamp       = [NSDate date];
        
        // set the Character's Corporation
        _currentCharacter.corporation = _currentCorporation;
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
