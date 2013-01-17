//
//  HackneyHearAppDelegate.m
//  HackneyHear
//
//  Created by Joe Zuntz on 08/10/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "ATAppDelegate.h"

//
//  HackneyHear_AppDelegate.m
//  Hackney Hear 
//
//  Created by Joe Zuntz on 05/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "ATAppDelegate_iPhone.h"


#import "HTNotifier.h"
#import "SimpleURLConnection.h"
#import <AVFoundation/AVFoundation.h>
#import "ATMainViewController.h"

void audioRouteChangeListenerCallback (void *data, AudioSessionPropertyID ID, UInt32  dataSize, const void *inData
                                       )
{
    ATMainViewController * viewController = (ATMainViewController *) data;
    CFDictionaryRef routeChangeDictionary = inData;
    [viewController audioRouteDidChange:routeChangeDictionary];
    
}



@implementation ATAppDelegate

@synthesize window=_window;
@synthesize splashScreen;
@synthesize mainTabBarController;



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [ATMainViewController class];
    [L1MapViewController class];
    self.window.rootViewController = self.mainTabBarController;
    NSLog(@"view controller = %@",self.mainTabBarController);
    [self.window makeKeyAndVisible];
    
    self.splashScreen = [[[UIImageView alloc] initWithFrame:self.window.bounds] autorelease];
    splashScreen.image = [UIImage imageNamed:@"splash.png"];
    [self.window addSubview:splashScreen];
    [self performSelector:@selector(removeSplashScreen:) withObject:nil afterDelay:SPLASH_SCREEN_DELAY];
    
    
    [HTNotifier startNotifierWithAPIKey:@"bf9845eaf284ec17a3652f0a82d70702" environmentName:HTNotifierDevelopmentEnvironment];

    [[AVAudioSession sharedInstance] setDelegate: self];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
#if LOAD_SCENARIO_FROM_FILE
#warning SETTING SCENARIO FROM FIXED FILE!
    useLoadedScenario = YES;
    [self setupScenario];
#else
    useLoadedScenario = NO;
    [self authenticate];
#endif
    
//    OSStatus error = AudioSessionInitialize(NULL, NULL, NULL, NULL);

    OSStatus error = AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     hhViewController);
    
    char * error_c = (char*) &error;
    if (error) 
        NSLog(@"Error %c%c%c%c while adding listener", *(error_c),*(error_c+1),*(error_c+2),*(error_c+3));

    return YES;
}

-(void) removeSplashScreen:(id) dummy
{
    [self.splashScreen removeFromSuperview];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    NSLog(@"applicationWillResignActive");
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    NSLog(@"applicationDidEnterBackground");
//    if ([[UIApplication sharedApplication] respondsToSelector:@selector(backgroundTimeRemaining)]){
//        NSTimeInterval t = [[UIApplication sharedApplication] backgroundTimeRemaining];
//        NSLog(@"Time left = %f\n",t);
//    }
    
    if (hhViewController.soundManager.globallyPaused){
        [hhViewController stopUpdatingLocation];
        NSLog(@"Stopping location update");
        //If paused the user does not want to play any more, so de-activate location updating
    }
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    NSLog(@"applicationWillEnterForeground");
    [hhViewController startUpdatingLocation];
    hhViewController.lastActivation = [NSDate date];
    [hhViewController zoomToCurrentLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    NSLog(@"applicationDidBecomeActive");

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    //    [_viewController release];
    [super dealloc];
}


#pragma mark -
#pragma mark Story Elements



-(void) authenticate
{
    NSString * signin = @"http://amblr.heroku.com/users/sign_in";
    NSString * email = @"alex@amblr.net";
    NSString * name = @"Matilda0708";
    NSString * dataString = [NSString stringWithFormat:@"{'user' : { 'email' : '%@', 'password' : '%@'}}", email,name];
    
    SimpleURLConnection * connection = [[SimpleURLConnection alloc] initWithURL:signin 
                                                                       delegate:self 
                                                                   passSelector:@selector(doneAuthentication:response:) 
                                                                   failSelector:@selector(failedAuthentication:)];
    NSMutableURLRequest * request = connection.request;
    
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSData * data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    [connection runRequest];
    
}

-(void) doneAuthentication:(NSData*) data response:(NSHTTPURLResponse*) response
{
    int code = [response statusCode];
    NSLog(@"Response %d to authentication: %@",code,[NSHTTPURLResponse localizedStringForStatusCode:code]);
    if (code%100==4||code%100==5) useLoadedScenario=YES;
    [self setupScenario];
    
}

-(void) failedAuthentication:(NSError*) error
{
    useLoadedScenario=YES;
    [self setupScenario];
    
    
}




-(void) setupScenario {
    L1Scenario * scenario;
    if (useLoadedScenario){
        NSLog(@"SETTING SCENARIO FROM FIXED FILE!");
        NSString * storyFile = [[NSBundle mainBundle]pathForResource:@"story" ofType:@"json"];
        scenario = [[[L1Scenario alloc] init] autorelease];
        scenario.key = @"4e15c53add71aa000100025b";
        NSData * data = [NSData dataWithContentsOfFile:storyFile];
        [self performSelector:@selector(hackScenarioReady:) withObject:data afterDelay:1.0];
    }
    else{
        NSArray * urls = [NSArray arrayWithObjects:STORY_URL, STORY_URL_2, nil];
        scenario = [L1Scenario scenarioFromStoryURLs:urls withKey:SCENARIO_KEY];
    }     
    
    scenario.delegate = hhViewController;
    hhViewController.scenario = scenario;
    //mediaStatusViewController.scenario = scenario;
    
}
-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes
{
    [hhViewController nodeSource:self didReceiveNodes:nodes];
    
}

-(void) nodeDownloadFailedForScenario:(L1Scenario*) scenario
{
//    NSString * message = @"We cannot connect to the internet to find the latest version of the app.";
//    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"No Network" message:message delegate:self cancelButtonTitle:@"*Sigh*" otherButtonTitles:nil];
//    [alert show];
//    [alert release];
    //We now transparently revert to the inbuilt version of the app if we have no internet connection.
    
    [self setupScenario];
    
    
}



@end
