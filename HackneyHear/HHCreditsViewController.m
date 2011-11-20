//
//  HHCreditsViewController.m
//  HackneyHear
//
//  Created by Joe Zuntz on 15/11/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import "HHCreditsViewController.h"

@implementation HHCreditsViewController

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


-(IBAction)openAmblrWebpage
{
    NSURL * url = [NSURL URLWithString:@"http://www.amblr.com"];
    [[UIApplication sharedApplication] openURL:url];
}


-(IBAction)openHackneyHearWebpage
{
    NSURL * url = [NSURL URLWithString:@"http://www.hackneyhear.com"];
    [[UIApplication sharedApplication] openURL:url];
}


@end
