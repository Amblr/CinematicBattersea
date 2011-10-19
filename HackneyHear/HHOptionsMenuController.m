//
//  HHOptionsMenuController.m
//  HackneyHear
//
//  Created by Joe Zuntz on 12/10/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import "HHOptionsMenuController.h"
#import "L1DownloadProximityMonitor.h"

@implementation HHOptionsMenuController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    [L1DownloadProximityMonitor class];
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
    NSString * helpFile = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
    NSString * helpText = [NSString stringWithContentsOfFile:helpFile encoding:NSASCIIStringEncoding error:nil];
    [helpWebView loadHTMLString:helpText baseURL:[NSURL URLWithString:@""]];
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

-(IBAction)fetchAll:(id)sender
{
    [proximityMonitor downloadAll];
}

@end
