//
//  Skill.h
//  EVE Skills_old
//
//  Created by Vincent Garrigues on 03/08/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Skill : NSManagedObject

@property (nonatomic, retain) NSString * secondaryAttribute;
@property (nonatomic, retain) NSString * skillName;
@property (nonatomic, retain) NSString * skillID;
@property (nonatomic, retain) NSString * primaryAttribute;
@property (nonatomic, retain) NSNumber * rank;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSManagedObject *group;
@property (nonatomic, retain) NSSet *queue;
@end

@interface Skill (CoreDataGeneratedAccessors)

- (void)addQueueObject:(NSManagedObject *)value;
- (void)removeQueueObject:(NSManagedObject *)value;
- (void)addQueue:(NSSet *)values;
- (void)removeQueue:(NSSet *)values;

@end
