//
//  GRVVideo+Section.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/1/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideo+Section.h"

@implementation GRVVideo (Section)

#pragma mark - Transient Properties
- (NSString *)sectionIdentifier
{
    
    // Create and cache the section identifier on demand.
    
    [self willAccessValueForKey:@"sectionIdentifier"];
    NSString *identifier = [self primitiveValueForKey:@"sectionIdentifier"];
    [self didAccessValueForKey:@"sectionIdentifier"];
    
    if (!identifier)
    {
        // Sections are organized in reverse createdAt values
        NSTimeInterval timeInterval= [self.createdAt timeIntervalSinceReferenceDate];
        identifier = [NSString stringWithFormat:@"%f", timeInterval];
        [self setPrimitiveValue:identifier forKey:@"sectionIdentifier"];
    }
    
    return identifier;
}


#pragma mark - Component Properties Setters

- (void)setCreatedAt:(NSDate *)createdAt
{
    // if the createdAt changes, the section identifier becomes invalid.
    [self willChangeValueForKey:@"createdAt"];
    [self willChangeValueForKey:@"sectionIdentifier"];
    
    [self setPrimitiveValue:createdAt forKey:@"createdAt"];
    [self setPrimitiveValue:nil forKey:@"sectionIdentifier"];
    
    [self didChangeValueForKey:@"createdAt"];
    [self didChangeValueForKey:@"sectionIdentifier"];
}


#pragma mark - Key path dependencies
+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier
{
    // If the value of createdAt changes, the section identifier may change as well.
    return [NSSet setWithArray:@[@"createdAt"]];
}

@end
