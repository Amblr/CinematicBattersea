//
//  HHSoundManager.m
//  locations1
//
//  Created by Joe Zuntz on 01/09/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "ATSoundManager.h"
#import "L1Utils.h"
#import "L1Node.h"
#import "CBNode.h"

#define SOUND_UPDATE_TIME_STEP 0.5

#define SOUND_FADE_TIME 5.0
#define SOUND_FADE_TIME_SPEECH 2.0
#define SOUND_FADE_TIME_INTRO 2.0
#define SOUND_FADE_TIME_MUSIC 5.0
#define SOUND_FADE_TIME_ATMOS 5.0
#define SOUND_FADE_TIME_BED 4.0

#define SOUND_RISE_TIME 5.0
#define SOUND_RISE_TIME_SPEECH 2.0
#define SOUND_RISE_TIME_INTRO 2.0
#define SOUND_RISE_TIME_MUSIC 5.0
#define SOUND_RISE_TIME_ATMOS 5.0
#define SOUND_RISE_TIME_BED 4.0

#define SPEECH_RESTART_REWIND 5.0

#define SPEECH_MINIMUM_INTERVAL 1500
#define INTRO_SOUND_BREAK_POINT 68
#define INTRO_SOUND_KEY @"HH_INTRO_SOUND"

#define SPEECH_TIME_FOR_INTERRUPTION_3G 15.0
#define SPEECH_DURATION_FOR_NO_INTERRUPTION_3G 60.0

#define PAUSE_FADE_TIME 1.0
#define PAUSE_RISE_TIME 1.0


@implementation ATAudioSource
-(id) init
{
    self = [super init];
    if (self){
    }
    return self;
}
@synthesize soundType;
@synthesize hasBeenPaused;
@end





@implementation ATSoundManager
@synthesize introBeforeBreakPoint;
@synthesize globallyPaused;
@synthesize delegate;
@synthesize introIsPlaying;
-(id) init
{
    self = [super init];
    if (self){
        audioSamples = [[NSMutableDictionary alloc] initWithCapacity:0];
        activeSpeechTrack=nil;
        activeAtmosTrack=nil;
        activeMusicTrack=nil;
        
        lastCompletionTime = [[NSMutableDictionary alloc] initWithCapacity:0];
        introIsPlaying=NO;
        introTimer=nil;
        
        globallyPaused=NO;
        globallyPausedSounds = [[NSMutableArray alloc] initWithCapacity:0];
        introIsPlaying=NO;
        introBeforeBreakPoint=NO;
        oneSoundOfTypeAtATime = YES;
        
        speechTimeForInterruption = SPEECH_TIME_FOR_INTERRUPTION_3G;
        speechDurationForNoInterruption = SPEECH_DURATION_FOR_NO_INTERRUPTION_3G;
        NSLog(@"Min progress for interruption: %f",speechTimeForInterruption);
        NSLog(@"Duration for never any interruption: %f",speechDurationForNoInterruption);
   
    }
    return self;
    
    
}

-(void) introBreakReached:(NSObject*) dummy
{
    //We have reached the break-point in the audio.  From now on we should 
    //end the intro if any audio is triggered.
    @synchronized(self){
        NSLog(@"Reached Intro Audio Break Point");
        introBeforeBreakPoint=NO;
        if (introTimer) [introTimer invalidate];
        introTimer=nil;
    }
}


-(void) checkIntroBreak:(id)dummy
{
    @synchronized(self){
    //First check if intro has reached the break point.
    if (introIsPlaying && introBeforeBreakPoint){
        ATAudioSource * intro = [audioSamples objectForKey:INTRO_SOUND_KEY];
        if(intro && ([intro currentTime]>INTRO_SOUND_BREAK_POINT)){
            [self introBreakReached:nil];
        }
    }
    }
}

#pragma mark Intro Sound
-(void) skipIntro
{    
    //This quick exit test is outside the test because otherwise we can get a deadlock
    //if another synchronized method here posts a notification to the main view which in turn
    //calls this again.  Bad design on my part.
    if (!introIsPlaying) return;
    @synchronized(self){
    NSLog(@"Skipping Intro");
    [self fadeOutSound:INTRO_SOUND_KEY];
    introIsPlaying=NO;
    introBeforeBreakPoint=NO;
        if (introTimer) [introTimer invalidate];
    }
}




