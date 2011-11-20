//
//  HHWalksViewController.m
//  HackneyHear
//
//  Created by Joe Zuntz on 15/11/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import "HHWalksViewController.h"
#import "HackneyHear_ViewController.h"

#define TRY_WALK @"Try this walk"
#define HIDE_WALK @"Hide this walk"

@implementation HHWalksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [scrollView addSubview:contentView];
    [scrollView setContentSize:contentView.frame.size];
    UIColor *pattern = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bkg-pattern.png"]];
    [contentView setBackgroundColor:pattern];
    [scrollView setBackgroundColor:pattern];
    
    for (UIButton * button in walkButtons){
            [button setTitle:TRY_WALK forState:UIControlStateNormal];
    }

}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
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



-(IBAction)clickWalkButton:(id)sender;
{
    UIButton *  clickedButton = (UIButton*)sender;
    int clickedIndex = clickedButton.tag;
    
    int mainViewControllerIndex = 0;
    
    UITabBarController * tabBarController = (UITabBarController *) self.parentViewController;
    HackneyHear_ViewController * viewController = [tabBarController.viewControllers objectAtIndex:mainViewControllerIndex];
    
    //Reset all the other buttons
    for (UIButton * button in walkButtons){
        if (button!=clickedButton){
            [button setTitle:TRY_WALK forState:UIControlStateNormal];
        }
    }
    
    if ([[clickedButton titleForState:UIControlStateNormal] isEqualToString:TRY_WALK]){
        //This means we are currently not doing the walk but want to start
        [clickedButton setTitle:HIDE_WALK forState:UIControlStateNormal];
        [viewController setWalk:clickedIndex]; 
    }
    else{
        //We want to stop the walk
        [clickedButton setTitle:TRY_WALK forState:UIControlStateNormal];
        [viewController setWalk:NO_WALK_SELECTED]; 
     
    }
    
    
}

@end
