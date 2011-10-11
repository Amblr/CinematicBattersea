//
//  HHSoundManager.m
//  locations1
//
//  Created by Joe Zuntz on 01/09/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "HHSoundManager.h"
#import "L1Utils.h"
#import "L1Node.h"

#define SOUND_UPDATE_TIME_STEP 0.5

#define SOUND_FADE_TIME 5.0
#define SOUND_FADE_TIME_SPEECH 2.0
#define SOUND_FADE_TIME_INTRO 2.0
#define SOUND_FADE_TIME_MUSIC 5.0
#define SOUND_FADE_TIME_ATMOS 5.0

#define SOUND_RISE_TIME 5.0
#define SOUND_RISE_TIME_SPEECH 2.0
#define SOUND_RISE_TIME_INTRO 2.0
#define SOUND_RISE_TIME_MUSIC 5.0
#define SOUND_RISE_TIME_ATMOS 5.0

#define SPEECH_RESTART_REWIND 5.0

#define SPEECH_MINIMUM_INTERVAL 1500
#define INTRO_SOUND_BREAK_POINT 68
#define INTRO_SOUND_KEY @"HH_INTRO_SOUND"

#define SPEECH_TIME_FOR_INTERRUPTION_3G 15.0
#define SPEECH_DURATION_FOR_NO_INTERRUPTION_3G 60.0



@implementation L1CDLongAudioSource
@synthesize soundType;
@synthesize key;

-(void) timeJump:(NSTimeInterval) deltaTime
{
    NSTimeInterval currentTime = audioSourcePlayer.currentTime;
    NSTimeInterval newTime = currentTime+deltaTime;
    NSTimeInterval maxTime = audioSourcePlayer.duration;
    if (newTime<0.0) newTime=0.0;
    if (newTime>maxTime) newTime=maxTime-0.01; //Give some buffer just before end, just in case.
    NSLog(@"Jumping sound time from %f to %f",currentTime,newTime);
    [audioSourcePlayer setCurrentTime:newTime];
}

-(NSTimeInterval) currentTime
{
    return audioSourcePlayer.currentTime;
}

-(NSTimeInterval) totalTime
{
    return audioSourcePlayer.duration;
}


@end





@implementation HHSoundManager
@synthesize introBeforeBreakPoint;
@synthesize globallyPaused;
@synthesize delegate;

-(id) init
{
    self = [super init];
    if (self){
        audioSamples = [[NSMutableDictionary alloc] initWithCapacity:0];
        activeSpeechTrack=nil;
        activeAtmosTrack=nil;
        activeMusicTrack=nil;
        fadingSounds = [[NSMutableDictionary alloc] initWithCapacity:0];
        risingSounds = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        lastCompletionTime = [[NSMutableDictionary alloc] initWithCapacity:0];
        introIsPlaying=NO;
        volumeChangeTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateSoundVolumes:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:volumeChangeTimer forMode:NSDefaultRunLoopMode];
        
        globallyPaused=NO;
        globallyPausedSounds = [[NSMutableArray alloc] initWithCapacity:0];

        oneSoundOfTypeAtATime = YES;
        
        if (oneSoundOfTypeAtATime){
            speechTimeForInterruption = SPEECH_TIME_FOR_INTERRUPTION_3G;
            speechDurationForNoInterruption = SPEECH_DURATION_FOR_NO_INTERRUPTION_3G;
        }
        else{
            speechTimeForInterruption = 0.0;
            speechDurationForNoInterruption = 0.0;
        }
        NSLog(@"Min progress for interruption: %f",speechTimeForInterruption);
        NSLog(@"Duration for never any interruption: %f",speechDurationForNoInterruption);
   
    }
    return self;
    
    
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
    }
}


-(void) introBreakReached:(NSObject*) dummy
{
    @synchronized(self){
    //We have reached the break-point in the audio.  From now on we should 
    //end the intro if any audio is triggered.
    NSLog(@"Reached Intro Audio Break Point");
    introBeforeBreakPoint=NO;
    }
}


-(void) startIntro
{
    @synchronized(self){

    L1CDLongAudioSource * introSound = [[L1CDLongAudioSource alloc] init];
    introSound.delegate=self;
    introSound.soundType=L1SoundTypeIntro;
    introSound.key=INTRO_SOUND_KEY;
    NSString * filename = [[NSBundle mainBundle] pathForResource:@"HHIntroSound" ofType:@"mp3"];
    [audioSamples setObject:introSound forKey:INTRO_SOUND_KEY];
    [introSound load:filename];
    [introSound play];
    [introSound release];
    introIsPlaying=YES;
    introBeforeBreakPoint=YES;
    [self performSelector:@selector(introBreakReached:) withObject:nil afterDelay:INTRO_SOUND_BREAK_POINT];
    }
}


