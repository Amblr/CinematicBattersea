//
//  HHOptionsMenuController.m
//  HackneyHear
//
//  Created by Joe Zuntz on 12/10/2011.
//  Copyright (c) 2011 Imperial College London. All rights reserved.
//

#import "ATOptionsMenuController.h"
#import "L1DownloadProximityMonitor.h"
#import "L1DownloadManager.h"

@implementation ATOptionsMenuController

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
    [fetchAllButton setHidden:YES];
    [fetchingLabel setHidden:NO];
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
    if (fraction>=0.999)[[NSNotificationCenter defaultCenter] removeObserver:self name:L1_RESOURCE_DATA_IS_READY object:nil];
}

@end
