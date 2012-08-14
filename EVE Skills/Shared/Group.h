//
//  Group.h
//  EVE Skills_old
//
//  Created by Vincent Garrigues on 14/08/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Skill;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * groupID;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NSSet *skills;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addSkillsObject:(Skill *)value;
- (void)removeSkillsObject:(Skill *)value;
- (void)addSkills:(NSSet *)values;
- (void)removeSkills:(NSSet *)values;

@end