-(void) fadeOutSound:(NSString *) key
{
    @synchronized(self){

    L1CDLongAudioSource * sound = [audioSamples objectForKey:key];
    if (!sound){
        NSLog(@"Tried to fade out sound not found: %@",sound.key);
        return;
    }
        if ([key isEqualToString:activeSpeechTrack]) activeSpeechTrack=nil;
        if (oneSoundOfTypeAtATime){
            if ([key isEqualToString:activeAtmosTrack]) activeAtmosTrack=nil;
            if ([key isEqualToString:activeMusicTrack]) activeMusicTrack=nil;
        }
    //If the sound is already rising then we should over-rule this and start fading.
        if ([risingSounds objectForKey:key]){
            [risingSounds removeObjectForKey:key];
        }
        [fadingSounds setObject:sound forKey:key];
    }
}

-(void) fadeInSound:(NSString *) key
{
    @synchronized(self){
    L1CDLongAudioSource * sound = [audioSamples objectForKey:key];
    if (!sound){
        NSLog(@"Tried to fade out sound not found: %@",sound.key);
        return;
    }

    //If the sound is already fading then we should over-rule this and start rising.
        if ([fadingSounds objectForKey:key]){
            [fadingSounds removeObjectForKey:key];
        }
        [risingSounds setObject:sound forKey:key];
    }
}


