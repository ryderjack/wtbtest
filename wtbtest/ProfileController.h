//
//  ProfileController.h
//  wtbtest
//
//  Created by Jack Ryder on 07/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileController : UITableViewController

//cells
@property (strong, nonatomic) IBOutlet UITableViewCell *receivedOffers;
@property (strong, nonatomic) IBOutlet UITableViewCell *sentOffers;
@property (strong, nonatomic) IBOutlet UITableViewCell *purchasedItems;
@property (strong, nonatomic) IBOutlet UITableViewCell *soldItems;

@end
