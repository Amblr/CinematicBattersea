//
//  ATSoundManager2.h
//  AmblrTravel
//
//  Created by Joe Zuntz on 18/01/2013.
//  Copyright (c) 2013 Imperial College London. All rights reserved.
//

#import <Foundation/Foundation.h>


// Think about the logic here.
// What do we want?
typedef enum ATInterruptBehaviour
{
    ATInterruptBehaviourNever      = 1<<0,
    ATInterruptBehaviourAlways     = 1<<1,
    ATInterruptBehaviourOnlyBefore = 1<<2,
    ATInterruptBehaviourOnlyAfter  = 1<<3,    
    ATInterruptBehaviourOnlyWith   = 1<<4,
    ATInterruptBehaviourOnlyOn     = 1<<5,
    ATInterruptBehaviourExceptWith = 1<<6,
    ATInterruptBehaviourExceptOn   = 1<<7,
} ATInterruptBehaviour;


typedef enum ATReplayBehaviour
{
    ATReplayBehaviourNever  = 1<<0,
    ATReplayBehaviourAlways = 1<<1,
    ATReplayBehaviourBefore = 1<<2,
    ATReplayBehaviourAfter  = 1<<3,
} ATReplayBehaviour;

typedef enum ATEndBehaviour
{
    ATEndBehaviourStop,
    ATEndBehaviourReplay,
} ATEndBehaviour;

typedef enum ATResumeBehaviour
{
    ATResumeBehaviourSame,
    ATResumeBehaviourStart,
    ATResumeBehaviourEarlier,
} ATResumeBehaviour;



@interface ATSoundBehaviour : NSObject
{
    NSString * key;
    ATInterruptBehaviour interruptBehaviour;
    ATReplayBehaviour replayBehaviour;
    ATEndBehaviour endBehaviour;
    ATResumeBehaviour resumeBehaviour;
    
    NSMutableDictionary * lastPlayedTime;
    NSDate * startTime;
    NSString * currentlyPlayingSound;

    NSSet * superiorSounds;
    NSSet * inferiorSounds;
    
    float interruptTime;
    float replayTime;

    float resumeOffset;
    
    float fadeTime;
    float riseOffset;

}
@property (retain) NSString * key;

-(id) initWithDictionary:(NSDictionary*) dictionary;
-(BOOL) shouldInterruptWithSound:(NSString*)key;
-(BOOL) shouldPlaySound:(NSString*)key;
-(BOOL) shouldReplayFinishedSound:(NSString*)key;
-(float) riseTimeForSound:(NSString*)key;
-(float) fallTimeForSound:(NSString*)key;


@end



@interface ATSoundManager2 : NSObject
{
    NSMutableDictionary * soundClasses;
    
}

-(void) offerSound:(NSString*)filename ofType:(NSString*)soundType;
-(NSString*) currentlyPlayingSoundOfType:(NSString*)soundType;
-(void) playSpecialSound:(NSString*)filename;

-(void) pause;
-(void) unPause;
-(void) togglePause;
-(BOOL) isPaused;

@end

// Possible sound behaviours
//  - Play without ever being interrupted - DEFAULT
//  - Play, interrupted always
//  - Play, interrupted after certain time
//  - Play, interrupted before certain time (?)
//  - Play, interrupted only if delegate says so
//  - Play, interrupted only by certain sounds
//  - End, repeat
//  - End, stop
//  - End, delegate
//  - Replay, always
//  - Replay, only after certain time
//  - Replay, only if condition previously met
//  - Restart, from place
//  - Restart, from start
//  - Restart, from earlier
//  - Fade in/out, instant
//  - Fade in/out, timed

/*
 @{
    @"interrupt": @"never"; // always interrupt - DEFAULT
    @"interrupt": @"always"; // always interrupt
    @"interrupt": @"after 45.0"; // only after this much time
    @"interrupt": @"before 45.0"; // only before this much time
    @"interrupt": @"only-with special1 special2"; // only if the new sound one of these
    @"interrupt": @"only-on boring1 boring2 boring3"; // only if the old sound is one of these
    @"interrupt": @"except-with boring4 boring5 boring6"; // only if the new sound is one of these
    @"interrupt": @"except-on special1 special2 special3 "; // only if the old sound is this key

?    @"interrupt": @"range 15.0 45.0"; // only in this range of time
?    @"interrupt": @"delegate"; // only if delegate says so

    @"end": @"stop" // when sound finishes, just stop - DEFAULT
    @"end": @"repeat"; // when finishes, start sound again

?    @"end": @"delegate"; // start sound again if delegate says so

    @"replay": @"always"; // always replay if offered after the end
    @"replay": @"never"; // never replay if offered after the end
    @"replay": @"after 45.0"; //   only after
    @"replay": @"before 45.0"; // only before this much time
    @"replay": @"range 15.0 45.0"; // only in this range of time
    @"replay": @"only special1  special2"; // only these sounds
    @"replay": @"except boring1 boring2"; // not these sounds

?    @"replay": @"delegate"; // only in this range of time

    @"resume": @"same"; // when resuming, start at the same place DEFAULT
    @"resume": @"time 0"; //  start at the beginning
    @"resume": @"early 4"; // start 4 seconds before current position

?    @"resume": @delegate; //  ask the delegate what to do

 
    @"rise": @"2.0"; // rise time
    @"fade": @"2.0"; // fall time
 
 
 }
 
 */


// Over-rides - do something regardless of behaviour
