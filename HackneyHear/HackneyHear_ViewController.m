//
//  Hackney_Hear_ViewController.m
//  Hackney Hear 
//
//  Created by Joe Zuntz on 05/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "HackneyHear_ViewController.h"
#import "L1Path.h"
#import "L1Utils.h"
#import "L1DownloadProximityMonitor.h"

#define SPECIAL_SHAPE_NODE_NAME @"2508 bway sound track01"
#define SINCALIR_SPECIAL_NODE_NAME @"0808 Sinclair bench w sting"
#define SINCALIR_SPECIAL_NODE_TIME 60



@implementation HackneyHear_ViewController
@synthesize scenario;
@synthesize selectedWalk;
@synthesize walkOverlay;

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
#if ALLOW_FAKE_LOCATION
    realGPSControl=[[NSUserDefaults standardUserDefaults] boolForKey:@"use_real_location"];
#else
    realGPSControl = YES;
#endif
    soundManager = [[HHSoundManager alloc] init];

    BOOL ok = [L1Utils initializeDirs];
    if (!ok) NSAssert(ok, @"Unable to ini dirs.");
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    circles = [[NSMutableDictionary alloc] initWithCapacity:0];
    //self.scenario=nil;
    realLocationTracker = [[L1BigBrother alloc] init];
    fakeLocationTracker = [[L1BigBrother alloc] init];
    mapViewController.delegate=self;
//    proximityMonitor = [[L1DownloadProximityMonitor alloc] init];
    skipButton=nil;
    NSLog(@"Tiles adding");
    NSString * tileDir = @"Tiles";
    sinclairSpecialCaseNodeFirstOffTime = nil;
    
    [nowPlayingView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bkg-pattern.png"]]];
    
    selectedWalk=NO_WALK_SELECTED;
    
    
    CLLocationCoordinate2D southWest, northEast;
    southWest.latitude = 51.3;
    southWest.longitude = -0.28;
    northEast.latitude = 51.8;
    northEast.longitude = -0.0;
    [mapViewController whiteOutFrom:southWest to:northEast];
    [mapViewController addTilesFromDirectory:tileDir];
    [self checkFirstLaunch];
    
    //    lat:   lon:  dLat:   dLon:)
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(INITIAL_CENTER_LAT, INITIAL_CENTER_LON);
    MKCoordinateSpan span = MKCoordinateSpanMake(INITIAL_DELTA_LAT, INITIAL_DELTA_LON);
    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    [mapViewController logLocation];

    [mapViewController zoomToRegion:region];

    //Now use a 20% enlarged region to restrict the map.
    [mapViewController logLocation];
//    [mapViewController restrictToRegion:region];
//    [mapViewController restrictToCurrentRegionBoundaryFraction:
#if RESTRICT_TO_HACKNEY    
    [mapViewController restrictToCurrentRegion];
#endif
    firstLocation=YES;
    self.walkOverlay = nil;
}


-(void) setNowPlayingLabel
{
    if (soundManager.currentSpeechKey){
        L1Node * activeSpeechNode = [self.scenario.nodes objectForKey:soundManager.currentSpeechKey];
        nowPlayingView.alpha = 1.0;
        [nowPlayingLabel setText:[NSString stringWithFormat:@"Now playing: %@",activeSpeechNode.name]];
    }
    else{
        nowPlayingView.alpha = 0.0;
    }
    
}


-(void) skipIntro:(NSObject*) dummy
{
    NSLog(@"The intro ended or was skipped somehow.");
    MKCoordinateRegion region = [mapViewController mapRegion];
    
    NSLog(@"BTW, region lat: %f  lon: %f  dLat: %f  dLon:%f)",region.center.latitude,region.center.longitude,region.span.latitudeDelta,region.span.longitudeDelta);

    //replace the skip button with a pause button
    
    [pauseButton setImage:[UIImage imageNamed:@"btn-pause.png"] forState:UIControlStateNormal];
    [pauseButton removeTarget:self action:@selector(skipIntro:) forControlEvents:UIControlEventTouchUpInside];
    [pauseButton addTarget:self action:@selector(globalPauseToggle) forControlEvents:UIControlEventTouchUpInside];
    
//    [skipButton removeFromSuperview];
//    skipButton = nil;
    [soundManager skipIntro];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setNowPlayingLabel];
    [self locationUpdate:locationManager.location.coordinate];

}




