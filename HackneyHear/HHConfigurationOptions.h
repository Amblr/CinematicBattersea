//
//  HHConfigurationOptions.h
//  HackneyHear
//
//  Created by Joe Zuntz on 19/10/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#ifndef HackneyHear_HHConfigurationOptions_h
#define HackneyHear_HHConfigurationOptions_h

#define FORCE_INTRO_LANUCH 1

#define RESTRICT_TO_HACKNEY 1

#define SPLASH_SCREEN_DELAY 2.0

#if TARGET_IPHONE_SIMULATOR || FORCE_FAKE_LOCATION
#define ALLOW_FAKE_LOCATION 1
#warning FAKING LOCATION
#else
#define ALLOW_FAKE_LOCATION 0
#endif

#define TIME_INTERVAL_FOR_SWITCH_OFF (10.*60)

#define LOAD_SCENARIO_FROM_FILE 0

#define INITIAL_CENTER_LAT 51.5393
#define INITIAL_CENTER_LON -0.0617
#define INITIAL_DELTA_LAT 0.006805
#define INITIAL_DELTA_LON 0.00505

#ifdef ALEX_HEAR    
#define STORY_URL @"http://amblr.heroku.com/scenarios/4e249f58d7c4b60001000023/stories/4e249fe5d7c4b600010000c1.json"
#define SCENARIO_KEY @"4e15c53add71aa000100025"
#else
#define STORY_URL @"http://amblr.heroku.com/scenarios/4e15c53add71aa000100025b/stories/4e15c6be7bd01600010000c0.json"
#define SCENARIO_KEY @"4e249f58d7c4b60001000023"

#endif



#endif
