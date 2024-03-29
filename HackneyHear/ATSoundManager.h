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
#import "L1CDLongAudioSource.h"
#import "CBNode.h"
#define HH_INTRO_SOUND_ENDED_NOTIFICATION @"HH_INTRO_SOUND_ENDED_NOTIFICATION"


@interface ATAudioSource : L1CDLongAudioSource {
@private
    L1SoundType soundType;
    BOOL hasBeenPaused;
}
@property (assign) L1SoundType soundType;
@property (assign) BOOL hasBeenPaused;
@end



@interface ATSoundManager : NSObject<L1CDLongAudioSourceDelegate> {
    NSMutableDictionary * fadingSounds;
    NSMutableDictionary * risingSounds;
    NSMutableDictionary *audioSamples;

    NSString * activeSpeechTrack;
    NSString * activeMusicTrack;
    NSString * activeAtmosTrack;
    NSString * activeBedTrack;
    
    BOOL oneSoundOfTypeAtATime;
    
    
    BOOL introIsPlaying;
    BOOL introBeforeBreakPoint;
    NSDate * introSoundLaunchTime;
    NSMutableDictionary * lastCompletionTime;
    NSTimer * introTimer;
    NSDate * activeSpeechStartTime;
    NSTimeInterval speechTimeForInterruption;
    NSTimeInterval speechDurationForNoInterruption;

    NSMutableArray * globallyPausedSounds;
    
    id delegate;
    
    BOOL globallyPaused;

        
}

@property (readonly) NSString * currentSpeechKey;
@property (retain) id delegate;
@property (readonly) BOOL introBeforeBreakPoint;
@property (readonly) BOOL introIsPlaying;
@property (readonly) BOOL globallyPaused;

//return YES if the sound is actually played.
-(BOOL) playSoundWithFilename:(NSString*)filename key:(NSString*)key type:(CBSoundType) soundType;
-(void) stopSoundWithKey:(NSString*) key;

-(void) startIntro;
-(void) skipIntro;


-(void) fadeInSound:(NSString *) key;
-(void) fadeOutSound:(NSString *) key;

-(void) toggleGlobalPause;
-(void) considerIncreasingBedVolume;
@end
