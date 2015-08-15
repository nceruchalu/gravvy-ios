//
//  GRVModelManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVModelManager.h"
#import "GRVManagedDocument.h"
#import "GRVConstants.h"

// Constants
/**
 * kUserDocumentBase is Managed Document base location
 */
static NSString *const kUserDocumentBase      = @"UserDocument";

/**
 * kUserKeyBase is base string for NSUserDefaults user settings dictionary key
 */
static NSString *const kUserKeyBase      = @"kGRVUserKey";

/**
 * kProfileConfiguredKey is the NSUserDefaults dictionary key for
 * the indicator of if the user profile has been configured following account
 * activation (registration and verification)
 */
static NSString *const kProfileConfiguredKey = @"kGRVProfileConfiguredKey";

@interface GRVModelManager ()

// want all properties to be readwrite internally
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *workerContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *workerContextVideo;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *workerContextLongRunning;

@property (strong, nonatomic) NSString *phoneNumber; // cache phone number being used.

/**
 * The documents for this app are separated by user, so this will be updated for
 * each authenticated user that logs into the app
 */
@property (strong, nonatomic) UIManagedDocument *userDocument;

@end

@implementation GRVModelManager
#pragma mark - Properties
- (void)setUserDocument:(UIManagedDocument *)userDocument
{
    // modifying the user document means the context should be reset. The context
    // will be set appropriately when the document is used.
    _userDocument = userDocument;
    self.managedObjectContext = nil;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    // modifying the main thread context means the background thread context should
    // be reset.
    _managedObjectContext = managedObjectContext;
    self.workerContext = nil;
    self.workerContextVideo = nil;
    self.workerContextLongRunning = nil;
}

- (NSManagedObjectContext *)workerContext
{
    // Worker context should only be generated if it doesn't already exist (was
    // possibly reset) and the main thread managed object context is ready.
    //
    // Note that it is surely faster to have each context be unique for
    // each core data background operation. As this would prevent delays while
    // waiting for a context to get freed up.
    // This will however lead to errors as it causes duplication of NSManagedObjects
    // when each worker context goes off creating objects common to different
    // background operations, such as GRVUsers.
    if (!_workerContext && self.managedObjectContext) {
        _workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workerContext.parentContext = self.managedObjectContext;
        _workerContext.stalenessInterval = 0.0; // no staleness acceptable
    }
    return _workerContext;
}

- (NSManagedObjectContext *)workerContextVideo
{
    if (!_workerContextVideo && self.managedObjectContext) {
        _workerContextVideo = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workerContextVideo.parentContext = self.managedObjectContext;
        _workerContextVideo.stalenessInterval = 0.0; // no staleness acceptable
    }
    return _workerContextVideo;
}

- (NSManagedObjectContext *)workerContextLongRunning
{
    if (!_workerContextLongRunning && self.managedObjectContext) {
        _workerContextLongRunning = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workerContextLongRunning.parentContext = self.managedObjectContext;
        _workerContextLongRunning.stalenessInterval = 0.0; // no staleness acceptable
    }
    return _workerContextLongRunning;
}


#pragma mark NSUserDefault Settings
- (BOOL)userSoundsSetting
{
    return [self userSettingsBoolForKey:kGRVSettingsSounds];
}

- (void)setUserSoundsSetting:(BOOL)userSoundsSetting
{
    [self setUserSettingsBool:userSoundsSetting forKey:kGRVSettingsSounds];
}

- (NSString *)userFullNameSetting
{
    return [self userSettingsObjectForKey:kGRVSettingsFullName];
}

- (void)setUserFullNameSetting:(NSString *)userFullNameSetting
{
    [self setUserSettingsObject:userFullNameSetting forKey:kGRVSettingsFullName];
}

- (BOOL)profileConfiguredPostActivation
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kProfileConfiguredKey];
}

- (void)setProfileConfiguredPostActivation:(BOOL)profileConfiguredPostActivation
{
    [[NSUserDefaults standardUserDefaults] setBool:profileConfiguredPostActivation
                                            forKey:kProfileConfiguredKey];
    [[NSUserDefaults standardUserDefaults] synchronize]; // never forget saving to disk
}

