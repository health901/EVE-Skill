//
//  Corporation.h
//  EVE Skills_old
//
//  Created by Vincent Garrigues on 14/08/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Character;

@interface Corporation : NSManagedObject

@property (nonatomic, retain) NSString * corporationName;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * corporationID;
@property (nonatomic, retain) NSSet *characters;
@end

@interface Corporation (CoreDataGeneratedAccessors)

- (void)addCharactersObject:(Character *)value;
- (void)removeCharactersObject:(Character *)value;
- (void)addCharacters:(NSSet *)values;
- (void)removeCharacters:(NSSet *)values;

@end
