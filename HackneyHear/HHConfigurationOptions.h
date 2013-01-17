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


#define STORY_URL @"http://amblr.heroku.com/scenarios/50f6fb6b4a24c20002004c6f/stories/50f6fc2b4a24c20002004daa.json"
#define SCENARIO_KEY @"50f6fb6b4a24c20002004c6f"

#define STORY_URL_2 @"http://amblr.heroku.com/scenarios/50f6fb6b4a24c20002004c6f/stories/50f6fbaa4a24c20002004d77.json"



#endif
