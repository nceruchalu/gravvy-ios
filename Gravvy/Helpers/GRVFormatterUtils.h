//
//  GRVFormatterUtils.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"

/**
 * GRVFormatterUtils is a collection of methods that are handy in formatting
 * objects (particularly strings and dates) for various purposes, be they visual
 * appeal or REST API requirements.
 */
@interface GRVFormatterUtils : NSObject

#pragma mark - Phone Number
/**
 * Generate a formatted version of a given phone number.
 * The default region will be that of the current app user.
 *
 * @param phoneNumber       Phone number to format (not necessarily E.164)
 * @param numberFormat      Format to use: E.164, National, Internation, RFC3966
 * @param regionCode        Region code to use if it's not included in the number.
 * @param error             Ptr to NSError object where errors will be captured.
 *
 * @return  A phone number of appropriate format or nil if there's an error such
 *      as providing an invalid phone number.
 */
+ (NSString *)formatPhoneNumber:(NSString *)phoneNumber
                   numberFormat:(NBEPhoneNumberFormat)numberFormat
                  defaultRegion:(NSString *)regionCode
                          error:(NSError**)error;


#pragma mark - String
/**
 * Convert a string to an integer number
 *
 * @param string    String object to be converted to a number
 *
 * @return An NSNumber object created by passing string. Returns nil if string
 *      couldn't be successfully parsed.
 */
+ (NSNumber *)stringToNum:(NSString *)string;

/**
 * URL encode a string
 *
 * @param string    String to be URL-encoded
 *
 * @return URL-encoded string
 *
 * @ref http://stackoverflow.com/a/3426140
 * @ref http://stackoverflow.com/a/8088484
 */
+ (NSString *)urlEncode:(NSString *)string;


#pragma mark - Number
/**
 * Convert an integer number to a comma-separated string
 *
 * @param number    Number object to be converted to a string
 *
 * @return An NSString object created by passing number. Returns nil if number
 *      couldn't be successfully parsed.
 */
+ (NSString *)numToString:(NSNumber *)number;


#pragma mark - Date
/**
 * Generate the RFC 3339 DateFormatter.
 * This is the expected date format of the REST API.
 *
 * @note This returns a cahced date formatter for performance reasons.
 *
 * @return an NSDateFormatter that can parse dates of the format:
 *      "2014-06-30T00:43:38.565Z"
 */
+ (NSDateFormatter *)generateRFC3339DateFormatter;

/**
 * Generate the dayAndYear string for a given date.
 *
 * @param date  NSDate to convert to day string
 *
 * @return string of format "MMM d, yyyy" [Ex: "July 10, 1990"]
 */
+ (NSString *)dayAndYearStringForDate:(NSDate *)date;

/**
 * Generate the day string for a given date.
 *
 * @param date  NSDate to convert to day string
 *
 * @return string of format "EEE. MMM d" [Ex: "Wed. July 10"]
 */
+ (NSString *)dayStringForDate:(NSDate *)date;

/**
 * Generate the time string for a given date
 *
 * @param date  NSDate to convert to time string
 *
 * @return string of format "hh:mm a" [Ex: "12:08 PM"]
 */
+ (NSString *)timeStringForDate:(NSDate *)date;

/**
 * Generate the day and time string for a given date.
 *
 * @param date  NSDate to convert to day and time string
 *
 * @return string of format "EEE. MMM d, hh:mm a" [Ex: "Wed. July 10, 12:08 PM"]
 */
+ (NSString *)dayAndTimeStringForDate:(NSDate *)date;

/**
 * Generate a label for a time interval such as time since created or time to expiry
 *
 * @param interval      time interval to be converted to a label
 *
 * @return time interval string with the following format:
 *      - xxd when time interval is >= 1 day
 *      - xxh when time interval is < 1 day and >= 1 hour
 *      - xxm when time interval is < 1 hour and >= 0 minutes
 *      - nil if time interval < 0
 */
+ (NSString *)timeStringForInterval:(NSTimeInterval)interval;


#pragma mark - NSLocale
/**
 * [NSLocale currentLocale] doesn't always work on iOS8.
 * It returns a `displayNameForKey:` value of nil.
 *
 * Ex:
 *     NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: @"US"}];
 *     NSString *countryName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
 *     >>>> countryName will be nil on iOS8 as opposed to "United States".
 *
 * Fix this by hardcoding the locale identifier to en_US
 *
 * @return NSLocale instance
 */
+ (NSLocale *)unitedStatesLocale;

@end
