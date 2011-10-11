//
//  HHSoundManager.h
//  locations1
//
//  Created by Joe Zuntz on 01/09/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleAudioEngine.h"
#import "L1Scenario.h"

#define HH_INTRO_SOUND_ENDED_NOTIFICATION @"HH_INTRO_SOUND_ENDED_NOTIFICATION"



@interface L1CDLongAudioSource : CDLongAudioSource
{
    L1SoundType soundType;
    NSString * key;
    BOOL isFading;
    BOOL isRising;
}

-(void) timeJump:(NSTimeInterval) deltaTime;
-(NSTimeInterval) currentTime;
-(NSTimeInterval) totalTime;

@property (assign) L1SoundType soundType;
@property (retain) NSString * key;
@end




@interface HHSoundManager : NSObject<CDLongAudioSourceDelegate> {
    NSMutableDictionary * fadingSounds;
    NSMutableDictionary * risingSounds;
    NSMutableDictionary *audioSamples;

    NSString * activeSpeechTrack;
    NSString * activeMusicTrack;
    NSString * activeAtmosTrack;
    
    BOOL oneSoundOfTypeAtATime;
    
    
    BOOL introIsPlaying;
    BOOL introBeforeBreakPoint;
    NSDate * introSoundLaunchTime;
    NSMutableDictionary * lastCompletionTime;
    NSTimer * volumeChangeTimer;
    NSDate * activeSpeechStartTime;
    NSTimeInterval speechTimeForInterruption;
    NSTimeInterval speechDurationForNoInterruption;

    NSMutableArray * globallyPausedSounds;
    
    id delegate;
    
    BOOL globallyPaused;

        
}

@property (retain) id delegate;
@property (readonly) BOOL introBeforeBreakPoint;
@property (readonly) BOOL globallyPaused;

//return YES if the sound is actually played.
-(BOOL) playSoundWithFilename:(NSString*)filename key:(NSString*)key type:(L1SoundType) soundType;
-(void) stopSoundWithKey:(NSString*) key;

-(void) startIntro;
-(void) skipIntro;


-(void) fadeInSound:(NSString *) key;
-(void) fadeOutSound:(NSString *) key;

-(void) toggleGlobalPause;

@end