-(void) startIntro
{
    @synchronized(self){

    ATAudioSource * introSound = [[ATAudioSource alloc] init];
    introSound.hasBeenPaused=NO;
    introSound.delegate=self;
    introSound.soundType=CBSoundTypeIntro;
    introSound.key=INTRO_SOUND_KEY;
    NSString * filename = [[NSBundle mainBundle] pathForResource:@"HHIntroSound" ofType:@"mp3"];
    [audioSamples setObject:introSound forKey:INTRO_SOUND_KEY];
    [introSound load:filename];
    [introSound play];
    [introSound release];
    introIsPlaying=YES;
    introBeforeBreakPoint=YES;
    introTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 
                                                  target:self 
                                                selector:@selector(checkIntroBreak:) 
                                                userInfo:nil 
                                                 repeats:YES];

    }
}





-(BOOL) newSpeechNodeShouldStart
{
    @synchronized(self){
    ATAudioSource * sound = nil;
    sound = [audioSamples objectForKey:activeSpeechTrack];
    if (!sound) return YES;
    NSTimeInterval totalTime = [sound totalTime];
    NSTimeInterval currentTime = [sound currentTime];
    NSLog(@"speechNodeShouldStart:  total: %f  current: %f  timeForInterrupt: %f   timeForNeverInterrupt: %f",totalTime,currentTime,speechTimeForInterruption,speechDurationForNoInterruption);
    if (currentTime<speechTimeForInterruption) return NO;
    if (totalTime<speechDurationForNoInterruption) return NO;
    return YES;
    }
}


-(BOOL) playSoundWithFilename:(NSString*)filename key:(NSString*)key type:(CBSoundType) soundType
{
    //Do not start playing new things if globally paused.
    if (globallyPaused) return NO;
    
    @synchronized(self){
    if (soundType==CBSoundTypeSpeech && ![self newSpeechNodeShouldStart]){
        NSLog(@"Not starting new sound  - criterion breached!");
        return NO;
    }
    
    //If we have reached the intro break point
    //then starting any new node should kill the intro
    //we also post the general notificiation.
    //In general this does cause the skipIntro to be invoked twice, annoyingly.
    //I had to put the test for quick return in that method outside the synchronization for that reason.
    if (!introBeforeBreakPoint){
        NSLog(@"Skipping intro because we are playing a new sound that will replace it.");
         [self skipIntro];   
        [[NSNotificationCenter defaultCenter] postNotificationName:HH_INTRO_SOUND_ENDED_NOTIFICATION object:nil];
    }
    
    //If we find the sound in audioSamples then we must have played it before.
    //Otherwise it is new
    ATAudioSource * sound = [audioSamples objectForKey:key];

    //If this is a new sound we will need to load it and then play it.
    //And this is pretty much it.
    if (!sound){
        NSLog(@"New sound found!");
        sound = [[ATAudioSource alloc] init];
        sound.delegate=self;
        sound.soundType=soundType;
        sound.hasBeenPaused=NO;
        sound.key=key;
        [sound load:filename];
        [sound play];
        [audioSamples setObject:sound forKey:key];
        [sound release];
    }
    else{
        NSLog(@"Resuming old sound.");

        //If it is a resumed sound then we can restart it.
        //But we rewind two seconds
        //If speech, restart at full volume immediately
        [sound resume];
        if (sound.soundType==CBSoundTypeSpeech){
            NSLog(@"The resumed sound is speech - jumping back then fading in.");
            [sound timeJump:-SPEECH_RESTART_REWIND];
        }
        //If not speech, just fade in.
        else{
            NSLog(@"The resumed sound is not speech - fading in.");
        }
        [self fadeInSound:sound.key];
    }
    
    // Any sound causes the Bed sounds playing to dip
    if (soundType!=CBSoundTypeBed){
        if (activeBedTrack){
            NSLog(@"Fading bed sound down");
            ATAudioSource * bedSound = [audioSamples objectForKey:activeBedTrack];
            bedSound.volume = 0.25;
        }
    }
        
    //If a new speech track has come along then fade out any existing one.
    if (soundType==CBSoundTypeSpeech){
        if (activeSpeechTrack){
         [self fadeOutSound:activeSpeechTrack];
            NSLog(@"Fading old speech track: %@",activeSpeechTrack);
        }
        activeSpeechTrack=sound.key;
    }
    else if (soundType==CBSoundTypeAtmos){
        if (activeAtmosTrack){
            [self fadeOutSound:activeAtmosTrack];
            NSLog(@"Fading old atmos track: %@",activeAtmosTrack);
        }
        activeAtmosTrack=sound.key;
    }
    else if (soundType==CBSoundTypeMusic){
        if (activeMusicTrack){
            [self fadeOutSound:activeMusicTrack];
            NSLog(@"Fading old music track: %@",activeMusicTrack);
        }
        activeMusicTrack=sound.key;
    }
    else if (soundType==CBSoundTypeBed){
        if (activeBedTrack){
            [self fadeOutSound:activeBedTrack];
            NSLog(@"Fading old music track: %@",activeBedTrack);
        }
        activeBedTrack=sound.key;
    }
        
        



        if (soundType==CBSoundTypeAtmos) NSLog(@"Playing atmos %@",filename);
        else if (soundType==CBSoundTypeMusic) NSLog(@"Playing music %@",filename);
        else if (soundType==CBSoundTypeSpeech) NSLog(@"Playing speech %@",filename);
        else if (soundType==CBSoundTypeBed) NSLog(@"Playing bed %@",filename);
        else NSLog(@"Playing something mysterious: %@",filename);
    }
    
    return YES;
}


