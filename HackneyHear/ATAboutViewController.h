//
//  HHAboutViewController.h
//  HackneyHear
//
//  Created by Joe Zuntz on 17/11/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import <UIKit/UIKit.h>


@class L1DownloadProximityMonitor;

@interface ATAboutViewController : UIViewController
{    
    IBOutlet UIScrollView * scrollView;
    IBOutlet UIView * contentView;
    IBOutlet UIButton * checkForNewSoundsButton;
    IBOutlet UIProgressView * progressView;
    IBOutlet L1DownloadProximityMonitor * proximityMonitor;
    int resourcesToDownload;
}

-(IBAction)checkForNewSounds;
@end
