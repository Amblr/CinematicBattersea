//
//  HHWalksViewController.h
//  HackneyHear
//
//  Created by Joe Zuntz on 15/11/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HHWalksViewController : UIViewController
{
    IBOutlet UIScrollView * scrollView;
    IBOutlet UIView * contentView;
    
    
    IBOutletCollection(UIButton) NSArray * walkButtons;
}

-(IBAction)clickWalkButton:(id)sender;
@end
