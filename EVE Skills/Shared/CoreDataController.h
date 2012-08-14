
/*
 
 */

#import <Foundation/Foundation.h>

@interface CoreDataController : NSObject <NSFilePresenter> 

@property (nonatomic, readonly) NSPersistentStoreCoordinator *psc;
@property (nonatomic, readonly) NSManagedObjectContext *mainThreadContext;
@property (nonatomic, readonly) NSPersistentStore *iCloudStore;
@property (nonatomic, readonly) NSPersistentStore *fallbackStore;
@property (nonatomic, readonly) NSPersistentStore *localStore;
@property (nonatomic, readonly) NSPersistentStore *skillStore;

@property (nonatomic, readonly) NSURL *ubiquityURL;
@property (nonatomic, readonly) id currentUbiquityToken;

/*
 Called by the AppDelegate whenever the application becomes active.
 We use this signal to check to see if the container identifier has
 changed.
 */
- (void)applicationResumed;

/*
 Load all the various persistent stores
 - The iCloud Store / Fallback Store if iCloud is not available
 - The persistent store used to store local data
 
 Also:
 - Seed the database if desired (using the SEED #define)
 - Unique
 */
- (void)loadPersistentStores;

#pragma mark Debugging Methods
/*
 Copy the entire contents of the application's iCloud container to the Application's sandbox.
 Use this on iOS to copy the entire contents of the iCloud Continer to the application sandbox
 where they can be downloaded by Xcode.
 */
- (void)copyContainerToSandbox;

/*
 Delete the contents of the ubiquity container, this method will do a coordinated write to
 delete every file inside the Application's iCloud Container.
 */
- (void)nukeAndPave;

@end
