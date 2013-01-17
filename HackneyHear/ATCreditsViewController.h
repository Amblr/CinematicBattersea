//
//  HHCreditsViewController.h
//  HackneyHear
//
//  Created by Joe Zuntz on 15/11/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATCreditsViewController : UIViewController
{
    IBOutlet UIScrollView * scrollView;
    IBOutlet UIView * contentView;
}
-(IBAction)openAmblrWebpage;
-(IBAction)openHackneyHearWebpage;
@end