-(BOOL) newSpeechNodeShouldStart
{
    @synchronized(self){
    L1CDLongAudioSource * sound = nil;
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


//
//-(void) updatePlayingListOn:(NSArray*) nodesOn off:(NSArray*) nodesOff
//{
//    NSMutableArray * soundsOn = [NSMutableArray arrayWithCapacity:0];
//    NSMutableArray * soundsOff = [NSMutableArray arrayWithCapacity:0];
//    L1SoundType soundType;
//    
//    for (L1Node * node in nodesOn){
//        for(L1Resource * resource in node.resources){
//            if ([resource.type isEqualToString:@"sound"]){
//                if (resource.local){
//                    soundType = resource.soundType;
//                    [soundsOn addObject:[resource localFileName]];
//                }
//                else{
//                    [resource downloadResourceData];
//                }
//                
//            }
//        }
//    }
//    
//}

-(BOOL) playSoundWithFilename:(NSString*)filename key:(NSString*)key type:(L1SoundType) soundType
{
    //Do not start playing new things if globally paused.
    if (globallyPaused) return NO;
    
    @synchronized(self){
    if (soundType==L1SoundTypeSpeech){
        NSDate * lastPlay = [lastCompletionTime objectForKey:key];
        NSTimeInterval timeSinceLastPlay = [[NSDate date] timeIntervalSinceDate:lastPlay];
        if (lastPlay) NSLog(@"Sound %@ was last completed at %f",key,timeSinceLastPlay);
        else NSLog(@"Sound has never previously been completed");

        if (lastPlay && (timeSinceLastPlay<SPEECH_MINIMUM_INTERVAL)){
            NSLog(@"Not playing sound - too recent.");
            return NO;
        }
        
        if (![self newSpeechNodeShouldStart]){
            NSLog(@"Not starting new sound  - criterion breached!");
            return NO;
        }
    }
    
    //If we have reached the intro break point
    //then starting any new node should kill the intro
    //we also post the general notificiation.
    //In general this does cause the skipIntro to be invoked twice, annoyingly.
    //I had to put the test for quick return in that method outside the synchronization for that reason.
    if (!introBeforeBreakPoint){
         [self skipIntro];   
        [[NSNotificationCenter defaultCenter] postNotificationName:HH_INTRO_SOUND_ENDED_NOTIFICATION object:nil];
    }
    
    //If we find the sound in audioSamples then we must have played it before.
    //Otherwise it is new
    L1CDLongAudioSource * sound = [audioSamples objectForKey:key];

    //If this is a new sound we will need to load it and then play it.
    //And this is pretty much it.
    if (!sound){
        NSLog(@"New sound found!");
        sound = [[L1CDLongAudioSource alloc] init];
        sound.delegate=self;
        sound.soundType=soundType;
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
        if (sound.soundType==L1SoundTypeSpeech){
            NSLog(@"The resumed sound is speech - jumping back then fading in.");
            [sound timeJump:-SPEECH_RESTART_REWIND];
        }
        //If not speech, fade in.
        else{
            NSLog(@"The resumed sound is not speech - fading in.");
        }
        [self fadeInSound:sound.key];

        
    }
    
    //If a new speech track has come along then fade out any existing one.
    if (soundType==L1SoundTypeSpeech){
        if (activeSpeechTrack){
         [self fadeOutSound:activeSpeechTrack];
            NSLog(@"Fading old speech track: %@",activeSpeechTrack);
        }
        activeSpeechTrack=sound.key;
    }
    if (oneSoundOfTypeAtATime){
        if (soundType==L1SoundTypeAtmos){
            if (activeAtmosTrack){
                [self fadeOutSound:activeAtmosTrack];
                NSLog(@"Fading old atmos track: %@",activeAtmosTrack);
            }
            activeAtmosTrack=sound.key;
        }
        else if (soundType==L1SoundTypeMusic){
            if (activeMusicTrack){
                [self fadeOutSound:activeMusicTrack];
                NSLog(@"Fading old music track: %@",activeMusicTrack);
            }
            activeMusicTrack=sound.key;
        }
        
        
    }


        if (soundType==L1SoundTypeAtmos) NSLog(@"Playing atmos %@",filename);
        else if (soundType==L1SoundTypeMusic) NSLog(@"Playing music %@",filename);
        else if (soundType==L1SoundTypeSpeech) NSLog(@"Playing speech %@",filename);
        else if (soundType==L1SoundTypeUnknown) NSLog(@"Playing unkown sound type %@",filename);
        else NSLog(@"Playing something mysterious: %@",filename);
    }
    
    return YES;
}


-(void) stopSoundWithKey:(NSString*) key
{
    if (globallyPaused) return;
    [self fadeOutSound:key];
    
}

-(float) fadeTimeForSound:(L1CDLongAudioSource*)sound
{
    switch (sound.soundType) {
        case L1SoundTypeAtmos:
            return SOUND_FADE_TIME_ATMOS;
            break;
        case L1SoundTypeMusic:
            return SOUND_FADE_TIME_MUSIC;
            break;
        case L1SoundTypeSpeech:
            return SOUND_FADE_TIME_SPEECH;
            break;
        case L1SoundTypeIntro:
            return SOUND_FADE_TIME_INTRO;
            break;
        default:
            return SOUND_FADE_TIME;
            break;
    }
}

-(float) riseTimeForSound:(L1CDLongAudioSource*)sound
{
    switch (sound.soundType) {
        case L1SoundTypeAtmos:
            return SOUND_RISE_TIME_ATMOS;
            break;
        case L1SoundTypeMusic:
            return SOUND_RISE_TIME_MUSIC;
            break;
        case L1SoundTypeSpeech:
            return SOUND_RISE_TIME_SPEECH;
            break;
        case L1SoundTypeIntro:
            return SOUND_RISE_TIME_INTRO;
            break;
        default:
            return SOUND_RISE_TIME;
            break;
    }
}



//This method gets triggered every 1/2 second or so to update the sound volumes.
//We keep track of whether there are any sounds rising or falling.
-(void) updateSoundVolumes:(NSObject*) dummy
{
    //Do not update if global pause is active.
    if (globallyPaused) return;

    @synchronized(self){
    //Quick exit if there are no sounds to process.
    int nRising = [risingSounds count];
    int nFading = [fadingSounds count];
    if (nRising==0 && nFading==0) return;

    //Fade out the fading sounds.
    NSArray * fadingSoundsArray;
        fadingSoundsArray = [fadingSounds allValues];
    for (L1CDLongAudioSource * sound in fadingSoundsArray){
        //Reduce the volume by the correct amount, which depends on the total fade time.
        float fadeTime = [self fadeTimeForSound:sound];
        sound.volume = sound.volume-SOUND_UPDATE_TIME_STEP/fadeTime;        
        NSLog(@"Fading %@",sound.key);
        
        //When the sound has fully faded we pause so we can restart it later.
        if (sound.volume<=0.0){
            sound.volume=0.0;
            NSLog(@"Done fading %@ - pausing",sound.key);
            [sound pause];
            //We can drop the intro altogether now as we will never replay it.
            if (sound.soundType==L1SoundTypeIntro) [audioSamples removeObjectForKey:sound.key];
            //This is no longer the active speech track as it has finished.
            if ([sound.key isEqualToString:activeSpeechTrack]) activeSpeechTrack=nil;
            if (oneSoundOfTypeAtATime){
                if ([sound.key isEqualToString:activeAtmosTrack]) activeAtmosTrack=nil;
                if ([sound.key isEqualToString:activeMusicTrack]) activeMusicTrack=nil;
                
            }
            
            [fadingSounds removeObjectForKey:sound.key];
        }
    }
    
    NSArray * risingSoundsArray;
        risingSoundsArray = [risingSounds allValues];
    for (L1CDLongAudioSource * sound in risingSoundsArray){
        float riseTime = [self riseTimeForSound:sound];
        sound.volume = sound.volume+SOUND_UPDATE_TIME_STEP/riseTime;        
        NSLog(@"Rising %@",sound.key);

        //When the sound has fully faded we pause so we can restart it later.
        if (sound.volume>=1.0){
            NSLog(@"Done rising %@",sound.key);

            sound.volume=1.0;
                [risingSounds removeObjectForKey:sound.key];
        }

    }
    }
}


- (void) cdAudioSourceDidFinishPlaying:(CDLongAudioSource *) audioSource
{
    @synchronized(self){
    
    // This sound *should* be an instance of our subclass.  Otherwise not sure what
    // is happening
    if (![audioSource isKindOfClass:[L1CDLongAudioSource class]]) return;
    L1CDLongAudioSource * source = (L1CDLongAudioSource*) audioSource;
    NSLog(@"Sound finished: %@",source.key);
    
    
    // If the sound is a speech track then note that it is no longer active, 
    // so that another can replace it without a clash.
    if ([source.key isEqualToString:activeSpeechTrack]) activeSpeechTrack=nil;

    if (oneSoundOfTypeAtATime){
        if ([source.key isEqualToString:activeMusicTrack]) activeMusicTrack=nil;
        if ([source.key isEqualToString:activeAtmosTrack]) activeAtmosTrack=nil;

    }
        
    // If this track is the intro track then note that it has stopped playing so we do
    // not try to stop it again.  We also post a notificiation that tells the main view controller
    // (and anyone else who wants to know) that it has finsihed.
    if ([source.key isEqualToString:INTRO_SOUND_KEY]){
        introIsPlaying=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:HH_INTRO_SOUND_ENDED_NOTIFICATION object:nil];
    }
    
    // We do not want to play speech nodes twice in a short time period if they
    // finish completely.  Record what time it finished so we can check again later.
    if (source.soundType==L1SoundTypeSpeech){
        [lastCompletionTime setObject:[NSDate date] forKey:source.key];
    }
    
    //We want to repeat music and atmost when they finish
//    if (source.soundType==L1SoundTypeMusic || source.soundType==L1SoundTypeAtmos){
    if (source.soundType==L1SoundTypeAtmos || source.soundType==L1SoundTypeMusic){
        [source play];
    }
    else
        // For other sounds we just note that they are no longer rising or falling and remove the reference
        // to them so they are freed.
    {
        if ([risingSounds objectForKey:source.key]) [risingSounds removeObjectForKey:source.key];
        if ([fadingSounds objectForKey:source.key]) [fadingSounds removeObjectForKey:source.key];
        [audioSamples removeObjectForKey:source.key];
        SEL sel = @selector(soundManager:soundDidFinish:);
        if ([self.delegate respondsToSelector:sel]){
            [self.delegate performSelector:sel withObject:self withObject:source.key];
        }
    }
    }
    
}

-(void) unpauseGlobal{
    for (L1CDLongAudioSource * sound in globallyPausedSounds){
        [sound resume];
    }
    [globallyPausedSounds removeAllObjects];
    globallyPaused=NO;
    
}

-(void) pauseGlobal{
    for (NSString * key in audioSamples){
        L1CDLongAudioSource * sound = [audioSamples objectForKey:key];
        if ([sound isPlaying]){
            [sound pause];
            [globallyPausedSounds addObject:sound];
        }
    }
    globallyPaused=YES;
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


//
//
//-(NSString*) filenameForNodeSound:(L1Node*) node getType:(L1SoundType*) soundType
//{
//    for(L1Resource * resource in node.resources){
//        if ([resource.type isEqualToString:@"sound"] && resource.saveLocal){
//            if (resource.local){
//                *soundType = resource.soundType;
//                return [resource localFilePath];
//            }else{
//                [resource downloadResourceData]; //We wanted the data but could not get it.  Start DL now so we might next time.
//            }
//        }   
//    }
//    
//    return nil;
//}



@end
