//
//  HHAboutViewController.m
//  HackneyHear
//
//  Created by Joe Zuntz on 17/11/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import "HHAboutViewController.h"
#import "L1DownloadManager.h"
#import "L1DownloadProximityMonitor.h"

@implementation HHAboutViewController

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
    resourcesToDownload=0;
}

-(void) viewDidAppear:(BOOL)animated
{
    if (resourcesToDownload==0) [checkForNewSoundsButton setTitle:@"Check for new sounds" forState:UIControlStateNormal];

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





-(IBAction)checkForNewSounds
{
    
    [[UIApplication sharedApplication] delegate];
    
    
    [checkForNewSoundsButton setTitle:@"Checking..." forState:UIControlStateNormal];

    [progressView setHidden:NO];
    [progressView setProgress:0.0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDownloaded:) name:L1_RESOURCE_DATA_IS_READY object:nil];
    [proximityMonitor downloadAll];
    resourcesToDownload = [[L1DownloadManager sharedL1DownloadManager] count];
    
}

-(void) resourceDownloaded:(L1Resource*) resource
{
    int n = resourcesToDownload - [[L1DownloadManager sharedL1DownloadManager] count]+1;//plus one because we receive this message before the current resource is removed.
    NSLog(@"Downloaded %d of %d",n,resourcesToDownload);
    float fraction = (1.0*n) / resourcesToDownload;
    [progressView setProgress:fraction];
    if (fraction>=0.999){
        [[NSNotificationCenter defaultCenter] removeObserver:self name: L1_RESOURCE_DATA_IS_READY object:nil];
        [progressView setHidden:YES];
        [checkForNewSoundsButton setTitle:@"Finished!" forState:UIControlStateNormal];
        resourcesToDownload = 0;
    }
}


@end