- (BOOL)acknowledgedVideoCreationTip
{
    return [self userSettingsBoolForKey:kGRVSettingsVideoCreationTip];
}

- (void)setAcknowledgedVideoCreationTip:(BOOL)acknowledgedVideoCreationTip
{
    [self setUserSettingsBool:acknowledgedVideoCreationTip forKey:kGRVSettingsVideoCreationTip];
}

- (BOOL)acknowledgedClipAdditionTip
{
    return [self userSettingsBoolForKey:kGRVSettingsClipAdditionTip];
}

- (void)setAcknowledgedClipAdditionTip:(BOOL)acknowledgedClipAdditionTip
{
    [self setUserSettingsBool:acknowledgedClipAdditionTip forKey:kGRVSettingsClipAdditionTip];
}

#pragma mark Helpers
- (BOOL)userSettingsBoolForKey:(NSString *)settingsKey
{
    return [[self userSettingsObjectForKey:settingsKey] boolValue];
}

- (void)setUserSettingsBool:(BOOL)boolean forKey:(NSString *)settingsKey
{
    [self setUserSettingsObject:@(boolean) forKey:settingsKey];
}

- (id)userSettingsObjectForKey:(NSString *)settingsKey
{
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self userSettingsKey]];
    return [userSettings objectForKey:settingsKey];
}

- (void)setUserSettingsObject:(id)object forKey:(NSString *)settingsKey
{
    NSString *userKey = [self userSettingsKey];
    NSMutableDictionary *mutableUserSettings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:userKey] mutableCopy];
    
    if (!object) {
        [mutableUserSettings removeObjectForKey:settingsKey];
    } else {
        [mutableUserSettings setObject:object forKey:settingsKey];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:mutableUserSettings forKey:userKey];
    [[NSUserDefaults standardUserDefaults] synchronize]; // never forget saving to disk
}


#pragma mark - Class methods
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static GRVModelManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


#pragma mark - Initialization
/*
 * ideally we would make the designated initializer of the superclass call
 *   the new designated initializer, but that doesn't make sense in this case.
 * if a programmer calls [GRVModelManager alloc] init], let them know the error
 *   of their ways.
 */
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [GRVModelManager sharedManager]"
                                 userInfo:nil];
    return nil;
}

/*
 * here is the real (secret) initializer
 * this is the official designated initializer so it will call the designated
 *   initializer of the superclass
 */
- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        // custom initialization here...
    }
    return self;
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)setupDocumentForUser:(NSString *)phoneNumber completionHandler:(void (^)())documentIsReady
{
    // register default settings for user at this time
    [self registerDefaultSettings:phoneNumber];
    
    // clear out managed object context which will soon be setup again.
    self.managedObjectContext = nil;
    
    // if a document is already open close it out before setting up document
    if (self.userDocument) {
        [self closeUserDocument:^{
            self.userDocument = nil;
            [self setupNewDocumentForUser:phoneNumber completionHandler:documentIsReady];
        }];
        
    } else {
        [self setupNewDocumentForUser:phoneNumber completionHandler:documentIsReady];
    }
}


/**
 * Asynchronously save and close userDocument.
 *
 * @param documentIsClosed
 *      block to be called when document is closed successfully.
 */
- (void)closeUserDocument:(void (^)())documentIsClosed
{
    [self.userDocument closeWithCompletionHandler:^(BOOL success) {
        // it would be ideal to check for success first, but if this fails
        // it's game over anyways.
        // we indicate document closure by clearing out userDocument
        self.userDocument = nil;
        
        // notify all listeners that this managedObjectContext is no longer valid
        [[NSNotificationCenter defaultCenter] postNotificationName:kGRVMOCDeletedNotification
                                                            object:self];
        if (documentIsClosed) documentIsClosed();
    }];
}


/**
 * Force an asynchronous manual save of the usually auto-saved userDocument.
 *
 * @param documentIsSaved
 *      block to be called when document is saved.
 */
- (void)saveUserDocument:(void (^)())documentIsSaved
{
    [self.userDocument saveToURL:self.userDocument.fileURL
                forSaveOperation:UIDocumentSaveForOverwriting
               completionHandler:^(BOOL success) {
                   if (success) {
                       if (documentIsSaved) documentIsSaved();
                   }
               }
     ];
}


