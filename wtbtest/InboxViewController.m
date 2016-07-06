//
//  InboxViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 17/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "InboxViewController.h"
#import "MessageViewController.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "Flurry.h"

@interface InboxViewController ()

@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Messages";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"InboxCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    self.convoObjects = [[NSArray alloc]init];
    self.unseenMessages = [[NSMutableArray alloc]init];
    
    [self loadMessages];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [Flurry logEvent:@"Inbox_Tapped"];
    
    [self loadMessages];
}

-(void)loadMessages{
    PFQuery *convosQuery = [PFQuery queryWithClassName:@"convos"];
    [convosQuery whereKey:@"convoId" containsString:[PFUser currentUser].objectId];
    [convosQuery whereKey:@"totalMessages" notEqualTo:@0];
    [convosQuery includeKey:@"buyerUser"];
    [convosQuery includeKey:@"sellerUser"];
    [convosQuery includeKey:@"wtbListing"];
    [convosQuery includeKey:@"lastSent"];
    [convosQuery orderByDescending:@"createdAt"];
    [convosQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                self.convoObjects = objects;
                [self.tableView reloadData];
                [self.tableView.pullToRefreshView stopAnimating];
                
                [self.unseenMessages removeAllObjects];
                
                for (PFObject *convo in objects) {
                    PFObject *msgObject = [convo objectForKey:@"lastSent"];
                    if ([[msgObject objectForKey:@"status"]isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                        [self.unseenMessages addObject:msgObject];
                    }
                }
                // careful! as only showing unseen messages that have been loaded
                if (self.unseenMessages.count > 0) {
                    [self.navigationController tabBarItem].badgeValue = [NSString stringWithFormat:@"%ld", (unsigned long)self.unseenMessages.count];
                    self.navigationItem.title = [NSString stringWithFormat:@"Messages(%ld)", (unsigned long)self.unseenMessages.count];
                }
                else{
                    self.navigationItem.title = @"Messages";
                    [self.navigationController tabBarItem].badgeValue = nil;
                     PFInstallation *installation = [PFInstallation currentInstallation];
                    if (installation.badge != 0) {
                        installation.badge = 0;
                    }
                    [installation saveInBackground];
                }
            }
            else{
                NSLog(@"no convos");
                //update table view
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf loadMessages];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.convoObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!self.cell) {
        self.cell = [[InboxCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    PFObject *convoObject = [self.convoObjects objectAtIndex:indexPath.row];
    
    PFUser *user1 = [convoObject objectForKey:@"user1"];
    PFUser *user2 = [convoObject objectForKey:@"user2"];
    
    if (user1 == [PFUser currentUser]) {
        //current user is user 1
        self.cell.usernameLabel.text = [NSString stringWithFormat:@"%@", user2.username];
        [self.cell.userPicView setFile:[user2 objectForKey:@"picture"]];
        [self.cell.userPicView loadInBackground];
    }
    else{
        //current user is user 2
        self.cell.usernameLabel.text = [NSString stringWithFormat:@"%@", user1.username];
        [self.cell.userPicView setFile:[user1 objectForKey:@"picture"]];
        [self.cell.userPicView loadInBackground];
    }
    
    //set timestamp
    NSDate *convoDate = convoObject.updatedAt;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    BOOL updatedToday = [calendar isDateInToday:convoDate];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setLocale:[NSLocale currentLocale]];
    
    if (updatedToday == YES) {
        //format into the time
        [dateFormat setDateFormat:@"HH:mm"];
    }
    else{
        //format into the day/month
        [dateFormat setDateFormat:@"dd/MM"];
    }
    self.cell.timeLabel.text = [NSString stringWithFormat:@"%@", [dateFormat stringFromDate:convoDate]];
    [self setImageBorder:self.cell.userPicView];
    
    PFObject *wtbListing = [convoObject objectForKey:@"wtbListing"];
    [self.cell.wtbImageView setFile:[wtbListing objectForKey:@"image1"]];
    [self.cell.wtbImageView loadInBackground];
    self.cell.wtbTitleLabel.text = [NSString stringWithFormat:@"%@", [wtbListing objectForKey:@"title"]];
    self.cell.wtbPriceLabel.text = [NSString stringWithFormat:@"£%@", [wtbListing objectForKey:@"listingPrice"]];
    [self setImageBorder:self.cell.wtbImageView];
    
    PFObject *msgObject = [convoObject objectForKey:@"lastSent"];
    NSString *text = [msgObject objectForKey:@"message"];
    
    if ([[msgObject objectForKey:@"mediaMessage"]isEqualToString:@"YES"]) {
        if ([[msgObject objectForKey:@"senderName"]isEqualToString:[PFUser currentUser].username]) {
            self.cell.messageLabel.text = @"you sent a photo 📸";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ sent a photo 📸", [msgObject objectForKey:@"senderName"]];
        }
    }
    else if ([[msgObject objectForKey:@"offer"]isEqualToString:@"YES"]){
        if ([[msgObject objectForKey:@"senderName"]isEqualToString:[PFUser currentUser].username]) {
            self.cell.messageLabel.text = @"you sent an offer 🔌";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ sent an offer 🔌", [msgObject objectForKey:@"senderName"]];
        }
    }
    else{
        self.cell.messageLabel.text = [NSString stringWithFormat:@"%@",text];
    }
    
    if ([[msgObject objectForKey:@"status"] isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //message has not been seen
        [self.cell.unreadIcon setHidden:NO];
    }
    else{
        //message has been seen
        [self.cell.unreadIcon setHidden:YES];
    }
    return self.cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFObject *convoObject = [self.convoObjects objectAtIndex:indexPath.row];
    PFObject *listing = [convoObject objectForKey:@"wtbListing"];
    
    MessageViewController *vc = [[MessageViewController alloc]init];
    vc.convoId = [convoObject objectForKey:@"convoId"];
    vc.convoObject = convoObject;
    vc.listing = listing;
    
    PFUser *buyer = [convoObject objectForKey:@"buyerUser"];
    
    if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
        //current user is buyer so other user is seller
        vc.otherUser = [listing objectForKey:@"sellerUser"];
        vc.userIsBuyer = YES;
    }
    else{
        //other user is buyer, current is seller
        vc.otherUser = [listing objectForKey:@"buyerUser"];
        vc.userIsBuyer = NO;
    }
    vc.otherUserName = @"";
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}
                     
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 119;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end