-(void) checkFirstLaunch{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *markerPath = [documentsPath stringByAppendingPathComponent:@"application_launched_before.marker"];
    NSFileManager * manager = [[NSFileManager alloc]init];
    if (![manager fileExistsAtPath:markerPath] || FORCE_INTRO_LANUCH){
        //Do all the first launch things
        BOOL ok = [manager createFileAtPath:markerPath contents:[NSData data] attributes:nil];
        NSAssert(ok, @"Failed to create marker file.");
        
        //Play the intro sound.
        [soundManager startIntro];
        [nowPlayingLabel setText:@"Now Playing: Hackney Hear Introduction"];

            
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(skipIntro:)
                                                     name:HH_INTRO_SOUND_ENDED_NOTIFICATION object:nil];

        
        [pauseButton addTarget:self action:@selector(skipIntro:) forControlEvents:UIControlEventTouchUpInside];
        [pauseButton setImage:[UIImage imageNamed:@"btn-skip.png"] forState:UIControlStateNormal];

        
        if (![CLLocationManager locationServicesEnabled]){
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Locations Disabled" message:@"This application will not function properly without location services enabled.  Please re-enable them in iPhone Settings if you want to use this app." delegate:nil cancelButtonTitle:@"Continue" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }

        
        //Start a timer that will end when the natural break point in the sound is reached (?)
        
    }
    [manager release];
}

