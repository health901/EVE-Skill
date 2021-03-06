/*
 File modified by Vincent Garrigues starting in August 2012
 
 File: CoreDataController.h
 Abstract:
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 
 WWDC 2012 License
 
 NOTE: This Apple Software was supplied by Apple as part of a WWDC 2012
 Session. Please refer to the applicable WWDC 2012 Session for further
 information.
 
 IMPORTANT: This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple
 Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <Foundation/Foundation.h>

#import "API.h"
#import "Character.h"
#import "Skill.h"
#import "Queue.h"
#import "Portrait.h"
#import "Corporation.h"

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
 Asynchronously saves the main thread context
 */
- (void)saveMainThreadContext;

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
- (void)loadPersistentStores:(void (^)())completionBlock;

- (void)dropStores;

/*
 Delete all objects in the local store
 */
//- (void)deleteLocalStore:(void (^)())completionBlock;

#pragma mark Fetch methods

+ (API *)   apiWithKeyID:(NSString *)keyID
               inContext:(NSManagedObjectContext *)context
  notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (Character *)characterWithCharacterID:(NSString *)characterID
                              inContext:(NSManagedObjectContext *)context
                 notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (Skill *)skillWithSkillID:(NSString *)skillID
                  inContext:(NSManagedObjectContext *)context
     notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (Group *)groupWithGroupID:(NSString *)groupID
                  inContext:(NSManagedObjectContext *)context
     notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (Corporation *)corporationlWithCorporationID:(NSString *)corporationID
                                     inContext:(NSManagedObjectContext *)context
                        notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (Queue *)queueWithCharacterID:(NSString *)characterID
                      inContext:(NSManagedObjectContext *)context
         notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (Portrait *)portraitWithCharacterID:(NSString *)characterID
                            inContext:(NSManagedObjectContext *)context
               notifyUserIfEmptyOrNil:(BOOL)notifyUser;

+ (NSArray *)characterEnabled:(NSNumber *)enabled
                    inContext:(NSManagedObjectContext *)context
              notifyUserIfNil:(BOOL)notifyUser;

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
