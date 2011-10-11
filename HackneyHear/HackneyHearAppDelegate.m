//
//  HackneyHearAppDelegate.m
//  HackneyHear
//
//  Created by Joe Zuntz on 08/10/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "HackneyHearAppDelegate.h"

//
//  HackneyHear_AppDelegate.m
//  Hackney Hear 
//
//  Created by Joe Zuntz on 05/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "HackneyHearAppDelegate_iPhone.h"


#import "HTNotifier.h"
#import "SimpleURLConnection.h"
#import <AVFoundation/AVFoundation.h>
#import "HackneyHear_ViewController.h"


#define LOAD_SCENARIO_FROM_FILE 0

@implementation HackneyHearAppDelegate
@synthesize  scenario;

@synthesize window=_window;

@synthesize mainTabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[AVAudioSession sharedInstance] setDelegate: self];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
    [HackneyHear_ViewController class];
    [L1MapViewController class];
    self.window.rootViewController = self.mainTabBarController;
    NSLog(@"view controller = %@",self.mainTabBarController);
    [self.window makeKeyAndVisible];
    //    [self setupScenario];
    [HTNotifier startNotifierWithAPIKey:@"bf9845eaf284ec17a3652f0a82d70702" environmentName:HTNotifierDevelopmentEnvironment];
    
#if LOAD_SCENARIO_FROM_FILE
    [self setupScenario];
#else
    [self authenticate];
#endif
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
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
    NSString * email = @"hackneyproductions@gmail.com";
    NSString * name = @"hackneyhear";
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
    //    NSString * text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@",text);
    [self setupScenario];
    
}

-(void) failedAuthentication:(NSError*) error
{
    NSString * message = [error localizedDescription];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error" message:message delegate:self cancelButtonTitle:@"*Sigh*" otherButtonTitles:nil];
    [alert show];
    
    
}

-(void) hackScenarioReady:(NSData*) data
{
    [scenario downloadedStoryData:data withResponse:nil];
    
}


-(void) setupScenario {
    
#if LOAD_SCENARIO_FROM_FILE
#warning SETTING SCENARIO FROM FIXED FILE!
    NSString * storyFile = [[NSBundle mainBundle]pathForResource:@"story" ofType:@"json"];
    self.scenario = [[L1Scenario alloc] init];
    self.scenario.key = @"4e15c53add71aa000100025b";
    NSData * data = [NSData dataWithContentsOfFile:storyFile];
    [self performSelector:@selector(hackScenarioReady:) withObject:data afterDelay:5.0];
#else
    
#ifdef ALEX_HEAR    
    NSString * storyURL = @"http://amblr.heroku.com/scenarios/4e249f58d7c4b60001000023/stories/4e249fe5d7c4b600010000c1.json";
    NSString scenarioKey = @"4e15c53add71aa000100025"
#else
    NSString * storyURL = @"http://amblr.heroku.com/scenarios/4e15c53add71aa000100025b/stories/4e15c6be7bd01600010000c0.json";
    NSString * scenarioKey = @"4e249f58d7c4b60001000023";
    
#endif
    self.scenario = [L1Scenario scenarioFromStoryURL:storyURL withKey:scenarioKey];
#endif        
    
    
    
    self.scenario.delegate = hhViewController;
    hhViewController.scenario = scenario;
    mediaStatusViewController.scenario = scenario;
    
}
-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes
{
    [hhViewController nodeSource:self didReceiveNodes:nodes];
    
}

-(void) nodeDownloadFailedForScenario:(L1Scenario*) scenario
{
    NSString * message = @"You don't seem to have an internet connection.  Or possibly your humble developers have screwed up.  Probably the former.";
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"No Network" message:message delegate:self cancelButtonTitle:@"*Sigh*" otherButtonTitles:nil];
    [alert show];
    
}



@end
