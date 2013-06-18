//
//  ATNode.m
//  AmblrTravel
//
//  Created by Joe Zuntz on 17/01/2013.
//  Copyright (c) 2013 Imperial College London. All rights reserved.
//

#import "CBNode.h"

@implementation CBNode
@synthesize soundType;

-(void) determineType
{
    self.soundType = CBSoundTypeSpeech;
    for (NSString * tag in self.tags){
        if ([[tag lowercaseString] isEqualToString:@"type-s"]) self.soundType = CBSoundTypeSpeech;
        if ([[tag lowercaseString] isEqualToString:@"type-bed"]) self.soundType = CBSoundTypeBed;
        if ([[tag lowercaseString] isEqualToString:@"type-a"]) self.soundType = CBSoundTypeAtmos;
        if ([[tag lowercaseString] isEqualToString:@"type-m"]) self.soundType = CBSoundTypeMusic;
    }
    
}

-(void) setStateFromDictionary:(NSDictionary *)nodeDictionary
{
    [super setStateFromDictionary:nodeDictionary];
    [self determineType];
}

@end
