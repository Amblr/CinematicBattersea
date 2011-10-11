//
//  HHMediaStatusViewController.h
//  locations1
//
//  Created by Joe Zuntz on 28/07/2011.
//  Copyright 2011 Amblr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L1Scenario.h"


@interface HHMediaStatusViewController : UITableViewController {
    L1Scenario * scenario;
    UIImage * warningIcon;
    UIImage * doneIcon;
    UIImage * downloadingIcon;
    NSMutableArray * readyResources;
    NSMutableArray * downloadingResources;
    NSMutableArray * problemResources;
    
}

@property (retain) L1Scenario * scenario;
@end
