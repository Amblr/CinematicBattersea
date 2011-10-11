//
//  HackneyHearAppDelegate.h
//  HackneyHear
//
//  Created by Joe Zuntz on 08/10/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HHMediaStatusViewController.h"

@class L1Scenario;
@class HackneyHearTabViewController;
@class HackneyHear_ViewController;

@interface HackneyHearAppDelegate : NSObject <UIApplicationDelegate> {
    IBOutlet UITabBarController*  mainTabBarController;
    IBOutlet HackneyHear_ViewController * hhViewController;
    IBOutlet HHMediaStatusViewController * mediaStatusViewController;
    L1Scenario * scenario;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController*  mainTabBarController;


@property (retain) L1Scenario * scenario;
// Story contents
-(void) setupScenario;
//-(void) pathSource:(id) pathManager didReceivePaths:(NSDictionary*) paths;
-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes;
-(void) nodeDownloadFailedForScenario:(L1Scenario*) scenario;
-(void) authenticate;

@end