-(void) stopSoundWithKey:(NSString*) key
{
    if (globallyPaused) return;
    [self fadeOutSound:key];
    
}

-(float) fadeTimeForSound:(ATAudioSource*)sound
{
    switch (sound.soundType) {
        case CBSoundTypeAtmos:
            return SOUND_FADE_TIME_ATMOS;
            break;
        case CBSoundTypeMusic:
            return SOUND_FADE_TIME_MUSIC;
            break;
        case CBSoundTypeSpeech:
            return SOUND_FADE_TIME_SPEECH;
            break;
        case CBSoundTypeIntro:
            return SOUND_FADE_TIME_INTRO;
            break;
        case CBSoundTypeBed:
            return SOUND_FADE_TIME_BED;
            break;
        default:
            return SOUND_FADE_TIME;
            break;
    }
}

-(float) riseTimeForSound:(ATAudioSource*)sound
{
    switch (sound.soundType) {
        case CBSoundTypeAtmos:
            return SOUND_RISE_TIME_ATMOS;
            break;
        case CBSoundTypeMusic:
            return SOUND_RISE_TIME_MUSIC;
            break;
        case CBSoundTypeSpeech:
            return SOUND_RISE_TIME_SPEECH;
            break;
        case CBSoundTypeIntro:
            return SOUND_RISE_TIME_INTRO;
            break;
        case CBSoundTypeBed:
            return SOUND_RISE_TIME_BED;
            break;
        default:
            return SOUND_RISE_TIME;
            break;
    }
}


-(void) fadeOutSound:(NSString *) key
{
    
    ATAudioSource * sound = [audioSamples objectForKey:key];
    [sound fadeOut:[self fadeTimeForSound:sound]];
}

-(void) fadeInSound:(NSString *) key
{
    ATAudioSource * sound = [audioSamples objectForKey:key];
    [sound riseIn:[self riseTimeForSound:sound]];
}


-(void) l1CDAudioSourceDidFinishFading:(L1CDLongAudioSource *)source
{
    @synchronized(self){
    ATAudioSource * sound = (ATAudioSource*) source;
    [sound pause];
    if (globallyPaused){
        //The rest of this function removes completed tracks 
        //during pause, which we do not want to do if we are fading because we are paused
        return;
        }
    if (sound.soundType==CBSoundTypeIntro) [audioSamples removeObjectForKey:sound.key];
    //This is no longer the active speech track as it has finished.
    if ([sound.key isEqualToString:activeSpeechTrack]) activeSpeechTrack=nil;
    if ([sound.key isEqualToString:activeAtmosTrack]) activeAtmosTrack=nil;
    if ([sound.key isEqualToString:activeMusicTrack]) activeMusicTrack=nil;
    if ([sound.key isEqualToString:activeBedTrack]) activeBedTrack=nil;
    NSLog(@"Done fading %@.",sound.key);
    [self considerIncreasingBedVolume];
        
    }
}

