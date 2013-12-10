//
//  Hackney_Hear_ViewController.m
//  Hackney Hear 
//
//  Created by Joe Zuntz on 05/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "ATMainViewController.h"
#import "L1Path.h"
#import "L1Utils.h"
#import "L1DownloadProximityMonitor.h"
#import "CBNode.h"
#import "TileOverlayView.h"
#import "TileOverlay.h"
#import "L1Overlay.h"

//#define SPECIAL_SHAPE_NODE_NAME @"2508 bway sound track01"
#define SINCALIR_SPECIAL_NODE_NAME @"0808 Sinclair bench w sting"
#define SINCALIR_SPECIAL_NODE_TIME 60

NSInteger nodeSortFunction(CBNode * node1, CBNode * node2, void * context)
{
    if (node1.soundType==CBSoundTypeBed){
        if (node2.soundType==CBSoundTypeBed)
            return NSOrderedSame;
        else return NSOrderedAscending;
    }
    else{
        if (node2.soundType==CBSoundTypeBed)
            return NSOrderedDescending;
        else return NSOrderedSame;
    }
}


@implementation ATMainViewController
//@synthesize scenario;
@synthesize selectedWalk;
@synthesize walkOverlay;
@synthesize soundManager;
@synthesize lastActivation;

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
    self.soundManager = [[[ATSoundManager alloc] init] autorelease];

    BOOL ok = [L1Utils initializeDirs];
    if (!ok) NSAssert(ok, @"Unable to ini dirs.");
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    circles = [[NSMutableDictionary alloc] initWithCapacity:0];
    //self.scenario=nil;
//    realLocationTracker = [[L1BigBrother alloc] init];
//    fakeLocationTracker = [[L1BigBrother alloc] init];
    self.delegate=self;
    proximityMonitor = [[L1DownloadProximityMonitor alloc] init];
    skipButton=nil;
//    NSLog(@"Tiles adding");
//    NSString * tileDir = @"Tiles";
//    sinclairSpecialCaseNodeFirstOffTime = nil;
    
    [nowPlayingView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bkg-pattern.png"]]];
    self.lastActivation = [NSDate date];
    selectedWalk=NO_WALK_SELECTED;
    
    contentImageView.hidden = YES;
    contentImageView.image = [UIImage imageNamed:@"about-logoband.png"];
    
    CLLocationCoordinate2D southWest, northEast;
    southWest.latitude = 51.3;
    southWest.longitude = -0.28;
    northEast.latitude = 51.8;
    northEast.longitude = -0.0;

    CLLocationCoordinate2D lowerLeftMap = CLLocationCoordinate2DMake(51.474494, -0.168348);
    CLLocationCoordinate2D upperRightMap = CLLocationCoordinate2DMake(51.487850, -0.136946);

    UIImage * mapOverlayImage = [UIImage imageNamed:@"overlayMap.jpg"];
    if (!mapOverlayImage){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"UhOh" message:@"Could not load thing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else{
        L1Overlay * overlay = [[L1Overlay alloc] initWithImage:mapOverlayImage withLowerLeftCoordinate:lowerLeftMap withUpperRightCoordinate:upperRightMap];
        [self addImageOverlay:overlay];
    }
    
    
//    [self whiteOutFrom:southWest to:northEast];
//    [self addTilesFromDirectory:@"Tiles2"];
////    [self addTilesFromDirectory:@"Tiles" cache:NO extension:@"png"];
//    for (id<MKOverlay> overlay in self.primaryMapView.overlays){
//        if ([overlay isKindOfClass:[TileOverlay class]]){
//            NSLog(@"XXXXXXX  %@", overlay);
//            TileOverlay * overlay_ = (TileOverlay*) overlay;
////            TileOverlayView * overlayView = [self.primaryMapView viewForOverlay:overlay];
//            MKMapPoint p1 = overlay_.boundingMapRect.origin;
//            MKMapPoint p2 = MKMapPointMake(overlay_.boundingMapRect.origin.x+overlay_.boundingMapRect.size.width, overlay_.boundingMapRect.origin.y+overlay_.boundingMapRect.size.height);
//            [self whiteOutFrom: MKCoordinateForMapPoint(p1) to:MKCoordinateForMapPoint(p2)];
//        }
//    }
//    

    [self checkFirstLaunch];
    
    //    lat:   lon:  dLat:   dLon:)
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(INITIAL_CENTER_LAT, INITIAL_CENTER_LON);
    MKCoordinateSpan span = MKCoordinateSpanMake(INITIAL_DELTA_LAT, INITIAL_DELTA_LON);
    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    [self logLocation];

    [self zoomToRegion:region];

    //Now use a 20% enlarged region to restrict the map.
    [self logLocation];
//    [mapViewController restrictToRegion:region];
//    [mapViewController restrictToCurrentRegionBoundaryFraction:

    firstLocation=YES;
    self.walkOverlay = nil;
}




