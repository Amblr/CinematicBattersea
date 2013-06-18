//
//  ATSoundManager2.m
//  AmblrTravel
//
//  Created by Joe Zuntz on 18/01/2013.
//  Copyright (c) 2013 Imperial College London. All rights reserved.
//

#import "ATSoundManager2.h"

@implementation ATSoundBehaviour
@synthesize key;

-(BOOL) shouldInterruptWithSound:(NSString*) newKey;
{
    float timePlayed = -[startTime timeIntervalSinceNow];
    switch (interruptBehaviour) {
        case ATInterruptBehaviourAlways:
            return YES;
            break;
        case ATInterruptBehaviourNever:
            return NO;
            break;
        case ATInterruptBehaviourOnlyBefore:
            return timePlayed<interruptTime;
            break;
        case ATInterruptBehaviourOnlyAfter:
            return timePlayed>interruptTime;
            break;
        case ATInterruptBehaviourOnlyWith:
            return [superiorSounds member:newKey];
            break;
        case ATInterruptBehaviourExceptWith:
            return [inferiorSounds member:newKey];
            break;
        case ATInterruptBehaviourOnlyOn:
            return [inferiorSounds member:currentlyPlayingSound];
            break;
        case ATInterruptBehaviourExceptOn:
            return [superiorSounds member:currentlyPlayingSound];
            break;
        default:
            return NO;
            break;
    }
}

-(BOOL) shouldPlaySound:(NSString*)newKey
{
    NSDate * lastPlayed = [lastPlayedTime valueForKey:newKey];
    NSTimeInterval timeSinceLastPlayed = -[lastPlayed timeIntervalSinceNow];
    switch (replayBehaviour) {
        case ATReplayBehaviourNever:
            return NO;
            break;
        case ATReplayBehaviourAlways:
            return YES;
            break;
        case ATReplayBehaviourBefore:
            return timeSinceLastPlayed<replayTime;
            break;
        case ATReplayBehaviourAfter:
            return timeSinceLastPlayed>replayTime;
            break;
        default:
            return YES;
            break;
    }
    //    ATReplayBehaviourNever  = 1<<0,
    //    ATReplayBehaviourAlways = 1<<1,
    //    ATReplayBehaviourBefore = 1<<2,
    //    ATReplayBehaviourAfter  = 1<<3,
    //    ATReplayBehaviourExcept = 1<<4,
    //    ATReplayBehaviourOnly   = 1<<5,
    
}


@end

@implementation ATSoundManager2



@end
