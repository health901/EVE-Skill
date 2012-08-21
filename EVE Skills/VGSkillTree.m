//
//  VGSkillTree.m
//  EVE Database
//
//  Created by Vincent Garrigues on 03/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGSkillTree.h"
#import "VGAPICall.h"
#import "VGAppDelegate.h"
#import "Skill.h"
#import "Group.h"

@interface VGSkillTree () {
    // App delegate
    VGAppDelegate *_appDelegate;
    
    
    // XML parsing
    NSXMLParser *_xmlParser;
    NSMutableString *_currentString;
    NSString *_currentRowset;
    
    // GCD queue
    dispatch_queue_t _skillTreeQueue;
    
    // Core Data stuff
    NSManagedObjectContext *_skillTreeMOC;
    Group *_currentGroup;
    Skill *_currentSkill;
    
    // Completion handler
    void (^_completionHandler)(NSError *);
}

// returns the skill group with groupID or nil in _moc
- (Group *)groupWithGroupID:(NSString *)groupID;

// returns the skill with skillID or nil in _moc
- (Skill *)skillWithSkillID:(NSString *)skillID;

@end

@implementation VGSkillTree

#pragma mark -
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _appDelegate = (VGAppDelegate *)[NSApp delegate];
        
        // create the dispatch queue for this class
        _skillTreeQueue = dispatch_queue_create("com.vincentgarrigues.skillTreeQueue",
                                               DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark -
#pragma mark - Public methods

- (void)downloadAndGenerateSkillTree:(void (^)(NSError *))completionHandler
{
    _completionHandler = completionHandler;
    
    VGAPICall *apiCall = [[VGAPICall alloc] init];
    
    NSDictionary *dict = @{@"apiURL": @"https://api.eveonline.com/eve/SkillTree.xml.aspx"};
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [apiCall callAPIWithDictionarySync:dict response:&response error:&error];
    if (!data) {
        NSLog(@"Error : Data recieved is nil : %@, %@", error, [error userInfo]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            exit(1);
        });
    }
    
    // Parse the NSXMLDocument
    _xmlParser = [[NSXMLParser alloc] initWithData:data];
    _xmlParser.delegate = self;
    
    // create the skill tree MOC in its dispatch queue
    _skillTreeMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_skillTreeMOC setPersistentStoreCoordinator:_appDelegate.coreDataController.psc];
    
    [_xmlParser parse];
}

#pragma mark -
#pragma mark - Private methods

- (Group *)groupWithGroupID:(NSString *)groupID {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Group"
                                              inManagedObjectContext:_skillTreeMOC];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@", groupID];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [_skillTreeMOC executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        NSLog(@"groupWithGroupID: '%@' error fetching objects: %@, %@",
              groupID, error, [error userInfo]);
        return nil;
    }
    
    if ([fetchedObjects count] == 0) {
        // no objects with specified ID found
        return nil;
    }
    
    return [fetchedObjects lastObject];
}

- (Skill *)skillWithSkillID:(NSString *)skillID {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Skill"
                                              inManagedObjectContext:_skillTreeMOC];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"skillID == %@", skillID];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [_skillTreeMOC executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        NSLog(@"skillWithSkillID: '%@' error fetching objects: %@, %@",
              skillID, error, [error userInfo]);
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

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    // We save the MOC
    NSError *error = nil;
    [_skillTreeMOC save:&error];
    _completionHandler(error);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    // rowset : Save the name of the current rowset
    if ([elementName isEqualToString:@"rowset"]) {
        if ([(NSString *)attributeDict[@"name"] isEqualToString:@"skillGroups"]) {
            _currentRowset = @"skillGroups";
        }
        
        if ([(NSString *)attributeDict[@"name"] isEqualToString:@"skills"]) {
            _currentRowset = @"skills";
        }
        
        if ([(NSString *)attributeDict[@"name"] isEqualToString:@"requiredSkills"]) {
            _currentRowset = @"requiredSkills";
        }
        
        if ([(NSString *)attributeDict[@"name"] isEqualToString:@"skillBonusCollection"]) {
            _currentRowset = @"skillBonusCollection";
        }
    }
    
    // row : Save the data in new managed object contexts depending on the value of _currentRowset
    if ([elementName isEqualToString:@"row"]) {
        if ([_currentRowset isEqualToString:@"skillGroups"]) {
            // is this group already in the MOC
            _currentGroup = [self groupWithGroupID:attributeDict[@"groupID"]];
            
            if (!_currentGroup) {
                // this group is not in the MOC, we create it
                _currentGroup = [NSEntityDescription insertNewObjectForEntityForName:@"Group"
                                                              inManagedObjectContext:_skillTreeMOC];
                
                // fill the attributes of the object
                _currentGroup.groupID   = attributeDict[@"groupID"];
                _currentGroup.groupName = attributeDict[@"groupName"];
            }
        }
        
        if ([_currentRowset isEqualToString:@"skills"]) {
            // is this skill already in the MOC
            _currentSkill = [self skillWithSkillID:attributeDict[@"typeID"]];
            
            if (!_currentSkill) {
                // this skill is not in the MOC, we create it
                _currentSkill = [NSEntityDescription insertNewObjectForEntityForName:@"Skill"
                                                              inManagedObjectContext:_skillTreeMOC];
                
                // fill the attributes of the object
                _currentSkill.skillID   = attributeDict[@"typeID"];
                _currentSkill.skillName = attributeDict[@"typeName"];
                _currentSkill.group     = _currentGroup;
                
                // the rest of the attributes will be filled in didEndElement:
            }
        }
        
        if ([_currentRowset isEqualToString:@"requiredSkills"]) {
            // the data here has currently no interest
        }
        
        if ([_currentRowset isEqualToString:@"skillBonusCollection"]) {
            // the data here has currently no interest
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!_currentString) {
        _currentString = [[NSMutableString alloc] initWithCapacity:50];
    }
    [_currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    // description : description of the skill
    if ([elementName isEqualToString:@"description"]) {
        _currentSkill.desc = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    // rank : rank of the skill
    if ([elementName isEqualToString:@"rank"]) {
        _currentSkill.rank = @([_currentString intValue]);
    }
    
    // primaryAttribute : primary attribute of the skill
    if ([elementName isEqualToString:@"primaryAttribute"]) {
        _currentSkill.primaryAttribute = _currentString;
    }
    
    // secondaryAttribute : secondary attribute of the skill
    if ([elementName isEqualToString:@"secondaryAttribute"]) {
        _currentSkill.secondaryAttribute = _currentString;
    }
    
    // erase _currentString
    _currentString = nil;
    
    // update _currentRowset
    if ([elementName isEqualToString:@"rowset"]) {
        if ([_currentRowset isEqualToString:@"skills"]) {
            _currentRowset = @"skillGroups";
        }
        
        if ([_currentRowset isEqualToString:@"requiredSkills"] ||
            [_currentRowset isEqualToString:@"skillBonusCollection"]) {
            _currentRowset = @"skills";
        }
    }
    
}

@end
