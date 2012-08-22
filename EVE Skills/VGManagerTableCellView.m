//
//  VGManagerTableCellView.m
//  EVE Skills
//
//  Created by Vincent Garrigues on 21/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import "VGManagerTableCellView.h"
#import "VGAppDelegate.h"
#import "Character.h"
#import "Portrait.h"

@interface VGManagerTableCellView () {
    // Managed Objects
    Character *_character;
}

@property (strong, nonatomic) VGAppDelegate *appDelegate;
@property (strong, nonatomic) NSManagedObjectContext *moc;

- (void)loadPortrait;

@end

@implementation VGManagerTableCellView

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

#pragma mark -
#pragma mark - View lifecycle

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
    
    
}

#pragma mark -
#pragma mark - KVO

- (void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    
    if (objectValue != nil && objectValue != _character) {
        _character = objectValue;
        [self loadPortrait];
        [self loadCorporation];
    }
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

- (void)loadPortrait
{
    if (_character == nil) return;
    
    // Fetch the Portrait associated with _character
    [self.moc performBlock:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Portrait" inManagedObjectContext:_moc];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"characterID == %@", _character.characterID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Portrait with characterID = '%@' : %@, %@",
                  _character.characterID, error, [error userInfo]);
        }
        
        if (fetchedObjects.count == 0) {
            // No portrait in DB, download the portrait
            dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
                [_appDelegate.apiController addPortraitForCharacterID:_character.characterID completionHandler:^(NSError *error, Portrait *portrait) {
                    self.portrait = portrait;
                }];
            });
        } else {
            // Portrait in the DB
            self.portrait = fetchedObjects.lastObject;
        }
    }];
}

- (void)loadCorporation
{
    if (_character == nil) return;
    
    [self.moc performBlock:^{
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Corporation"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"corporationID = %@", _character.corporationID];
        fr.predicate = predicate;
        
        NSError *error = nil;
        NSArray *fetchedObjects = [_moc executeFetchRequest:fr error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"Error fetching Corporation with corporationID = '%@' : %@, %@",
                  _character.corporationID, error, [error userInfo]);
        }
        
        if (fetchedObjects.count == 0) {
            // Corporation not in DB, download it
            dispatch_async(_appDelegate.apiController.dispatchQueue, ^{
                [_appDelegate.apiController addCorporationForCharacterID:_character.characterID completionHandler:^(NSError *error, Corporation *corporation) {
                    self.corporation = corporation;
                }];
            });
        } else {
            // Corporation in DB
            self.corporation = fetchedObjects.lastObject;
        }
    }];
}

#pragma mark -
#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
