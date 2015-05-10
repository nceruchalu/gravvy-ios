//
//  GRVAddressBookManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVAddressBookManager.h"
#import <AddressBook/AddressBook.h>
#import <CoreData/CoreData.h>
#import "GRVContact+AddressBook.h"

#pragma mark - Constants
// NSError domain
static NSString *const kGRVAddressBookManagerErrorDomain = @"GRVAddressBookManagerErrorDomain";


#pragma mark - C Functions
/**
 * C callback function that simply invokes the appropriate instance method on
 * the address book manager for when the address book is changed.
 *
 * @param addressBook   Address book used to interact with the Address Book database.
 * @param info          Always NULL.
 * @param context       The AddressBookManager object passsed to the callback function
 */
void addressBookChanged(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    
    GRVAddressBookManager *addressBookManager = (__bridge GRVAddressBookManager *)context;
    [addressBookManager addressBookChanged:addressBook];
}

@interface GRVAddressBookManager ()

// address book object to be used on the main queue
@property (nonatomic) ABAddressBookRef addressBook;

@end

@implementation GRVAddressBookManager

#pragma mark - Properties


#pragma mark - Class methods
#pragma mark Public
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static GRVAddressBookManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

#pragma mark Public (Authorization)
+ (BOOL)authorized
{
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

+ (ABAuthorizationStatus)authorizationStatus
{
    return ABAddressBookGetAuthorizationStatus();
}


#pragma mark Public (User Preferences)
+ (ABPersonSortOrdering)sortOrdering
{
    return ABPersonGetSortOrdering();
}

+ (BOOL)orderByFirstName
{
    return [GRVAddressBookManager sortOrdering] == kABPersonSortByFirstName;
}

+ (BOOL)orderByLastName
{
    return [GRVAddressBookManager sortOrdering] == kABPersonSortByLastName;
}

+ (ABPersonCompositeNameFormat)compositeNameFormat
{
    return ABPersonGetCompositeNameFormatForRecord(NULL);
}

+ (BOOL)compositeNameFormatFirstNameFirst
{
    return [GRVAddressBookManager compositeNameFormat] == kABPersonCompositeNameFormatFirstNameFirst;
}

+ (BOOL)compositeNameFormatLastNameFirst
{
    return [GRVAddressBookManager compositeNameFormat] == kABPersonCompositeNameFormatLastNameFirst;
}


#pragma mark Public (Reading ABPersonRef)
/**
 * Convert properties into strings, array, images
 */
+ (NSString *)stringProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef
{
    CFStringRef valueRef = ABRecordCopyValue(recordRef, property);
    return (__bridge_transfer NSString *)valueRef;
}

+ (NSArray *)arrayProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef
{
    ABMultiValueRef multiValue = ABRecordCopyValue(recordRef, property);
    CFIndex multiValueCount = ABMultiValueGetCount(multiValue);
    NSMutableArray *resultArray = [NSMutableArray array];
    
    for (CFIndex i=0; i<multiValueCount; i++) {
        CFTypeRef valueRef = ABMultiValueCopyValueAtIndex(multiValue, i);
        NSString *string = (__bridge_transfer NSString *)valueRef;
        if (string) [resultArray addObject:string];
    }
    
    if (multiValue) CFRelease(multiValue);
    return [resultArray copy];
}

+ (UIImage *)imagePropertyFromRecord:(ABRecordRef)recordRef asThumbnail:(BOOL)asThumbnail
{
    ABPersonImageFormat format = asThumbnail ? kABPersonImageFormatThumbnail : kABPersonImageFormatOriginalSize;
    CFDataRef imageDataRef = ABPersonCopyImageDataWithFormat(recordRef, format);
    
    NSData *imageData = (__bridge_transfer NSData *)imageDataRef;
    UIImage *imageResult = imageData ? [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale] : nil;
    
    return imageResult;
}

+ (NSDate *)dateProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef
{
    CFDateRef valueRef = ABRecordCopyValue(recordRef, property);
    return (__bridge_transfer NSDate *)valueRef;
}

+ (NSNumber *)numberProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef
{
    CFNumberRef valueRef = ABRecordCopyValue(recordRef, property);
    return (__bridge_transfer NSNumber *)valueRef;
}

#pragma mark - Initialization
/*
 * ideally we would make the designated initializer of the superclass call
 *   the new designated initializer, but that doesn't make sense in this case.
 * if a programmer calls [GRVAddressBookManager alloc] init], let them know the error
 *   of their ways.
 */
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [GRVAddressBookManager sharedManager]"
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
        // Setup address book and register for callback to receive
        // notifications when the address book database is modified.
        CFErrorRef error = NULL;
        self.addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        if (!self.addressBook) {
            self = nil;
            return self;
        }
        
        GRVAddressBookManager * __weak weakSelf = self; // avoid capturing self in the callback
        ABAddressBookRegisterExternalChangeCallback(self.addressBook, addressBookChanged, (__bridge void *)(weakSelf));
        
    }
    return self;
}


#pragma mark - Deallocation
- (void)dealloc
{
    if (_addressBook) CFRelease(_addressBook), _addressBook = NULL;
}


#pragma mark - Instance Methods
#pragma mark Public (Notifications)
- (void)addressBookChanged:(ABAddressBookRef)addressBook
{
    // Address Book database changed, so sync contacts
    [GRVContact refreshContacts:nil];
}

- (void)requestAuthorizationWithCompletion:(void (^)(BOOL authorized, NSError *error))completion
{
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        
        // Since the completion handler is called on an arbitrary queue,
        // we have to dispatch to main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            
            BOOL authorized = (granted) ? YES : NO;
            
            NSError *nserror = nil;
            if (error || !authorized) {
                // if there's an error we need to map it to an NSError as the
                // provided CFErrorRef is always empty (oddly...)
                nserror =[NSError errorWithDomain:kGRVAddressBookManagerErrorDomain
                                             code:ABAddressBookGetAuthorizationStatus()
                                         userInfo:nil];
            }
            
            // Call callback if available
            if (completion) completion(authorized, nserror);
        });
    });
}

@end
