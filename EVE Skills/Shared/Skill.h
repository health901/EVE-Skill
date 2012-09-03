//
//  Skill.h
//  EVE Skills_old
//
//  Created by Vincent Garrigues on 14/08/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group;

@interface Skill : NSManagedObject

@property (nonatomic, retain) NSString * secondaryAttribute;
@property (nonatomic, retain) NSString * skillName;
@property (nonatomic, retain) NSString * skillID;
@property (nonatomic, retain) NSString * primaryAttribute;
@property (nonatomic, retain) NSNumber * rank;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) Group *group;

@end
