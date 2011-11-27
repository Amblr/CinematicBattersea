//
//  Hackney_Hear_ViewController.h
//  Hackney Hear 
//
//  Created by Joe Zuntz on 05/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "L1Scenario.h"
#import "L1MapViewController.h"
#import "SimpleAudioEngine.h"
#import "L1BigBrother.h"
//#import "L1DownloadProximityMonitor.h"
#import "HHSoundManager.h"

#import "HHConfigurationOptions.h"
#import "L1OverlayView.h"

#define NO_WALK_SELECTED -1


@class L1DownloadProximityMonitor;


@interface HackneyHear_ViewController : UIViewController<CLLocationManagerDelegate> {
    L1Scenario * scenario;
    IBOutlet L1MapViewController * mapViewController;
    IBOutlet UILabel * nowPlayingLabel;
    IBOutlet UIView * nowPlayingView;
    IBOutlet UIImageView * headphoneLabel;
    CLLocationManager *locationManager;
    NSMutableDictionary *circles;
//    IBOutlet UISwitch *realGPSControl;
    
    // Tracking the user's path
    BOOL trackMe;
    BOOL firstLocation;
    BOOL realGPSControl;
    L1BigBrother * realLocationTracker;
    L1BigBrother * fakeLocationTracker;
//    L1DownloadProximityMonitor * proximityMonitor;
    UIButton * skipButton;
    HHSoundManager * soundManager;
    IBOutlet UIButton * pauseButton;
    IBOutlet L1DownloadProximityMonitor * proximityMonitor;
    NSDate * sinclairSpecialCaseNodeFirstOffTime;
    int selectedWalk;
    L1Overlay * walkOverlay;
    NSDate * lastActivation;
    
    
}
@property (retain) NSDate * lastActivation;
@property (retain) L1Overlay * walkOverlay;
@property (assign) int selectedWalk;
@property (retain) L1Scenario * scenario;
@property (retain) NSDate * sinclairSpecialCaseNodeFirstOffTime;
@property (retain) HHSoundManager * soundManager;
-(void) globalPauseToggle;

-(void) setWalk:(int) walkIndex;
-(void) stopUpdatingLocation;
-(void) startUpdatingLocation;
-(void) reset;

-(void) audioRouteDidChange:(CFDictionaryRef) change;

// Location awareness
-(void) locationUpdate:(CLLocationCoordinate2D) location;
-(void) manualLocationUpdate:(CLLocation*)location;
-(IBAction) downloadAllTheThings;

// Story contents
//-(void) setupScenario;
-(void) pathSource:(id) pathManager didReceivePaths:(NSDictionary*) paths;
-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes;
//-(void) nodeDownloadFailedForScenario:(L1Scenario*) scenario;
// Sound
-(void) nodeSoundOff:(L1Node*) node;
-(void) nodeSoundOn:(L1Node*) node;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
-(NSString*) filenameForNodeSound:(L1Node*) node getType:(L1SoundType*) soundType;
-(void) checkFirstLaunch;
-(void) zoomToCurrentLocation;
@end
