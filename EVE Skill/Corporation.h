//
//  Corporation.h
//  EVE Skills
//
//  Created by Vincent Garrigues on 22/08/12.
//  Copyright (c) 2012 Vincent Garrigues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Corporation : NSManagedObject

@property (nonatomic, retain) NSString * corporationName;
@property (nonatomic, retain) NSString * corporationID;

@end
