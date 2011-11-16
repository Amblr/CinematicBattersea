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
#define HH_INTRO_SOUND_ENDED_NOTIFICATION @"HH_INTRO_SOUND_ENDED_NOTIFICATION"


@interface HHAudioSource : L1CDLongAudioSource {
@private
    L1SoundType soundType;
}
@property (assign) L1SoundType soundType;
@end




@interface HHSoundManager : NSObject<L1CDLongAudioSourceDelegate> {
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
@property (readonly) NSString * currentSpeechKey;
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
