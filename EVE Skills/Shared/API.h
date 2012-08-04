//
//  API.h
//  EVE Database
//
//  Created by Vincent Garrigues on 04/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Character;

@interface API : NSManagedObject

@property (nonatomic, retain) NSString * keyID;
@property (nonatomic, retain) NSString * accessMask;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * vCode;
@property (nonatomic, retain) NSDate * expires;
@property (nonatomic, retain) NSSet *characters;
@end

@interface API (CoreDataGeneratedAccessors)

- (void)addCharactersObject:(Character *)value;
- (void)removeCharactersObject:(Character *)value;
- (void)addCharacters:(NSSet *)values;
- (void)removeCharacters:(NSSet *)values;

@end
