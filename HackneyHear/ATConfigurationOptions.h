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



#define SPLASH_SCREEN_DELAY 2.0
#define FORCE_FAKE_LOCATION 0
#if TARGET_IPHONE_SIMULATOR || FORCE_FAKE_LOCATION
#define ALLOW_FAKE_LOCATION 1
#warning FAKING LOCATION
#else
#define ALLOW_FAKE_LOCATION 0
#endif

#define TIME_INTERVAL_FOR_SWITCH_OFF (10.*60)

#define LOAD_SCENARIO_FROM_FILE 0



//
//   ASPIRE PROJECT SETTINGS
//
#ifdef PROJECT_ASPIRE


#define INITIAL_CENTER_LAT 51.7511
#define INITIAL_CENTER_LON -1.2558
#define INITIAL_DELTA_LAT 0.006805
#define INITIAL_DELTA_LON 0.00505
#define STORY_URL @"http://amblr.heroku.com/scenarios/4f6bac3a3e44f20001000a66/stories/50f6fa9a4a24c20002004afd"
#define SCENARIO_KEY @"4f6bac3a3e44f20001000a66"


//
//   BATTERSEA PROJECT SETTINGS
//
#elif defined PROJECT_BATTERSEA
#define INITIAL_CENTER_LAT 51.478185
#define INITIAL_CENTER_LON -0.154989
#define INITIAL_DELTA_LAT 0.006805
#define INITIAL_DELTA_LON 0.00505
#define STORY_URL @"http://amblr.heroku.com/scenarios/50f6fcef4a24c20002004e4c/stories/50f6fd334a24c20002004e7b.json"
#define SCENARIO_KEY @"50f6fcef4a24c20002004e4c"

#else
#error NO PROJECT DEFINED
#endif





#endif
