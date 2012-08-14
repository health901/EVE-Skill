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
    
    // Core Data stuff
    NSManagedObjectContext *_moc;
    
    API *_currentAPI;
    Character *_currentCharacter;
    Corporation *_currentCorporation;
    
    // Completion handler
    void (^_completionHandler)(NSError *);
}

- (API *)apiWithKeyID:(NSString *)keyID;
- (Character *)characterWithCharacterID:(NSString *)characterID;
- (Corporation *)corporationWithCorporationID:(NSString *)corporationID;

@end

@implementation VGKeyInfoQuery
@synthesize keyID = _keyID;


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
        return nil;
    }
    
    if ([fetchedObjects count] == 0) {
        // no objects with specified ID found
        return nil;
    }
    
    return [fetchedObjects lastObject];
}

- (Character *)characterWithCharacterID:(NSString *)characterID
{
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
        return nil;
    }
    
    if ([fetchedObjects count] == 0) {
        // no objects with specified ID found
        return nil;
    }
    
    return [fetchedObjects lastObject];
}

- (Corporation *)corporationWithCorporationID:(NSString *)corporationID
{
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
        return nil;
    }
    
    if ([fetchedObjects count] == 0) {
        // no objects with specified ID found
        return nil;
    }
    
    return [fetchedObjects lastObject];
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
        _currentAPI.accessMask  = [attributeDict objectForKey:@"accessMask"];
        _currentAPI.expires     = [NSDate dateWithString:[NSString stringWithFormat:@"%@ +0000", [attributeDict objectForKey:@"expires"]]];
        _currentAPI.timestamp   = [NSDate date];
    }
    
    // each 'row' element represents a character associated with this API
    if ([elementName isEqualToString:@"row"]) {
        // is this Character already in the MOC
        _currentCharacter = [self characterWithCharacterID:[attributeDict objectForKey:@"characterID"]];
        
        if (!_currentCharacter) {
            // this Character is not in the MOC, we create it
            _currentCharacter = [NSEntityDescription insertNewObjectForEntityForName:@"Character"
                                                              inManagedObjectContext:_moc];
        }
        
        // fill the attributes of the object
        _currentCharacter.characterID   = [attributeDict objectForKey:@"characterID"];
        _currentCharacter.characterName = [attributeDict objectForKey:@"characterName"];
        _currentCharacter.timestamp     = [NSDate date];
        _currentCharacter.api           = _currentAPI;
        
        // get the character's portrait
        NSString *tmpCharacterID = [NSString stringWithString:_currentCharacter.characterID];
        dispatch_async(dispatch_get_current_queue(), ^{
            
            [_appDelegate.apiController addPortraitForCharacterID:tmpCharacterID];
        });
        
        // is this Character's Corporation already in the MOC
        _currentCorporation = [self corporationWithCorporationID:[attributeDict objectForKey:@"corporationID"]];
        
        if (!_currentCorporation) {
            // this Character's Corporation is not in the MOC, we create it
            _currentCorporation = [NSEntityDescription insertNewObjectForEntityForName:@"Corporation"
                                                                inManagedObjectContext:_moc];
        }
        
        // fill the attributes of the object
        _currentCorporation.corporationID   = [attributeDict objectForKey:@"corporationID"];
        _currentCorporation.corporationName = [attributeDict objectForKey:@"corporationName"];
        _currentCorporation.timestamp       = [NSDate date];
        
        // set the Character's Corporation
        _currentCharacter.corporation = _currentCorporation;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    
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
