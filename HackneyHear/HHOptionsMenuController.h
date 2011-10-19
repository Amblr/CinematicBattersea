//
//  HHOptionsMenuController.h
//  HackneyHear
//
//  Created by Joe Zuntz on 12/10/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import <UIKit/UIKit.h>

@class L1DownloadProximityMonitor;
@interface HHOptionsMenuController : UIViewController
{
    IBOutlet UIWebView * helpWebView;
    IBOutlet L1DownloadProximityMonitor * proximityMonitor;
}

-(IBAction)fetchAll:(id)sender;

@end
