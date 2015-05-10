//
//  GRVContact+Section.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContact+Section.h"
#import "GRVContact+AddressBook.h"

@implementation GRVContact (Section)

#pragma mark - Transient Properties
- (NSString *)sectionIdentifier
{
    // Create and cache the section identifier on demand
    [self willAccessValueForKey:@"sectionIdentifier"];
    NSString *identifier = [self primitiveValueForKey:@"sectionIdentifier"];
    [self didAccessValueForKey:@"sectionIdentifier"];
    
    if (!identifier) {
        // Sections are organized by first letter of full name. So create
        // section identififer based on that.
        NSString *fullName = [self fullName];
        if ([fullName length] > 0) {
            identifier = [[fullName substringToIndex:1] uppercaseString];
        } else {
            identifier = @"#"; // if no name then this goes in the # section
        }
        [self setPrimitiveValue:identifier forKey:@"sectionIdentifier"];
    }
    
    return identifier;
}


#pragma mark - Component Properties Setters
- (void)setFirstName:(NSString *)firstName
{
    // if the firstName changes, the section identifier becomes invalid.
    [self willChangeValueForKey:@"firstName"];
    [self willChangeValueForKey:@"sectionIdentifier"];
    
    [self setPrimitiveValue:firstName forKey:@"firstName"];
    
    [self didChangeValueForKey:@"firstName"];
    [self didChangeValueForKey:@"sectionIdentifier"];
}

- (void)setLastName:(NSString *)lastName
{
    // if the firstName changes, the section identifier becomes invalid.
    [self willChangeValueForKey:@"lastName"];
    [self willChangeValueForKey:@"sectionIdentifier"];
    
    [self setPrimitiveValue:lastName forKey:@"lastName"];
    
    [self didChangeValueForKey:@"lastName"];
    [self didChangeValueForKey:@"sectionIdentifier"];
}


#pragma mark - Key path dependencies
+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier
{
    // If the value of the contact's first name or last name changes,
    // the section identifier may change as well.
    return [NSSet setWithArray:@[@"firstName", @"lastName"]];
}

@end