-(void) viewDidAppear:(BOOL)animated
{
    //We may have just lanched the application or have flipped back here from another tab
    //either way we check if anything has changed in the options,
    //and then alter our tracking behaviour accordingly.
    //This is also a good time to check for location updates, in case the user
    //just switched to real location from fake or vice versa.
#if ALLOW_FAKE_LOCATION
    realGPSControl = [[NSUserDefaults standardUserDefaults] boolForKey:@"use_real_location"];
#else
    realGPSControl=YES;
#endif
    trackMe = [[NSUserDefaults standardUserDefaults] boolForKey:@"track_user_location"];
    [locationManager startUpdatingLocation];
    
    if ([CLLocationManager locationServicesEnabled] && self.scenario){
        if (realGPSControl){
            [self locationUpdate:locationManager.location.coordinate];
        }
        else {
            [self locationUpdate:mapViewController.manualUserLocation.coordinate];
        }
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark -
#pragma mark Story Elements


//This is a delegate method that gets called when some nodes have been downloaded.
//in our case that means that the scenario download is complete and we
//shoudl start normal behaviour.
//That means reading through the nodes and adding them to the map if they have a sound attached.
-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes
{
    for (L1Node *node in [nodes allValues]){
        
        //Check if node has any sound resources.  If not ignore it.
        L1Resource * sound = nil;
        for (L1Resource * resource in node.resources){
            if ([resource.type isEqualToString:@"sound"]){
                sound=resource;
            }
        }
        if (!sound) continue;
        NSLog(@"HH Found node: %@",node.name);
        
                
        //Add circle overlay.  The colour depends on the sound type.
        //Choose the colour here.
//        UIColor * circleColor;
//        BOOL isSpeech = (sound.soundType==L1SoundTypeSpeech);
//        if (isSpeech) circleColor = [UIColor redColor];
//        else circleColor = [UIColor greenColor];
        
        //Create the circle here, store it so we can keep track and change its color later,
        //and add it to the map.
        if ((![node.name isEqualToString:SPECIAL_SHAPE_NODE_NAME]) && (sound.soundType==L1SoundTypeSpeech)){
            UIColor * color = [UIColor redColor];
            L1Circle * circle = [mapViewController addCircleAt:node.coordinate radius:[node.radius doubleValue] color:color];
            [circles setObject:circle forKey:node.key];
            [mapViewController addNode:node];
        }

        //We use the enabled flag to track whether a node is playing.
        //None of them start enabled.
        node.enabled = NO; 
    }
    
    // If any nodes have been found we should zoom the map to their location.
    //We use an arbitrary on to zoom to for now.
    if ([nodes count]) {
//        L1Node * firstNode = [[nodes allValues] objectAtIndex:0];
//        [mapViewController zoomInToCoordinate:];
//        -(void) zoomInToCoordinate:(CLLocationCoordinate2D) center size:(float) size
//        float lat_center = 51.535463;
//        float lon_center = -0.062656;
//        CLLocationCoordinate2D center;
//        center.latitude=lat_center;
//        center.longitude=lon_center;
//        [mapViewController zoomInToCoordinate:center size:400.0];
        //We also add a pin representing the fake user location (for testing)
        //a little offset from the first node.
#if ALLOW_FAKE_LOCATION
        L1Node * firstNode = [[nodes allValues] objectAtIndex:0];
        CLLocationCoordinate2D firstNodeCoord = firstNode.coordinate;
        firstNodeCoord.latitude -= 5.0e-4;
        firstNodeCoord.longitude -= 5.0e-4;
        [mapViewController addManualUserLocationAt:firstNodeCoord];
#endif
    }
    
    //Now all the nodes are in place we can track them to see if we should
    //download their data.  We do that with the proximity manager.
    NSLog(@"New nodes to %@",proximityMonitor);
    [proximityMonitor addNodes:[nodes allValues]];
    
    //This is also a good time to update our location.
    //In particular to trigger proximity downloads.
    [self locationManager:locationManager didUpdateToLocation:locationManager.location fromLocation:nil];
    
}


-(void) pathSource:(id) pathManager didReceivePaths:(NSDictionary*) paths
{
    for (L1Path *path in [paths allValues]){
        NSLog(@"Found path: %@",path.name);
    }
}



#pragma  mark -
#pragma mark Sound
-(NSString*) filenameForNodeSound:(L1Node*) node getType:(L1SoundType*) soundType
{
    for(L1Resource * resource in node.resources){
        if ([resource.type isEqualToString:@"sound"] && resource.saveLocal){
            if (resource.local){
                *soundType = resource.soundType;
                return [resource localFilePath];
            }else{
                [resource downloadResourceData]; //We wanted the data but could not get it.  Start DL now so we might next time.
            }
        }   
    }
    
    return nil;
}

-(void) nodeSoundOn:(L1Node*) node
{           
    
    NSLog(@"Node on: %@",node.name);
    L1SoundType soundType;
    NSString * filename = [self filenameForNodeSound:node getType:&soundType];
    if (filename){
        node.enabled = [soundManager playSoundWithFilename:filename key:node.key type:soundType];
    }
}


-(void) nodeSoundOff:(L1Node*) node
{
    NSLog(@"Node off: %@",node.name);
    [soundManager stopSoundWithKey:node.key];
}

#pragma mark -
#pragma mark Location Awareness


/*
 Coordinates of the special region.
 -0.063043,51.535805
 -0.061262,51.538181
 -0.060328,51.537498
 -0.061744,51.535519

 
 */

-(BOOL) inSpecialRegion:(CLLocationCoordinate2D) location
{
#define NVERT 4
    float X[NVERT] = {-0.063043, -0.061262, -0.060328, -0.061744};
    float Y[NVERT] = {51.535805, 51.538181, 51.537498, 51.535519};
    
    int inRegion =  point_in_polygon(NVERT, X, Y, location.longitude, location.latitude);
    if (inRegion) NSLog(@"In special region");
    return inRegion;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//    NSLog(@"Location update [real]");
    if (realGPSControl) {
        NSLog(@"Using update");

        [self locationUpdate:newLocation.coordinate];
        if (trackMe)[realLocationTracker addLocation:newLocation];
    }
    else{
//        NSLog(@"Ignoring update");
        
    }

}

-(void) manualLocationUpdate:(CLLocation*)location
{
    NSLog(@"Location update [fake]");
    if (!realGPSControl) {
        NSLog(@"Using update");
        [self locationUpdate:location.coordinate];
        if (trackMe) [fakeLocationTracker addLocation:location];
    }
    else{
        NSLog(@"Ignoring update");

    }
}

-(void) trackToFirstLocation:(CLLocationCoordinate2D) location
{
//    {134166592.0, 89216064.0, 10240.0, 14720.0}
    MKMapRect rect = MKMapRectMake(134166592.0, 89216064.0, 10240.0, 14720.0);
    MKMapPoint point = MKMapPointForCoordinate(location);
    if (MKMapRectContainsPoint(rect, point)){
        
    }
    else //The user is not in Hackney!
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"You are not in Hackney" message:@"You don't seem to be in our area.  Run this application as you walk around the London Fields area to experience a rich audio tapestry of life in the borough." delegate:nil cancelButtonTitle:@"I'll go there now." otherButtonTitles: nil];
        [alert show];

    }
    firstLocation=NO;
}