#pragma mark Private: CoreData
/**
 * Setup document for a given authenticated app user. This sets up the internal
 * UIManagedDocument and its associated managedObjectContext
 *
 * This is different from the public method setupDocumentForUser:completionHandler:
 * in that it doesn't close a previously opened document.
 *
 * @param phoneNumber
 *      Unique identifier of a user is an E.164 format phone number.
 * @param documentIsReady
 *      A block object to be executed when the document and managed object context
 *      are setup. This block has no return value and takes no arguments.
 *
 * @warning You probably shouldn't call this without first closing the document.
 */
- (void)setupNewDocumentForUser:(NSString *)phoneNumber completionHandler:(void (^)())documentIsReady
{
    // construct authenticated user's document directory.
    NSString *docPath = [NSString stringWithFormat:@"%@%@", kUserDocumentBase, phoneNumber];
    
    // setup userDocument @property as a document in the application's document directory
    NSURL *docURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    docURL = [docURL URLByAppendingPathComponent:docPath];
    
    self.userDocument = [[GRVManagedDocument alloc] initWithFileURL:docURL];
    
    // support automatic migration
    // see documentation of NSPersistentStoreCoordinator for details
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption  : @(YES),
                              NSInferMappingModelAutomaticallyOption        : @(YES)};
    self.userDocument.persistentStoreOptions = options;
    
    // use userDocument to setup managedObjectContext @property
    [self useUserDocument:^{
        // notify all listeners that this managedObjectContext is now setup
        [[NSNotificationCenter defaultCenter] postNotificationName:kGRVMOCAvailableNotification
                                                            object:self];
        if (documentIsReady) documentIsReady();
    }];
}

/**
 * Either creates, opens or just uses the userDocument.
 * Creating and opening are async, so in the completion handler we set our model
 *   (managedObjectContext).
 * This sets up the managedObjectContext property if it isn't already setup
 *   then it calls the ^(void)documentIsReady block.
 *
 * @param documentIsReady
 *      block to be called when document is ready and managedObjectContext
 *      property is setup.
 */
- (void)useUserDocument:(void (^)())documentIsReady
{
    // access the shared instance of the document
    NSURL *url = self.userDocument.fileURL;
    UIManagedDocument *document = self.userDocument;
    
    // must first open/create the document to use it so check to see if it
    // exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // if document doesn't exist create it
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
                // just created this document so this would be a good time to call
                // methods to populate the data. However there is no need for
                // that in this case.
                if (documentIsReady) documentIsReady();
            }
        }];
        
    } else if (document.documentState == UIDocumentStateClosed) {
        // if document exists but is closed, open it
        [document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
                // if already open, no need to attempt populating the data.
                if (documentIsReady) documentIsReady();
            }
        }];
        
    } else {
        // if document is already open try to use it
        self.managedObjectContext = document.managedObjectContext;
        // again already open, so no need to attempt populating the data.
        if (documentIsReady) documentIsReady();
    }
}


#pragma mark Private: NSUserDefaults
/**
 * Register NSUserDefault settings for currently authenticated user
 *
 * @param phoneNumber
 *      Unique identifier of user is an E.164 formatted phone number.
 */
- (void)registerDefaultSettings:(NSString *)phoneNumber;
{
    self.phoneNumber = phoneNumber; // cache phone number.
    
    // Create the preference defaults
    NSDictionary *appDefaults = @{kGRVSettingsSounds: @(YES),
                                  kGRVSettingsVideoCreationTip: @(NO),
                                  kGRVSettingsClipAdditionTip: @(NO)};
    NSDictionary *userDefaults = @{[self userSettingsKey] : appDefaults,
                                   kProfileConfiguredKey : @(NO)};
    
    // Register the preference defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 * Get key for a user's settings dictionary in NSUserDefaults
 *
 * @warning Don't call this before phoneNumber @property is setup.
 */
- (NSString *)userSettingsKey
{
    return [NSString stringWithFormat:@"%@%@", kUserKeyBase, self.phoneNumber];
}

@end
