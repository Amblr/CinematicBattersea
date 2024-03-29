//
//  HHOptionsMenuController.h
//  HackneyHear
//
//  Created by Joe Zuntz on 12/10/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import <UIKit/UIKit.h>

@class L1DownloadProximityMonitor;
@interface ATOptionsMenuController : UIViewController
{
    IBOutlet UIWebView * helpWebView;
    IBOutlet L1DownloadProximityMonitor * proximityMonitor;
    IBOutlet UIButton * fetchAllButton;
    IBOutlet UILabel * fetchingLabel;
    IBOutlet UIProgressView * progressView;
    int resourcesToDownload;
    
}

-(IBAction)fetchAll:(id)sender;

@end
