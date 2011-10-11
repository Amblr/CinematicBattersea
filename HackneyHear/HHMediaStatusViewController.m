//
//  HHMediaStatusViewController.m
//  locations1
//
//  Created by Joe Zuntz on 28/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import "HHMediaStatusViewController.h"
#import "L1Node.h"

#define READY_SECTION 0
#define DOWNLOADING_SECTION 1
#define PROBLEM_SECTION 2


@implementation HHMediaStatusViewController
@synthesize scenario;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization

    }
    return self;
}

-(void) awakeFromNib
{
    [super awakeFromNib];
    self.scenario = nil;
    warningIcon = nil;
    doneIcon = nil;
    downloadingIcon = nil;
    readyResources = [[NSMutableArray alloc] initWithCapacity:0];
    problemResources = [[NSMutableArray alloc] initWithCapacity:0];
    downloadingResources = [[NSMutableArray alloc] initWithCapacity:0];

    NSLog(@"View awoken!");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceReady:) name:L1_RESOURCE_DATA_IS_READY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceProblem:) name:L1_RESOURCE_DATA_IS_PROBLEM object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDownloading:) name:L1_RESOURCE_DATA_IS_DOWNLOADING object:nil];

    
}

-(void) resourceDownloading:(NSNotification*) notification
{
    L1Resource * resource = [notification object];

    if ([downloadingResources indexOfObject:resource.name]==NSNotFound) [downloadingResources addObject:resource.name];
    NSLog(@"NOTIFICATION %@",L1_RESOURCE_DATA_IS_DOWNLOADING);
    [self.tableView reloadData];
}


-(void) resourceReady:(NSNotification*) notification
{
    L1Resource * resource = [notification object];
    NSLog(@"NOTIFICATION %@",L1_RESOURCE_DATA_IS_READY);
    NSLog(@"Resource = %@",resource);

    if ([readyResources indexOfObject:resource.name]==NSNotFound) [readyResources addObject:resource.name];
    [downloadingResources removeObject:resource.name];
    [problemResources removeObject:resource.name];
    [self.tableView reloadData];

}

-(void) resourceProblem:(NSNotification*) notification
{
    L1Resource * resource = [notification object];
    NSLog(@"NOTIFICATION %@",L1_RESOURCE_DATA_IS_PROBLEM);

        if ([problemResources indexOfObject:resource.name]==NSNotFound)[problemResources addObject:resource.name];
    [self.tableView reloadData];

}

- (void)dealloc
{
    [super dealloc];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Reload the status of all the resources.
    
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSLog(@"Three sections");
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section==READY_SECTION){
        return [readyResources count];
    }
    else if (section==DOWNLOADING_SECTION){
        return [downloadingResources count];
    }
    else if (section==PROBLEM_SECTION){
        return [problemResources count];
    }
    return 0;
//    NSLog(@"Scenario: %@",self.scenario);
//    // Return the number of rows in the section.
//    if (self.scenario){
//        int N = [self.scenario.nodes count];
//        NSLog(@"Key: %@  (%d nodes)",self.scenario.key,N);
//        return N;
//    }
//    return 0;
}

-(UIImage*) iconForDoneStatus:(BOOL) done downloadingStatus:(BOOL) downloading
{
    if (done){
        if (!doneIcon) doneIcon = [[UIImage imageNamed:@"117-todo.png"] retain];
        return doneIcon;
    }
    if (downloading){
        if (!downloadingIcon) downloadingIcon = [[UIImage imageNamed:@"57-download.png"] retain];
        return downloadingIcon;
    }
    if (!warningIcon) warningIcon  = [[UIImage imageNamed:@"184-warning.png"] retain];
    return warningIcon;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.textLabel.adjustsFontSizeToFitWidth=YES;
    int section = [indexPath indexAtPosition:0];
    int number = [indexPath indexAtPosition:1];
    if (section==READY_SECTION){
        cell.textLabel.text = [readyResources objectAtIndex:number];
        cell.imageView.image = [self iconForDoneStatus:YES downloadingStatus:NO];
    }
    else if (section==PROBLEM_SECTION){
        cell.textLabel.text = [problemResources objectAtIndex:number];
        cell.imageView.image = [self iconForDoneStatus:NO downloadingStatus:NO];
    }
    else if (section==DOWNLOADING_SECTION){
        cell.textLabel.text = [downloadingResources objectAtIndex:number];
        cell.imageView.image = [self iconForDoneStatus:NO downloadingStatus:YES];
        
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