-(void) setWalk:(int) walkIndex
{
    NSLog(@"Set walk to %d",walkIndex);
    selectedWalk=walkIndex;
    if (self.walkOverlay) [mapViewController removeImageOverlay:self.walkOverlay];
    if (walkIndex==-1) return;

    CLLocationCoordinate2D lowerLeft, upperRight; 

    switch (walkIndex) {
        case 1:
            lowerLeft.latitude = 51.535447;
            lowerLeft.longitude = -0.062364;
            upperRight.latitude = 51.537738;
            upperRight.longitude = -0.060814;
            break;
        case 2:
            lowerLeft.latitude = 0;
            lowerLeft.longitude = 0;
            upperRight.latitude = 0;
            upperRight.longitude = 0;
            break;
        case 3:
            lowerLeft.latitude = 0;
            lowerLeft.longitude = 0;
            upperRight.latitude = 0;
            upperRight.longitude = 0;
            break;
        default:
            return;
            break;
    }
    
    NSString * filename = [NSString stringWithFormat:@"walk%d.png",walkIndex];
    UIImage * overlayImage = [UIImage imageNamed:filename];

    self.walkOverlay = [[[L1Overlay alloc] initWithImage:overlayImage withLowerLeftCoordinate:lowerLeft withUpperRightCoordinate:upperRight] autorelease];
    
    [mapViewController addImageOverlay:self.walkOverlay];
    
    
    
}


