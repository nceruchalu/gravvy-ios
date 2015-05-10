//
//  GRVFormatterUtils.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVFormatterUtils.h"
#import "NBPhoneNumberUtil+Shared.h"
#import "NBPhoneNumber.h"


#pragma mark - Constants
// seconds in minute, hour, day per the Gregorian Calendar.
static const NSInteger kSecondsInMinute    = 60;
static const NSInteger kSecondsInHour      = 3600;
static const NSInteger kSecondsInDay       = 86400;


@implementation GRVFormatterUtils

#pragma mark - Phone Number
+ (NSString *)formatPhoneNumber:(NSString *)phoneNumber
                   numberFormat:(NBEPhoneNumberFormat)numberFormat
                  defaultRegion:(NSString *)regionCode
                          error:(NSError**)error
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedUtilInstance];
    NBPhoneNumber *phoneNumberObj = [phoneUtil parse:phoneNumber
                                       defaultRegion:regionCode
                                               error:error];
    
    NSString *formattedPhoneNumber = nil;
    
    // If there's an error object then check for no error
    // Get a formatted phone number only if phone number is valid
    if ((!error || !(*error)) && [phoneUtil isValidNumber:phoneNumberObj]) {
        formattedPhoneNumber = [phoneUtil format:phoneNumberObj
                                    numberFormat:numberFormat
                                           error:error];
    }
    
    return formattedPhoneNumber;
}


#pragma mark - String
+ (NSNumber *)stringToNum:(NSString *)string
{
    // if the number formatters isn't already setup, create it and cache for reuse.
    static NSNumberFormatter *numberFormatter = nil;
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    
    return [numberFormatter numberFromString:string];
}


#pragma mark - Date
+ (NSDateFormatter *)generateRFC3339DateFormatter
{
    // If the date formatter isn't already setup, create it and cache for reuse.
    // It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *rfc3339DateFormatter = nil;
    
    if (!rfc3339DateFormatter) {
        rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"];
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return rfc3339DateFormatter;
}

+ (NSString *)dayAndYearStringForDate:(NSDate *)date
{
    // If the date formatters isn't already setup, create it and cache for reuse.
    // It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *dayAndYearStringFormatter = nil;
    if (!dayAndYearStringFormatter) {
        dayAndYearStringFormatter = [[NSDateFormatter alloc] init];
        [dayAndYearStringFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dayAndYearStringFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    return [dayAndYearStringFormatter stringFromDate:date];
}

+ (NSString *)dayStringForDate:(NSDate *)date
{
    // If the date formatters isn't already setup, create it and cache for reuse.
    // It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *dayStringFormatter = nil;
    if (!dayStringFormatter) {
        dayStringFormatter = [[NSDateFormatter alloc] init];
        [dayStringFormatter setDateFormat:@"EEE. MMM d"];
    }
    
    return [dayStringFormatter stringFromDate:date];
}

+ (NSString *)timeStringForDate:(NSDate *)date
{
    // If the date formatters isn't already setup, create it and cache for reuse.
    // It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *timeStringFormatter = nil;
    if (!timeStringFormatter) {
        timeStringFormatter = [[NSDateFormatter alloc] init];
        [timeStringFormatter setDateFormat:@"hh:mm a"];
    }
    
    return [timeStringFormatter stringFromDate:date];
}

+ (NSString *)dayAndTimeStringForDate:(NSDate *)date
{
    NSString *dayLabel = [GRVFormatterUtils dayStringForDate:date];
    NSString *timeLabel = [GRVFormatterUtils timeStringForDate:date];
    
    return [NSString stringWithFormat:@"%@, %@", dayLabel, timeLabel];
}

+ (NSString *)timeStringForInterval:(NSTimeInterval)interval
{
    NSString *timeLabel = nil;
    
    if (interval >= kSecondsInDay) {
        timeLabel = [NSString stringWithFormat:@"%dd",(int)(interval/kSecondsInDay)];
    } else if (interval >= kSecondsInHour) {
        timeLabel = [NSString stringWithFormat:@"%dh",(int)(interval/kSecondsInHour)];
    } else if (interval >= 0) {
        timeLabel = [NSString stringWithFormat:@"%dm",(int)(interval/kSecondsInMinute)];
    }
    
    return timeLabel;
}


#pragma mark - NSLocale
+ (NSLocale *)unitedStatesLocale
{
    NSDictionary *localeComponents = @{NSLocaleLanguageCode : @"en",
                                       NSLocaleCountryCode : @"US"};
    NSString *identifier = [NSLocale localeIdentifierFromComponents:localeComponents];
    return [NSLocale localeWithLocaleIdentifier:identifier];
}

@end
