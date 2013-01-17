//
//  HackneyHearAppDelegate.h
//  HackneyHear
//
//  Created by Joe Zuntz on 08/10/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "HHMediaStatusViewController.h"

@class L1Scenario;
@class HackneyHearTabViewController;
@class ATMainViewController;

@interface ATAppDelegate : NSObject <UIApplicationDelegate> {
    IBOutlet UITabBarController*  mainTabBarController;
    IBOutlet ATMainViewController * hhViewController;
    UIBackgroundTaskIdentifier backgroundTaskID;
    BOOL useLoadedScenario;
    UIImageView * splashScreen;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController*  mainTabBarController;
@property (retain) UIImageView * splashScreen;

@property (retain) L1Scenario * scenario;
// Story contents
-(void) setupScenario;
-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes;
-(void) nodeDownloadFailedForScenario:(L1Scenario*) scenario;
-(void) authenticate;
//-(void) audioRouteDidChange:(CFDictionaryRef) change;

@end


