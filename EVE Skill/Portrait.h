//
//  Portrait.h
//  EVE Skills_old
//
//  Created by Vincent Garrigues on 14/08/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Portrait : NSManagedObject

@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSString * characterID;

@end