-(void) skipIntro:(NSObject*) dummy
{
    NSLog(@"The intro ended or was skipped somehow.");
    MKCoordinateRegion region = [self mapRegion];
    
    NSLog(@"BTW, region lat: %f  lon: %f  dLat: %f  dLon:%f)",region.center.latitude,region.center.longitude,region.span.latitudeDelta,region.span.longitudeDelta);

    //replace the skip button with a pause button
    
    [pauseButton setImage:[UIImage imageNamed:@"btn-pause.png"] forState:UIControlStateNormal];
    [pauseButton removeTarget:self action:@selector(skipIntro:) forControlEvents:UIControlEventTouchUpInside];
    [pauseButton addTarget:self action:@selector(globalPauseToggle) forControlEvents:UIControlEventTouchUpInside];
    
//    [skipButton removeFromSuperview];
//    skipButton = nil;
    [soundManager skipIntro];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setNowPlayingMedia];
    [self locationUpdate:locationManager.location.coordinate];

}




-(void) checkFirstLaunch{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *markerPath = [documentsPath stringByAppendingPathComponent:@"application_launched_before.marker"];
    NSFileManager * manager = [[NSFileManager alloc]init];
    if (![manager fileExistsAtPath:markerPath] || FORCE_INTRO_LANUCH){
        //Do all the first launch things
        [manager createFileAtPath:markerPath contents:[NSData data] attributes:nil];
        
        //Play the intro sound.
//#ifndef LITE
//        [soundManager startIntro];
//        [nowPlayingLabel setText:@"Now Playing: Hackney Hear Introduction"];
        
            
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(skipIntro:)
//                                                     name:HH_INTRO_SOUND_ENDED_NOTIFICATION 
//                                                   object:nil];

        
//        [pauseButton addTarget:self action:@selector(skipIntro:) forControlEvents:UIControlEventTouchUpInside];
//        [pauseButton setImage:[UIImage imageNamed:@"btn-skip.png"] forState:UIControlStateNormal];
//#else
        [self skipIntro:nil];
//#endif

        
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
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    if ([CLLocationManager locationServicesEnabled] && self.scenario){
        if (realGPSControl){
            [self locationUpdate:locationManager.location.coordinate];
        }
        else {
            [self locationUpdate:self.manualUserLocation.coordinate];
        }
    }
//    NSLog(@"View did appear");
    [self performSelector:@selector(showMap:) withObject:nil afterDelay:0.1];
//    [self performSelector:@selector(testHack:) withObject:nil afterDelay:10.0];

}

-(void) showMap:(NSObject*)dummy
{
    self.view.alpha=1.0;

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

-(void) viewWillAppear:(BOOL)animated
{
//    NSLog(@"VIEW WILL APPEAR");
    self.view.alpha=0.01;
    [super viewWillAppear:animated];
}
#pragma mark -
#pragma mark Story Elements


//This is a delegate method that gets called when some nodes have been downloaded.
//in our case that means that the scenario download is complete and we
//shoudl start normal behaviour.
//That means reading through the nodes and adding them to the map if they have a sound attached


-(void) reset
{
    for (L1Circle * circle in [circles allValues]){
        [self removeCircle:circle];
    }
    [proximityMonitor removeNodes:[self.scenario.nodes allValues]];
    [self setWalk:NO_WALK_SELECTED];
    self.scenario=nil;
}

-(void) nodeSource:(id) nodeManager didReceiveNodes:(NSDictionary*) nodes
{
    //If we do this a second time it is because we have re-downloaded the scenario.
    //So we should reset.
    //[self reset];
    NSLog(@"FOUND NODES");
    
    for (CBNode *node in [nodes allValues]){
        
        //Check if node has any sound resources.  If not ignore it.
        L1Resource * sound = nil;
        for (L1Resource * resource in node.resources){
            if ([resource.type isEqualToString:@"sound"]){
                sound=resource;
            }
        }
//        if (!sound) continue;
        NSLog(@"HH Found node: %@",node.name);
        
                
        //Add circle overlay.  The colour depends on the sound type.
        //Choose the colour here.
        
        //Create the circle here, store it so we can keep track and change its color later,
        //and add it to the map.
            UIColor * color = [UIColor redColor];
            L1Circle * circle = [self addCircleAt:node.coordinate radius:[node.radius doubleValue] color:color];
            [circles setObject:circle forKey:node.key];

        //We use the enabled flag to track whether a node is playing.
        //None of them start enabled.
        node.enabled = NO; 
    }
    
    // If any nodes have been found we should zoom the map to their location.
    //We use an arbitrary on to zoom to for now.
    if ([nodes count]) {
        //We also add a pin representing the fake user location (for testing)
        //a little offset from the first node.
#if ALLOW_FAKE_LOCATION
        CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(51.477891, -0.160782);
        if (!self.manualUserLocation) {
            [self addManualUserLocationAt:startCoord];
            NSLog(@"Added manual user location");
        }
        [self zoomToCoordinate:startCoord];
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
#pragma mark Sound & Image

-(NSString*) filenameForNodeImage:(CBNode*) node
{
    for(L1Resource * resource in node.resources){
        if ([resource.type isEqualToString:@"image"] && resource.saveLocal){
            if (resource.local){
                return [resource localFilePath];
            }else{
                [resource downloadResourceData]; //We wanted the data but could not get it.  Start DL now so we might next time.
            }
        }
    }
    
    return nil;
}


-(NSString*) filenameForNodeSound:(CBNode*) node
{
    for(L1Resource * resource in node.resources){
        if ([resource.type isEqualToString:@"sound"] && resource.saveLocal){
            if (resource.local){
                return [resource localFilePath];
            }else{
                [resource downloadResourceData]; //We wanted the data but could not get it.  Start DL now so we might next time.
            }
        }   
    }
    
    return nil;
}



-(void) setNowPlayingMedia
{
    if (self.soundManager.globallyPaused){
//TODO Consider pausing beahviour
        nowPlayingView.alpha = 0.0;
        contentImageView.hidden=YES;
        
    }
    else if (soundManager.currentSpeechKey){
        CBNode * activeSpeechNode = [self.scenario.nodes objectForKey:soundManager.currentSpeechKey];
//        NSLog(@"setting label from node %@ -  '%@'",activeSpeechNode.name, activeSpeechNode.text);
        if (![activeSpeechNode.text isEqualToString:@""]){
            nowPlayingView.alpha = 1.0;
            [nowPlayingLabel setText:[NSString stringWithFormat:@"%@",activeSpeechNode.text]];
        }
        else{
            nowPlayingView.alpha = 0.0;
        }
//        contentImageView.hidden=NO;
        
//        NSString * imageFilename = [self filenameForNodeImage:activeSpeechNode];
//        if (imageFilename==nil) imageFilename = @"amblr@2x.png";
//        contentImageView.image = [UIImage imageWithContentsOfFile:imageFilename];
        
        // Also need to set image.
    }
    else{
        nowPlayingView.alpha = 0.0;
        contentImageView.hidden=YES;
    }
    
}


-(void) nodeSoundOn:(CBNode*) node
{           
    
    NSLog(@"Node on: %@",node.name);
    NSString * filename = [self filenameForNodeSound:node];
    if (filename){
        node.enabled = [soundManager playSoundWithFilename:filename key:node.key type:node.soundType];
    }
}


-(void) nodeSoundOff:(CBNode*) node
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
//        if (trackMe)[realLocationTracker addLocation:newLocation];
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
//        if (trackMe) [fakeLocationTracker addLocation:location];
    }
    else{
        NSLog(@"Ignoring update");

    }
}

-(void) trackToFirstLocation:(CLLocationCoordinate2D) location
{
//    {134166592.0, 89216064.0, 10240.0, 14720.0}
//    MKMapRect rect = MKMapRectMake(134166592.0, 89216064.0, 10240.0, 14720.0);
//    MKMapPoint point = MKMapPointForCoordinate(location);
//    if (MKMapRectContainsPoint(rect, point)){
//        
//    }
//    else //The user is not in Hackney!
//    {
//        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"You are not in Hackney" message:@"You don't seem to be in our area.  Run this application as you walk around the London Fields area to experience a rich audio tapestry of life in the borough." delegate:nil cancelButtonTitle:@"I'll go there now." otherButtonTitles: nil];
//        [alert show];
//
//    }
    firstLocation=NO;
}


-(void) cornersForWalk:(int)walkIndex lowerLeft:(CLLocationCoordinate2D*) lowerLeft upperRight:(CLLocationCoordinate2D*) upperRight
{
    switch (walkIndex) {
        case 1:
            lowerLeft->latitude = 51.535447;
            lowerLeft->longitude = -0.062364;
            upperRight->latitude = 51.537738;
            upperRight->longitude = -0.060814;
            break;
        case 2:
            
            lowerLeft->latitude = 51.537799;
            lowerLeft->longitude = -0.061318;
            upperRight->latitude = 51.542192;
            upperRight->longitude = -0.059180;
            break;
        case 3:
            lowerLeft->latitude = 51.538658;
            lowerLeft->longitude = -0.060446;
            upperRight->latitude = 51.542151;
            upperRight->longitude = -0.058134;
            break;
        default:
            return;
            break;
    }

}


-(void) zoomToWalk:(int) walkIndex
{
    CLLocationCoordinate2D lowerLeft, upperRight; 
    [self cornersForWalk:walkIndex lowerLeft:&lowerLeft upperRight:&upperRight];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake((lowerLeft.latitude+upperRight.latitude)/2, (lowerLeft.longitude+upperRight.longitude)/2);
    
    MKCoordinateSpan span = MKCoordinateSpanMake(fabs(upperRight.latitude-lowerLeft.latitude), fabs(lowerLeft.longitude-upperRight.longitude));
    
    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    
//    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(INITIAL_CENTER_LAT, INITIAL_CENTER_LON);
//    MKCoordinateSpan span = MKCoordinateSpanMake(INITIAL_DELTA_LAT, INITIAL_DELTA_LON);
//    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);

    
    [self zoomToRegion:region];
}


-(void) setWalk:(int) walkIndex
{
    NSLog(@"Set walk to %d",walkIndex);
    selectedWalk=walkIndex;
    if (self.walkOverlay) [self removeImageOverlay:self.walkOverlay];
    if (walkIndex==-1) return;

    CLLocationCoordinate2D lowerLeft, upperRight; 
    [self cornersForWalk:walkIndex lowerLeft:&lowerLeft upperRight:&upperRight];
    NSString * filename = [NSString stringWithFormat:@"walk%d.png",walkIndex];
    UIImage * overlayImage = [UIImage imageNamed:filename];

    self.walkOverlay = [[[L1Overlay alloc] initWithImage:overlayImage withLowerLeftCoordinate:lowerLeft withUpperRightCoordinate:upperRight] autorelease];
    
    [self addImageOverlay:self.walkOverlay];
    [self zoomToWalk:walkIndex];
    
    
    
}

-(void) checkForBackgroundExpiry
{
    
    NSLog(@"Background expiry not used.");
    return;
    
    //If the app has not been playing any sound for a certain length of time we should alert the user and
    //then switch off application updates
    if ([[UIApplication sharedApplication] applicationState]!=UIApplicationStateBackground) return;
    
    NSTimeInterval dt = -[self.lastActivation timeIntervalSinceNow];
    if (dt>TIME_INTERVAL_FOR_SWITCH_OFF){
        [self stopUpdatingLocation];
        UILocalNotification * note = [[UILocalNotification alloc] init];
        note.alertBody = @"You seem to have left the London Fields area so the Hackney Hear application has switched off.  To restart it you can open the app again and return to the area.";
        note.hasAction=NO;
//        note.soundName = @"flood.mp3";
        [[UIApplication sharedApplication] presentLocalNotificationNow:note];
        [note autorelease];
    }
}

-(void) locationUpdate:(CLLocationCoordinate2D) location
{
//    NSLog(@"%@", primaryMapView.overlays);
    if (soundManager.globallyPaused){
        NSLog(@"Ignoring location update becaue we are globally paused - no changes applied.");
        return;
    }
    NSLog(@"Updated to location: lat = %f,   lon = %f", location.latitude,location.longitude);
    MKMapPoint point = MKMapPointForCoordinate(location);
    NSLog(@"Map Point = %@", MKStringFromMapPoint(point));
    [proximityMonitor updateLocation:location];
    if (firstLocation){
        [self trackToFirstLocation:location];
    }
    
    if (self.scenario==nil) return;
    
    
    
    //We do not want to start playing any kind of sound if the intro is still before its break point.
    //So we should not enable any nodes or anything like that either.
    //So quitting this suborutine early seems the easiest way of doing this.
    if (soundManager.introBeforeBreakPoint){
        NSLog(@"Ignoring location update since intro has not reached break point");
        return;
    }
    NSMutableArray * offNodes = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray * onNodes = [NSMutableArray arrayWithCapacity:0];
    
    for (CBNode * node in [self.scenario.nodes allValues]){
        CLRegion * region = [node region];
        BOOL wasEnabled = node.enabled;
        BOOL nowEnabled = [region containsCoordinate:location];
        
        if (nowEnabled) NSLog(@"Node now (or still) enabled: %@.  Old Status %d",node.name,wasEnabled);
        if (nowEnabled && (!wasEnabled)) [onNodes addObject:node];
        if ((!nowEnabled) && wasEnabled) {NSLog(@"Switching off: %@",node.name);[offNodes addObject:node];}

        node.enabled = nowEnabled;
        
        L1Circle * circle = [circles valueForKey:node.key];
        if (circle){
            MKCircleView * circleView = [self circleViewForCircle:circle];
            if (circleView){
                if (nowEnabled && [circleView.fillColor isEqual: [UIColor clearColor]]){
                    circleView.fillColor = [UIColor redColor];
                }
                if ((!nowEnabled) && [circleView.fillColor isEqual: [UIColor redColor]]){
                    circleView.fillColor = [UIColor clearColor];
                }

            }
        }
    }
    
    // Sort the nodes so that the bed nodes appear first, so that they get dimmed before the
    // other nodes reset their volume to 1.
    [offNodes sortedArrayUsingFunction:nodeSortFunction context:NULL];
    
    for (CBNode * node in offNodes){
        [self nodeSoundOff:node];
    }
    for (CBNode * node in onNodes){
        [self nodeSoundOn:node];
    }

    
    [self setNowPlayingMedia];
    
    if ([onNodes count]||[offNodes count]){
        self.lastActivation=[NSDate date];
    }else{
        [self checkForBackgroundExpiry];
    }


}



-(IBAction) downloadAllTheThings
{
    [proximityMonitor downloadAll];
}


-(void) audioRouteDidChange:(CFDictionaryRef) change
{
    CFNumberRef routeChangeReasonRef = CFDictionaryGetValue (change, 
                                                             CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
    SInt32 routeChangeReason;
    
    CFNumberGetValue (routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
    
    if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) 
    {
        NSLog(@"Unplugged headset");
        if (!self.soundManager.globallyPaused) {
            [self globalPauseToggle];
//            [headphoneLabel setHidden:NO];    
        }
        
        
    }
    if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable)
    {
        NSLog(@"Plugged in headset");
//        [headphoneLabel setHidden:YES];    
        
    }
    
}

-(void) testHack:(id) dummy
{
    
    NSLog(@"Unplugged headset");
    if (!self.soundManager.globallyPaused) {
        [self globalPauseToggle];
//        [headphoneLabel setHidden:NO];    
    }
    [self performSelector:@selector(testHack:) withObject:nil afterDelay:10.0];

    
}



-(void) globalPauseToggle
{
//    [headphoneLabel setHidden:YES];    
    [soundManager toggleGlobalPause];
    if (soundManager.globallyPaused){
        NSLog(@"Just paused.  Set icon to play image.");
        [pauseButton setImage:[UIImage imageNamed:@"btn-play.png"] forState:UIControlStateNormal];        
        [pauseButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [pauseButton addTarget:self action:@selector(globalPauseToggle) 
              forControlEvents:UIControlEventTouchUpInside];

    }
    else{
        NSLog(@"Just unpaused.  Set icon to pause image.");
        if (soundManager.introIsPlaying){
            [pauseButton setImage:[UIImage imageNamed:@"btn-skip.png"] forState:UIControlStateNormal];        
            [pauseButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [pauseButton addTarget:self action:@selector(skipIntro:) forControlEvents:UIControlEventTouchUpInside];

        }
        else{
            [pauseButton setImage:[UIImage imageNamed:@"btn-pause.png"] forState:UIControlStateNormal];        
            [pauseButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [pauseButton addTarget:self action:@selector(globalPauseToggle) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    [self setNowPlayingMedia];
}

-(void) soundManager:(ATSoundManager*)manager soundDidFinish:(NSString*) key
{
    CBNode * node = [self.scenario.nodes objectForKey:key];
    node.enabled=NO;
}

-(void) stopUpdatingLocation
{
    [locationManager stopUpdatingLocation];
}

-(void) startUpdatingLocation
{
    [locationManager startUpdatingLocation];
}


-(void) zoomToCurrentLocation
{
#if ALLOW_FAKE_LOCATION    
    return;
#endif
    CLLocationCoordinate2D coord = locationManager.location.coordinate;
    if (coord.latitude>INITIAL_CENTER_LAT-INITIAL_DELTA_LAT/2
        && coord.latitude<INITIAL_CENTER_LAT+INITIAL_DELTA_LAT/2 
        && coord.longitude>INITIAL_CENTER_LON-INITIAL_DELTA_LON/2 
        && coord.longitude<INITIAL_CENTER_LON+INITIAL_DELTA_LON/2 
    ){
        [self zoomToCoordinate:locationManager.location.coordinate];
    }
}

//@synthesize sinclairSpecialCaseNodeFirstOffTime;
@end