-(void) considerIncreasingBedVolume
{
    if (!activeBedTrack) return;
    if (activeSpeechTrack || activeMusicTrack || activeAtmosTrack) return;
    ATAudioSource * bedTrack = [audioSamples objectForKey:activeBedTrack];
    if (bedTrack.isFading) return;
    if (bedTrack.isRising) return;
    NSLog(@"Setting volume of sound bed back to 1");
    bedTrack.volume=1.0;
}

-(void) l1CDAudioSourceDidFinishRising:(L1CDLongAudioSource *)source
{
    @synchronized(self){
    ATAudioSource * sound = (ATAudioSource*) source;
    NSLog(@"Done rising %@",sound.key);
    }
}





- (void) cdAudioSourceDidFinishPlaying:(L1CDLongAudioSource *) audioSource
{
    @synchronized(self){
    
    // This sound *should* be an instance of our subclass.  Otherwise not sure what
    // is happening
    if (![audioSource isKindOfClass:[ATAudioSource class]]) return;
    ATAudioSource * source = (ATAudioSource*) audioSource;
    NSLog(@"Sound finished: %@",source.key);
    
    
//    if ([source.key isEqualToString:activeSpeechTrack]) activeSpeechTrack=nil;
//    if ([source.key isEqualToString:activeMusicTrack]) activeMusicTrack=nil;
//    if ([source.key isEqualToString:activeAtmosTrack]) activeAtmosTrack=nil;
//    if ([source.key isEqualToString:activeBedTrack]) activeBedTrack=nil;
    
        
    // If this track is the intro track then note that it has stopped playing so we do
    // not try to stop it again.  We also post a notificiation that tells the main view controller
    // (and anyone else who wants to know) that it has finsihed.
    if ([source.key isEqualToString:INTRO_SOUND_KEY]){
        introIsPlaying=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:HH_INTRO_SOUND_ENDED_NOTIFICATION object:nil];
    }
    
    //We want to repeat music and atmost when they finish
    if ((source.soundType==CBSoundTypeAtmos || source.soundType==CBSoundTypeMusic || source.soundType==CBSoundTypeSpeech || source.soundType==CBSoundTypeBed)){
        [source play];
    }
    else
        // For other sounds we just note that they are no longer rising or falling and remove the reference
        // to them so they are freed.
    {
        [audioSamples removeObjectForKey:source.key];
        SEL sel = @selector(soundManager:soundDidFinish:);
        if ([self.delegate respondsToSelector:sel]){
            [self.delegate performSelector:sel withObject:self withObject:source.key];
        }
    }
    }
    
}

-(void) unpauseGlobal{
    @synchronized(self){
    for (ATAudioSource * sound in globallyPausedSounds){
        if (![sound isPlaying]){
            [sound resume]; //we only resume if the pause-fade finished.   
            NSLog(@"Resuming %@",sound.key);
        }else{
            NSLog(@"Still playing: %@",sound.key);
        }
        
        [sound riseIn:PAUSE_RISE_TIME];
    }
    [globallyPausedSounds removeAllObjects];
    globallyPaused=NO;    
    }
}


-(void) pauseGlobal{
    @synchronized(self){
    for (NSString * key in audioSamples){
        ATAudioSource * sound = [audioSamples objectForKey:key];
        if ([sound isPlaying]){
            [sound fadeOut:PAUSE_FADE_TIME];
            NSLog(@"Pausing %@",sound.key);
            [globallyPausedSounds addObject:sound];

        }
    }
    globallyPaused=YES;
    }
}

-(void) toggleGlobalPause
{
    @synchronized(self){
    if (globallyPaused){
        [self unpauseGlobal];
    }
    else{
        [self pauseGlobal];
    }
    }
}



-(NSString*) currentSpeechKey
{
    return activeSpeechTrack;
}



@end