-(void) locationUpdate:(CLLocationCoordinate2D) location
{
    if (soundManager.globallyPaused){
        NSLog(@"Ignoring location update becaue we are globally paused - no changes applied.");
        return;
    }
    NSLog(@"Updated to location: lat = %f,   lon = %f", location.latitude,location.longitude);
    [proximityMonitor updateLocation:location];
    if (firstLocation){
        [self trackToFirstLocation:location];
    }
    
    //We do not want to start playing any kind of sound if the intro is still before its break point.
    //So we should not enable any nodes or anything like that either.
    //So quitting this suborutine early seems the easiest way of doing this.
    if (soundManager.introBeforeBreakPoint){
        NSLog(@"Ignoring location update since intro has not reached break point");
        return;
    }
    NSMutableArray * offNodes = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray * onNodes = [NSMutableArray arrayWithCapacity:0];
    
    for (L1Node * node in [self.scenario.nodes allValues]){
        CLRegion * region = [node region];
        BOOL wasEnabled = node.enabled;
        BOOL nowEnabled = [region containsCoordinate:location];
        if ([node.name isEqualToString:SPECIAL_SHAPE_NODE_NAME]){
            nowEnabled = [self inSpecialRegion:location];
        }
        
        // Handle the special case awkward node.
        //We use sinclairSpecialCaseNodeFirstOffTime to track whether this is the first request or not.
        if ([node.name isEqualToString:SINCALIR_SPECIAL_NODE_NAME]){
            BOOL newNowEnabled = nowEnabled;
            if ((!nowEnabled) && wasEnabled){
                NSDate * now = [NSDate date];
                //Node told to switch on.  Either this is the first time or not
                if ((!sinclairSpecialCaseNodeFirstOffTime) || ([now timeIntervalSinceDate:sinclairSpecialCaseNodeFirstOffTime] < SINCALIR_SPECIAL_NODE_TIME)){
                    //The date is nil so we have been told for the first time to switch off.
                    //OR it is too recent to switch 
                    //So we ignore it and wait for later.
                    NSLog(@"Preventing Sinclair from switching off as we do not believe location");
                    if (!sinclairSpecialCaseNodeFirstOffTime) self.sinclairSpecialCaseNodeFirstOffTime = now;
                    newNowEnabled = YES;
                }else
                {
                    //It has been long enough off so we really let it switch off
                    //So we also need to reset the date.
                    self.sinclairSpecialCaseNodeFirstOffTime = nil;
                    NSLog(@"Allowing sinclair to switch off at last.");

                }
            }
            else if (nowEnabled && wasEnabled){
                //still enabled.  It is possible that this is a re-entry into the 
                //node, in which case we should re-set the timing.
                self.sinclairSpecialCaseNodeFirstOffTime = nil;
            }
            
            //We may have over-ridden this, so reset it now.
            nowEnabled = newNowEnabled;
        }
        

        if (nowEnabled) NSLog(@"Node now (or still) enabled: %@.  Old Status %d",node.name,wasEnabled);
        if (nowEnabled && (!wasEnabled)) [onNodes addObject:node];
        if ((!nowEnabled) && wasEnabled) [offNodes addObject:node];            

        node.enabled = nowEnabled;
        
        if (nowEnabled){
            L1Circle * circle = [circles valueForKey:node.key];
            MKCircleView * circleView = [mapViewController circleViewForCircle:circle];
            if (circleView){
                circleView.fillColor = [UIColor redColor];
                circleView.alpha = 0.75;
            }

        }
        else{
            
        }
        
        
        L1Circle * circle = [circles valueForKey:node.key];
        if (circle){
            MKCircleView * circleView = [mapViewController circleViewForCircle:circle];
            if (circleView){
                if (nowEnabled){
                    circleView.fillColor = [UIColor redColor];
                    circleView.alpha = 0.5;
                }
                else{
                    circleView.fillColor = [UIColor clearColor];
                    circleView.alpha = 1.0;
                    
                }
            }
        }
        
        // This is overkill.
//        if (nowEnabled){
//            L1Circle * circle = [circles valueForKey:node.key];
////            -(MKCircleView*) circleViewForCircle:(L1Circle*) circle
//            MKCircleView * circleView = [mapViewController circleViewForCircle:circle];
//            if (circleView){
//                circleView.fillColor = [UIColor redColor];
//                circleView.alpha = 0.75;
//            }
//            //[mapViewController setColor:[UIColor blueColor] forCircle:circle];
//        }
//        else{
//            
//        }
//            for(L1Resource * resource in node.resources){
//                if ([resource.type isEqualToString:@"sound"] && resource.soundType==L1SoundTypeSpeech){
//                    L1Circle * circle = [circles valueForKey:node.key];
//                    if (circle){
//                            MKCircleView * circleView = [mapViewController circleViewForCircle:circle];
//                            if (circleView){
//                                circleView.fillColor = [UIColor clearColor];
//                                circleView.alpha = 0.75;
//                            }
//                   
//                    break;
//                    
//                }
//            }            
//            
//        }
//        }
            
//
    }
        
        
    for (L1Node * node in offNodes){
        [self nodeSoundOff:node];        
    }
    for (L1Node * node in onNodes){
        [self nodeSoundOn:node];
    }

    
    [self setNowPlayingLabel];

}



-(IBAction) downloadAllTheThings
{
    [proximityMonitor downloadAll];
}

-(void) globalPauseToggle
{
    [soundManager toggleGlobalPause];
    if (soundManager.globallyPaused){
        NSLog(@"Just paused.  Set icon to play image.");
        [pauseButton setImage:[UIImage imageNamed:@"btn-play.png"] forState:UIControlStateNormal];
    }
    else{
        NSLog(@"Just unpaused.  Set icon to pause image.");
        [pauseButton setImage:[UIImage imageNamed:@"btn-pause.png"] forState:UIControlStateNormal];
    }
}

-(void) soundManager:(HHSoundManager*)manager soundDidFinish:(NSString*) key
{
    L1Node * node = [self.scenario.nodes objectForKey:key];
    node.enabled=NO;
}

@synthesize sinclairSpecialCaseNodeFirstOffTime;
@end

