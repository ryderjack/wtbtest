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
#import <Crashlytics/Crashlytics.h>
#import <DGActivityIndicatorView.h>
#import "WelcomeViewController.h"
#import "NavigationController.h"
#import "UIImageView+Letters.h"
#import <Intercom/Intercom.h>

@interface InboxViewController ()

@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"M E S S A G E S";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"InboxCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    self.convoObjects = [[NSMutableArray alloc]init];
    self.allConvoIds = [[NSMutableArray alloc]init];

    self.buyingConvos = [[NSMutableArray alloc]init];
    self.buyingConvoIds = [[NSMutableArray alloc]init];

    self.sellingConvos = [[NSMutableArray alloc]init];
    self.sellingConvoIds = [[NSMutableArray alloc]init];

    self.unseenConvos = [[NSMutableArray alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAllConvos) name:@"NewMessage" object:nil];
    
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setLocale:[NSLocale currentLocale]];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.pullFinished = YES;
    self.infinFinished = YES;
    
    self.justViewedMsg = NO;
    
    self.lastSkipped = 0;
    self.lastSentDate = [[NSDate alloc]init];
    
    //selling query setup
    self.sellingSkipped = 0;
    self.sellingPullFinished = YES;
    self.sellingInfinFinished = YES;
    
    //buying query setup
    self.buyingSkipped = 0;
    self.buyingPullFinished = YES;
    self.buyingInfinFinished = YES;
    
    self.lastConvoIndex = [[NSIndexPath alloc]init];
    self.lastBuyingIndex = [[NSIndexPath alloc]init];
    self.lastSellingIndex = [[NSIndexPath alloc]init];
    
    self.currentInstallation = [PFInstallation currentInstallation];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //fire all 3 queries to start
    [self loadAllConvos];
    
    //load when app comes into foreground
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(loadMessages)
//                                                 name:UIApplicationWillEnterForegroundNotification
//                                               object:[UIApplication sharedApplication]];
    
    if ([PFUser currentUser]) {
        [self checkIfBanned];
    }
    else{
        //no user so show welcome
        [Answers logCustomEventWithName:@"Logging No User Out"
                       customAttributes:@{
                                          @"from":@"Inbox"
                                          }];
        
        
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:NO completion:nil];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
        
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.selectedConvo = @"";
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Inbox"
                                      }];
    
    if (self.justViewedMsg == NO) {
//        NSLog(@"HAVENT SEEN A MESSAGE");
    }
    else{
        self.justViewedMsg = NO;
        [self updateUnseenCount];
    }
        
    //reset last convo as only useful when we're not looking at the inbox
    self.lastConvo = nil;

    [self.infiniteQuery cancel];
    [self.tableView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
}

-(void)loadMessages{
    if(self.pullFinished != YES || ![PFUser currentUser]){
        return;
    }
    
    self.pullFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.infiniteQuery cancel];
    
    if (!self.pullQuery) {
        PFQuery *buyerConvos = [PFQuery queryWithClassName:@"convos"];
        [buyerConvos whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [buyerConvos whereKey:@"buyerDeleted" equalTo:@"NO"];
        
        PFQuery *sellerConvos = [PFQuery queryWithClassName:@"convos"];
        [sellerConvos whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [sellerConvos whereKey:@"sellerDeleted" equalTo:@"NO"];
        
        self.pullQuery = [PFQuery orQueryWithSubqueries:@[buyerConvos, sellerConvos]];
        [self.pullQuery whereKey:@"totalMessages" greaterThan:@0];
        [self.pullQuery includeKey:@"lastSent"];
        
        [self.pullQuery orderByDescending:@"lastSentDate"];
        self.pullQuery.limit = 15;
    }

    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                
//                [self.unseenConvos removeAllObjects]; //this should be in the updateUnseen method only?
                
                if (objects.count == 0) {
                    
                    if (self.segmentedControl.selectedSegmentIndex == 0) {

                        if (!self.topLabel && !self.bottomLabel) {
                            self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                            self.topLabel.textAlignment = NSTextAlignmentCenter;
                            self.topLabel.text = @"No messages";
                            [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                            self.topLabel.numberOfLines = 1;
                            self.topLabel.textColor = [UIColor lightGrayColor];
                            [self.view addSubview:self.topLabel];
                            
                            self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                            self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                            self.bottomLabel.text = @"Explore the Home tab and message sellers or list your items for sale so buyers can get in touch";
                            [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                            self.bottomLabel.numberOfLines = 0;
                            self.bottomLabel.textColor = [UIColor lightGrayColor];
                            [self.view addSubview:self.bottomLabel];
                        }
                        else{
                            [self.topLabel setHidden:NO];
                            [self.bottomLabel setHidden:NO];
                        }
                    
                        [self.allConvoIds removeAllObjects];
                        [self.convoObjects removeAllObjects];
                        
                        [self.tableView reloadData];
                        [self.tableView.pullToRefreshView stopAnimating];
                        [self.tableView.infiniteScrollingView stopAnimating];
                    }

                    self.pullFinished = YES;
                    
                }
                else{
                    if (self.segmentedControl.selectedSegmentIndex == 0) {
                        [self.topLabel setHidden:YES];
                        [self.bottomLabel setHidden:YES];
                    }
                    
                    //add IDs first to avoid index bounds errors
                    NSMutableArray *allIdsPlaceholder = [NSMutableArray array];
                    
                    for (PFObject *convo in objects) {
                        [allIdsPlaceholder addObject:convo.objectId];
                    }
                    
                    //use placeholder to avoid index out of bounds erros if user taps a loaded cell quickly
                    [self.allConvoIds removeAllObjects];
                    [self.allConvoIds addObjectsFromArray:allIdsPlaceholder];
                    
                    [self.convoObjects removeAllObjects];
                    [self.convoObjects addObjectsFromArray:objects];
                    
                    int count = (int)[objects count];
                    self.lastSkipped = count;
                    
                    if (self.segmentedControl.selectedSegmentIndex == 0) {
                        NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
                        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
                        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                        
                        [self.tableView.pullToRefreshView stopAnimating];
                        [self.tableView.infiniteScrollingView stopAnimating];
                    }

                    self.pullFinished = YES;
                }
            }
            else{
//                NSLog(@"no convo objects");
                
                [self.tableView.pullToRefreshView stopAnimating];
                [self.tableView.infiniteScrollingView stopAnimating];
                
                self.pullFinished = YES;

            }
        }
        else{
            NSLog(@"error getting convos %@", error);
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.pullFinished = YES;

        }
    }];
}

-(void)updateUnseenCount{
    if (![PFUser currentUser]) {
        return;
    }
    
    //query for convos we know this user hasn't seen
    PFQuery *buyingUnseenQuery = [PFQuery queryWithClassName:@"convos"];
    [buyingUnseenQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
    [buyingUnseenQuery whereKey:@"buyerUnseen" greaterThan:@0];
    [buyingUnseenQuery whereKey:@"buyerDeleted" equalTo:@"NO"];

    PFQuery *sellingUnseenQuery = [PFQuery queryWithClassName:@"convos"];
    [sellingUnseenQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [sellingUnseenQuery whereKey:@"sellerUnseen" greaterThan:@0];
    [sellingUnseenQuery whereKey:@"sellerDeleted" equalTo:@"NO"];
    
    PFQuery *unseenQuery = [PFQuery orQueryWithSubqueries:@[buyingUnseenQuery, sellingUnseenQuery]];
    [unseenQuery whereKey:@"totalMessages" greaterThan:@0];
    [unseenQuery orderByDescending:@"createdAt"];
    
    [unseenQuery includeKey:@"lastSent"];
    [unseenQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                
                //check if last msg sent is seen
                //if no then retrieves the relevant unseen counter for the user
                //use that on the tab
                
                //check if tab bar was zero then if it was, reload everything
                UITabBarItem *itemToBadge = self.tabBarController.tabBar.items[2];
                int currentTabValue = [itemToBadge.badgeValue intValue];
                
                [self.unseenConvos removeAllObjects];
                
                int totalUnseen = 0;
                int unseen = 0;
                int buyingUnseen = 0;
                int sellingUnseen = 0;
                
                for (PFObject *convo in objects) {

                    PFObject *msgObject = [convo objectForKey:@"lastSent"];
                    
                    if ([[msgObject objectForKey:@"status"]isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {

                        [self.unseenConvos addObject:convo];

                        if ([[PFUser currentUser].objectId isEqualToString:[convo objectForKey:@"buyerId"]]) {
                            //current user is buyer so other user is seller
                            unseen = [[convo objectForKey:@"buyerUnseen"] intValue];
                            
                            if ([convo objectForKey:@"profileConvo"]) {
                                if ([[convo objectForKey:@"profileConvo"] isEqualToString:@"NO"]) {
                                    buyingUnseen = [[convo objectForKey:@"buyerUnseen"] intValue];
                                }
                            }

                        }
                        else{
                            //current user is seller
                            unseen = [[convo objectForKey:@"sellerUnseen"] intValue];

                            if ([convo objectForKey:@"profileConvo"]) {
                                if ([[convo objectForKey:@"profileConvo"] isEqualToString:@"NO"]) {
                                    sellingUnseen = [[convo objectForKey:@"sellerUnseen"] intValue];
                                }
                            }

                        }
                        totalUnseen = totalUnseen + unseen;
                    }
                }
                
                if (totalUnseen != 0) {
                    
                    //we currently call reload only if there's been a change in unread message number - NOT ACCURATE ENOUGH because could read 2 then get 2 mor eunread and it won't reload for e.g. //CHECK
                    if (currentTabValue != totalUnseen) {
                        [self loadAllConvos];
                    }
                    
                    if (totalUnseen > 0) {
                        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%d", totalUnseen]];
                        self.currentInstallation.badge = totalUnseen;
                        [self.currentInstallation saveEventually];
                        
                    }
                    else{
                        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                    }
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
                    
                    if (self.currentInstallation.badge != 0) {
                        self.currentInstallation.badge = 0;
                        [self.currentInstallation saveEventually];
                    }
                }
                
//                NSLog(@"TOTAL UNSEEN %d    BUYING UNSEEN: %d   SELLING UNSEEN: %d", totalUnseen, buyingUnseen, sellingUnseen);
                
                //update segment control badges
                [self updateUnseenSegmentBadges:totalUnseen buyerUnseen:buyingUnseen sellerUnseen:sellingUnseen];
            }
            else{
                //no convos
                NSLog(@"error getting convos %@", error);
                [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
            }
    }];
}

-(void)loadMoreConvos{
    if (self.pullFinished == NO || self.infinFinished == NO) {
        return;
    }
    
    self.infinFinished = NO;
    
    if(!self.infiniteQuery){
        
        PFQuery *buyerConvos = [PFQuery queryWithClassName:@"convos"];
        [buyerConvos whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [buyerConvos whereKey:@"buyerDeleted" equalTo:@"NO"];
        
        PFQuery *sellerConvos = [PFQuery queryWithClassName:@"convos"];
        [sellerConvos whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [sellerConvos whereKey:@"sellerDeleted" equalTo:@"NO"];
        
        self.infiniteQuery = [PFQuery orQueryWithSubqueries:@[buyerConvos, sellerConvos]];
        [self.infiniteQuery whereKey:@"totalMessages" greaterThan:@0];
        [self.infiniteQuery includeKey:@"lastSent"];
        [self.infiniteQuery orderByDescending:@"lastSentDate"];
        self.infiniteQuery.limit = 15;
    }

    self.infiniteQuery.skip = self.lastSkipped;
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastSkipped = self.lastSkipped + count;
            
            NSMutableArray *allIdsPlaceholder = [NSMutableArray array];
            
            for (PFObject *convo in objects) {
                [allIdsPlaceholder addObject:convo.objectId];
            }
            
            [self.allConvoIds addObjectsFromArray:allIdsPlaceholder];
            [self.convoObjects addObjectsFromArray:objects];

            if (self.segmentedControl.selectedSegmentIndex == 0) {
                [self.tableView reloadData];
                [self.tableView.infiniteScrollingView stopAnimating];
            }

            self.infinFinished = YES;
        }
        else{
            NSLog(@"error on infin %@", error);
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                [self.tableView.infiniteScrollingView stopAnimating];
            }
            self.infinFinished = YES;
        }
    }];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf loadAllConvos];
    }];
    
    DGActivityIndicatorView *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.tableView.pullToRefreshView setCustomView:spinner forState:SVPullToRefreshStateAll];
    [spinner startAnimating];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf generalInfinQuery]; //CHECK removed the if here - test
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated{
    //load when app comes into foreground
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return self.convoObjects.count;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        //load buying messages only
        return self.buyingConvos.count;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2) {
        //load selling messages only
        return self.sellingConvos.count;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [Answers logCustomEventWithName:@"Deleted a convo"
                       customAttributes:@{}];
        
        //check if mismatch with index path and datasource
        //so just force a reload
        if (self.segmentedControl.selectedSegmentIndex == 0 && indexPath.row >= self.convoObjects.count) {
            [Answers logCustomEventWithName:@"Deletion mismatch"
                           customAttributes:@{
                                              @"tab":@"all"
                                              }];
            
            [self loadAllConvos];
            return;
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1 && indexPath.row >= self.buyingConvos.count) {
            [Answers logCustomEventWithName:@"Deletion mismatch"
                           customAttributes:@{
                                              @"tab":@"buying"
                                              }];
            [self loadAllConvos];
            return;
        }
        else if (self.segmentedControl.selectedSegmentIndex == 2 && indexPath.row >= self.sellingConvos.count) {
            [Answers logCustomEventWithName:@"Deletion mismatch"
                           customAttributes:@{
                                              @"tab":@"selling"
                                              }];
            [self loadAllConvos];
            return;
        }
        
        //now save convo object as deleted on this user's end

        PFObject *convoObject;
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            convoObject = [self.convoObjects objectAtIndex:indexPath.row];
            
            if ([[convoObject objectForKey:@"sellerId"] isEqualToString:[PFUser currentUser].objectId]) {
                [convoObject setObject:@"YES" forKey:@"sellerDeleted"];
            }
            else if([[convoObject objectForKey:@"buyerId"] isEqualToString:[PFUser currentUser].objectId]){
                [convoObject setObject:@"YES" forKey:@"buyerDeleted"];
            }
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1) {
            //load buying messages only
            convoObject = [self.buyingConvos objectAtIndex:indexPath.row];
            [convoObject setObject:@"YES" forKey:@"buyerDeleted"];

        }
        else if (self.segmentedControl.selectedSegmentIndex == 2) {
            //load selling messages only
            convoObject = [self.sellingConvos objectAtIndex:indexPath.row];
            [convoObject setObject:@"YES" forKey:@"sellerDeleted"];
        }

        [convoObject saveInBackground];
        
        //update tabs

        if (self.segmentedControl.selectedSegmentIndex == 0 && indexPath.row < self.convoObjects.count) {
            [self.convoObjects removeObjectAtIndex:indexPath.row];
            [self.allConvoIds removeObject:convoObject.objectId];
            
            //because we're in the main messages segment, need to update sub-segments (if not a profile convo)
            if ([self.buyingConvoIds containsObject:convoObject.objectId]) {
                //reload buying convos
                [self loadBuyingConvos];
            }
            else if ([self.sellingConvoIds containsObject:convoObject.objectId]) {
                //reload buying convos
                [self loadSellingConvos];
            }
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1 && indexPath.row < self.buyingConvos.count) {
            //remove from buying tab
            [self.buyingConvos removeObjectAtIndex:indexPath.row];
            [self.buyingConvoIds removeObject:convoObject.objectId];

            //and remove from all
            [self loadMessages];
        }
        else if (self.segmentedControl.selectedSegmentIndex == 2 && indexPath.row < self.sellingConvos.count) {
            //remove from selling tab
            [self.sellingConvos removeObjectAtIndex:indexPath.row];
            [self.sellingConvoIds removeObject:convoObject.objectId];

            //and remove from all
            [self loadMessages];
        }
        
        [self updateUnseenCount];
        
        if (indexPath) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!self.cell) {
        self.cell = [[InboxCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    [self.cell.unreadDot setHidden:YES];
    
    self.cell.wtbImageView.image = nil;
    self.cell.userPicView.image = nil;
    
    [self.cell.seenImageView setHidden:YES];
    [self setSeenImageBorder];

    PFObject *convoObject;
    
    if (self.segmentedControl.selectedSegmentIndex == 0 && self.convoObjects.count > indexPath.row) {
        convoObject = [self.convoObjects objectAtIndex:indexPath.row];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1 && self.buyingConvos.count > indexPath.row) {
        //load buying messages only
        convoObject = [self.buyingConvos objectAtIndex:indexPath.row];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2 && self.sellingConvos.count > indexPath.row) {
        //load selling messages only
        convoObject = [self.sellingConvos objectAtIndex:indexPath.row];
    }
    
    BOOL isBuyer = NO;
    NSString *sellerId = [convoObject objectForKey:@"sellerId"];
    
    if ([sellerId isEqualToString:[PFUser currentUser].objectId]) {
        //current user is seller
        self.cell.usernameLabel.text = [NSString stringWithFormat:@"%@", [convoObject objectForKey:@"buyerUsername"]];
        
        //placeholder with initials if no profile pic
        if (![convoObject objectForKey:@"buyerPicture"]) {
            NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                            NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
            
            [self.cell.userPicView setImageWithString:[convoObject objectForKey:@"buyerUsername"] color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
        }
        else{
            [self.cell.userPicView setFile:[convoObject objectForKey:@"buyerPicture"]];
            [self.cell.userPicView loadInBackground];
        }
    }
    else{
        //current user is buyer
        isBuyer = YES;
        self.cell.usernameLabel.text = [NSString stringWithFormat:@"%@", [convoObject objectForKey:@"sellerUsername"]];
        
        //placeholder with initials if no profile pic
        if (![convoObject objectForKey:@"sellerPicture"]) {
            NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                            NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
            
            [self.cell.userPicView setImageWithString:[convoObject objectForKey:@"sellerUsername"] color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
        }
        else{
            [self.cell.userPicView setFile:[convoObject objectForKey:@"sellerPicture"]];
            [self.cell.userPicView loadInBackground];
        }
    }
    
    //set timestamp
    NSDate *convoDate = convoObject[@"lastSentDate"];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    BOOL updatedToday = [calendar isDateInToday:convoDate];
    BOOL updatedInLastWeek = [self isInPastWeek:convoDate];

    if (updatedToday == YES) {
        //format into the time
        [self.dateFormat setDateFormat:@"HH:mm"];
    }
    else if (updatedInLastWeek){
        [self.dateFormat setDateFormat:@"EEE"];
    }
    else{
        //format into date
        [self.dateFormat setDateFormat:@"dd MMM"];
    }
    self.cell.timeLabel.text = [NSString stringWithFormat:@"%@", [self.dateFormat stringFromDate:convoDate]];
    
    //mask profile to circle and item to rounded corners
    [self setProfImageBorder];
    [self setWTSImageBorder];
    
    [self.cell.wtbImageView setFile:[convoObject objectForKey:@"thumbnail"]];
    [self.cell.wtbImageView loadInBackground];

    PFObject *msgObject = [convoObject objectForKey:@"lastSent"];
    NSString *text = [msgObject objectForKey:@"message"];
    
    //setup inbox cell preview text
    if ([[msgObject objectForKey:@"mediaMessage"]isEqualToString:@"YES"]) {
        
        if ([[msgObject objectForKey:@"senderName"]isEqualToString:[PFUser currentUser].username]) {
            self.cell.messageLabel.text = @"You sent a photo 📷";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"@%@ sent a photo 📷", [msgObject objectForKey:@"senderName"]];
        }
    }
    else if ([[msgObject objectForKey:@"sharedMessage"]isEqualToString:@"YES"]){
        if ([msgObject objectForKey:@"Sale"]) {
            //shared a for sale item
            if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                self.cell.messageLabel.text = @"You shared a listing 📲";
            }
            else{
                self.cell.messageLabel.text = [NSString stringWithFormat:@"@%@ shared a listing 📲", [msgObject objectForKey:@"senderName"]];
            }
        }
        else{
            if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                self.cell.messageLabel.text = @"You shared a wanted listing 📲";
            }
            else{
                self.cell.messageLabel.text = [NSString stringWithFormat:@"@%@ shared a wanted listing 📲", [msgObject objectForKey:@"senderName"]];
            }
        }
    }
    else if ([[msgObject objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
        if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
            self.cell.messageLabel.text = @"You sent your PayPal 💰";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"@%@ sent their PayPal 🛒", [msgObject objectForKey:@"senderName"]];
        }
    }
    else{
        if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
            self.cell.messageLabel.text = [NSString stringWithFormat:@"You: %@",text];
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"%@",text];
        }
    }
    
    //set text as bold/normal depending on last message status
    if ([convoObject.objectId isEqualToString:self.lastConvo.objectId] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        
        //this is the convo the user is currently in so set the last sent to 'Seen' if sent by other user
        [self megaUnbold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //unseen message sent by other user
        //hide pic
        [self.cell.unreadDot setHidden:NO];
        
        //bold text
        [self megaBold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"sent"] && [[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //unseen message sent by me
        //hide pic
        
        //unbolded
        [self megaUnbold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"seen"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //seen message sent by other user

        //unbolded
        [self megaUnbold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"seen"] && [[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //seen message sent by me
        //show pic
        [self.cell.seenImageView setHidden:NO];
        
        if (isBuyer == YES) {
            
            if (![convoObject objectForKey:@"sellerPicture"]) {
                NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:5],
                                                NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [self.cell.seenImageView setImageWithString:[convoObject objectForKey:@"sellerUsername"] color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
            }
            else{
                [self.cell.seenImageView setFile:[convoObject objectForKey:@"sellerPicture"]];
                [self.cell.seenImageView loadInBackground];
            }
            
        }
        else{
            if (![convoObject objectForKey:@"buyerPicture"]) {
                NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:5],
                                                NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [self.cell.seenImageView setImageWithString:[convoObject objectForKey:@"buyerUsername"] color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
            }
            else{
                [self.cell.seenImageView setFile:[convoObject objectForKey:@"buyerPicture"]];
                [self.cell.seenImageView loadInBackground];
            }
        }
        
        //unbolded
        [self megaUnbold];
    }
    else{
        //fail safe
        NSLog(@"fail safing");
        [self megaUnbold];
    }
    
    return self.cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFObject *convoObject;
    
    self.lastConvoIndex = indexPath;

    if (self.segmentedControl.selectedSegmentIndex == 0 && indexPath.row < self.convoObjects.count) {
        convoObject = [self.convoObjects objectAtIndex:indexPath.row];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1 && indexPath.row < self.buyingConvos.count) {
        //load buying messages only
        convoObject = [self.buyingConvos objectAtIndex:indexPath.row];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2 && indexPath.row < self.sellingConvos.count) {
        //load selling messages only
        convoObject = [self.sellingConvos objectAtIndex:indexPath.row];
    }
    else{
        //something went wrong so just reload everything
        [self loadAllConvos];
        return;
    }
    
    //reload the cell so we it unbolds quickly
    PFObject *msgObject = [convoObject objectForKey:@"lastSent"];
    
    if (![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        
        [msgObject setObject:@"seen" forKey:@"status"];
        NSLog(@"set msg as seen");
        
        //set as seen in other relevant inbox segments too
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            
            if ([self.sellingConvoIds containsObject:convoObject.objectId]) {
                //get last sent
                PFObject *sellingMsg = [self.sellingConvos[[self.sellingConvoIds indexOfObject:convoObject.objectId]] objectForKey:@"lastSent"];
                //mark selling convo as seen too
                [sellingMsg setObject:@"seen" forKey:@"status"];
            }
            else if ([self.buyingConvoIds containsObject:convoObject.objectId]) {
                //get last sent
                PFObject *buyingMsg = [self.buyingConvos[[self.buyingConvoIds indexOfObject:convoObject.objectId]] objectForKey:@"lastSent"];
                //mark selling convo as seen too
                [buyingMsg setObject:@"seen" forKey:@"status"];
            }

        }
        else if (self.segmentedControl.selectedSegmentIndex == 1 || self.segmentedControl.selectedSegmentIndex == 2 ) {
            //update all segment too
            
//            NSLog(@"INDEX: %lu",(unsigned long)[self.allConvoIds indexOfObject:convoObject.objectId]);
            
            //added in the second check to prevent out of bounds errors
            if ([self.allConvoIds containsObject:convoObject.objectId] && self.convoObjects.count > [self.allConvoIds indexOfObject:convoObject.objectId]) {
                PFObject *allMsg = [self.convoObjects[[self.allConvoIds indexOfObject:convoObject.objectId]] objectForKey:@"lastSent"];
                //CHECK mark convo in all tab as seen too if we have 2 unseen then tap the lower then read the upper (in selling tab) does the ALL tab change?
                [allMsg setObject:@"seen" forKey:@"status"];
            }
        }
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    int unseen = 0;
    int buyingUnseen = 0;
    int sellingUnseen = 0;
    
    PFUser *buyer = [convoObject objectForKey:@"buyerUser"];

    if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
        //current user is buyer so other user is seller
        buyingUnseen = [[convoObject objectForKey:@"buyerUnseen"] intValue];
        unseen = [[convoObject objectForKey:@"buyerUnseen"] intValue];
    }
    else{
        //other user is buyer, current is seller
        sellingUnseen = [[convoObject objectForKey:@"sellerUnseen"] intValue];
        unseen = [[convoObject objectForKey:@"sellerUnseen"] intValue];
    }
    
    UITabBarItem *itemToBadge = self.tabBarController.tabBar.items[2];
    int currentTabValue = [itemToBadge.badgeValue intValue];
    int newTabValue = currentTabValue - unseen;
    
    if (newTabValue == 0) {
        [self.navigationController tabBarItem].badgeValue = nil;
        self.currentInstallation.badge = 0;
        
        self.sellingBadge.alpha = 0.0;
        self.buyingBadge.alpha = 0.0;
        self.allBadge.alpha = 0.0;
    }
    
    else if (newTabValue > 0){
        
        //add badge to relevant segment control section
        [self.navigationController tabBarItem].badgeValue = [NSString stringWithFormat:@"%d", newTabValue];
        
        self.currentInstallation.badge = newTabValue;
    }
    
    else{
        NSLog(@"error calc'n %d", newTabValue);
        self.currentInstallation.badge = 0;
        [self.navigationController tabBarItem].badgeValue = nil;
    }
    
    [self.currentInstallation saveEventually];

    self.selectedConvo = convoObject.objectId;
    
    MessageViewController *vc = [[MessageViewController alloc]init];
    vc.convoId = [convoObject objectForKey:@"convoId"];
    vc.convoObject = convoObject;
    vc.delegate = self;
    
    if ([[convoObject objectForKey:@"pureWTS"]isEqualToString:@"YES"]) {
        if ([convoObject objectForKey:@"wtsListing"]) {
            vc.listing = [convoObject objectForKey:@"wtsListing"];
        }
        vc.pureWTS = YES;
    }
    else if ([[convoObject objectForKey:@"profileConvo"]isEqualToString:@"YES"]){
        vc.pureWTS = YES;
        vc.profileConvo = YES;
    }
    else{
        PFObject *listing = [convoObject objectForKey:@"wtbListing"];
        vc.listing = listing;
    }
    
    if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
        //current user is buyer so other user is seller
//        NSLog(@"IM THE BUYER");
        vc.otherUser = [convoObject objectForKey:@"sellerUser"];
        vc.userIsBuyer = YES;
    }
    else{
//        NSLog(@"IM THE SELLER");
        //other user is buyer, current is seller
        vc.otherUser = buyer;
        vc.userIsBuyer = NO;
    }
    vc.otherUserName = @"";
    self.justViewedMsg = YES;
    self.lastConvo = convoObject;
    self.lastSentDate = msgObject.createdAt;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)updateUnseenSegmentBadges:(int)unseen buyerUnseen:(int)buyingUnseen sellerUnseen:(int)sellingUnseen{
    if (unseen > 0) {
        //show the A L L badge
        self.allBadge.alpha = 1.0;
        
        if (buyingUnseen > 0) {
            //show B U Y E R badge
            self.buyingBadge.alpha = 1.0;
        }
        else{
            //hide
            self.buyingBadge.alpha = 0.0;
        }
        
        if (sellingUnseen > 0) {
            //show S E L L E R badge
            self.sellingBadge.alpha = 1.0;
        }
        else{
            //hide
            self.sellingBadge.alpha = 0.0;
        }
    }
    else{
        //hide all 3 badges
        self.sellingBadge.alpha = 0.0;
        self.buyingBadge.alpha = 0.0;
        self.allBadge.alpha = 0.0;

    }
}

//multiple bcoz of imageview.cornerradius bug
-(void)setWTSImageBorder{
    self.cell.wtbImageView.layer.cornerRadius = 2;
    self.cell.wtbImageView.layer.masksToBounds = YES;
    self.cell.wtbImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.cell.wtbImageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)setProfImageBorder{
    self.cell.userPicView.layer.cornerRadius = 25;
    self.cell.userPicView.layer.masksToBounds = YES;
    self.cell.userPicView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.cell.userPicView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)setSeenImageBorder{
    self.cell.seenImageView.layer.cornerRadius = 8;
    self.cell.seenImageView.layer.masksToBounds = YES;
    self.cell.seenImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.cell.seenImageView.contentMode = UIViewContentModeScaleAspectFill;
}
                     
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 84;
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

-(void)boldFontForLabel:(UILabel *)label{
    UIFont *currentFont = label.font;
    UIFont *boldFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:currentFont.pointSize];
    label.font = boldFont;
}

-(void)unboldFontForLabel:(UILabel *)label{
    UIFont *currentFont = label.font;
    UIFont *newFont;
    newFont = [UIFont fontWithName:@"PingFangSC-Regular" size:currentFont.pointSize];
    label.font = newFont;
}

-(void)megaUnbold{
    [self unboldFontForLabel:self.cell.usernameLabel];
    [self unboldFontForLabel:self.cell.messageLabel];
    [self unboldFontForLabel:self.cell.timeLabel];
    self.cell.messageLabel.textColor = [UIColor lightGrayColor];
    self.cell.timeLabel.textColor = [UIColor colorWithRed:0.81 green:0.81 blue:0.81 alpha:1.0];
    [self.cell.wtbTitleLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13]];
}

-(void)megaBold{
    [self boldFontForLabel:self.cell.usernameLabel];
    [self boldFontForLabel:self.cell.messageLabel];
    self.cell.messageLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.cell.timeLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self unboldFontForLabel:self.cell.wtbTitleLabel];
}

#pragma mark - messageVC delegates

-(void)lastMessageInConvo:(NSString *)message incomingMsg:(BOOL)incoming{
    
//    NSLog(@"last msg reload with index: %ld    and convo: %@", (long)self.lastConvoIndex.row, self.lastConvo.objectId);
    
//    NSLog(@"CURRENT CONVO: %@   SELECTED CONVO: %@", self.selectedConvo, self.lastConvo.objectId);
    
    if (!self.lastConvo || !self.lastConvoIndex || self.lastConvoIndex.row >= [self.tableView numberOfRowsInSection:0] || self.updatingLastMessage == YES) {
        return;
    }
    
    self.updatingLastMessage = YES;
    
    if (self.segmentedControl.selectedSegmentIndex == 0 && self.lastConvoIndex.row < self.convoObjects.count && self.convoObjects.count == self.allConvoIds.count) {
        
        //if its already at the top, don't need to move anything
        if (self.lastConvoIndex.row > 0 && [self.allConvoIds indexOfObject:self.lastConvo.objectId] < self.allConvoIds.count) {
            //update convos
            [self.convoObjects removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
            [self.convoObjects insertObject:self.lastConvo atIndex:0];
            
            //update Ids array
            [self.allConvoIds removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
            [self.allConvoIds insertObject:self.lastConvo.objectId atIndex:0];
            
            //remove duplications
            NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:self.convoObjects];
            NSArray *arrayWithoutDuplicates = [orderedSet array];
            
            [self.convoObjects removeAllObjects];
            [self.convoObjects addObjectsFromArray:arrayWithoutDuplicates];
            
            NSOrderedSet *orderedSet1 = [NSOrderedSet orderedSetWithArray:self.allConvoIds];
            NSArray *arrayWithoutDuplicates1 = [orderedSet1 array];
            
            [self.allConvoIds removeAllObjects];
            [self.allConvoIds addObjectsFromArray:arrayWithoutDuplicates1];
        }
        
        //because we're in the main messages segment, need to update sub-segments (if not a profile convo)
        if ([self.buyingConvoIds containsObject:self.lastConvo.objectId] && [self.buyingConvoIds indexOfObject:self.lastConvo.objectId] < self.buyingConvoIds.count) {

            if ([self.buyingConvoIds indexOfObject:self.lastConvo.objectId] > 0) {
//                NSLog(@"moved chat at index: %lu now  onto buying segment",(unsigned long)[self.buyingConvoIds indexOfObject:self.lastConvo.objectId]);

                //get index & move to top
                [self.buyingConvos removeObjectAtIndex: [self.buyingConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.buyingConvos insertObject:self.lastConvo atIndex:0];
                
                //update Ids array
                [self.buyingConvoIds removeObjectAtIndex:[self.buyingConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.buyingConvoIds insertObject:self.lastConvo.objectId atIndex:0];
            }
            else{
                //already at index zero so just refresh with latest message sent
                [self.buyingConvos removeObjectAtIndex: [self.buyingConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.buyingConvos insertObject:self.lastConvo atIndex:0];
            }

        }
        if ([self.sellingConvoIds containsObject:self.lastConvo.objectId]  && [self.sellingConvoIds indexOfObject:self.lastConvo.objectId] < self.sellingConvoIds.count) {
            
            if ([self.sellingConvoIds indexOfObject:self.lastConvo.objectId] > 0) {
//                NSLog(@"moved chat at index: %lu now  onto selling segment",(unsigned long)[self.sellingConvoIds indexOfObject:self.lastConvo.objectId]);
                
                //get index & move to top
                [self.sellingConvos removeObjectAtIndex: [self.sellingConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.sellingConvos insertObject:self.lastConvo atIndex:0];
                
                //update Ids array
                [self.sellingConvoIds removeObjectAtIndex:[self.sellingConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.sellingConvoIds insertObject:self.lastConvo.objectId atIndex:0];
            }
            else{
                [self.sellingConvos removeObjectAtIndex: [self.sellingConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.sellingConvos insertObject:self.lastConvo atIndex:0];
            }
            
        }
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1 && self.lastConvoIndex.row < self.buyingConvos.count && self.buyingConvos.count == self.buyingConvoIds.count) {
        
        if (self.lastConvoIndex.row > 0 && [self.buyingConvoIds indexOfObject:self.lastConvo.objectId] < self.buyingConvoIds.count) {
//            NSLog(@"MOVING IN BUYING ARRAY");

            //load buying messages only
            [self.buyingConvos removeObjectAtIndex:[self.buyingConvoIds indexOfObject:self.lastConvo.objectId]];
            [self.buyingConvos insertObject:self.lastConvo atIndex:0];
            
            //update Ids array
            [self.buyingConvoIds removeObjectAtIndex:[self.buyingConvoIds indexOfObject:self.lastConvo.objectId]];
            [self.buyingConvoIds insertObject:self.lastConvo.objectId atIndex:0];
        }
        
        //check if this convo has been loaded in allConvos first
        if ([self.allConvoIds containsObject:self.lastConvo.objectId]) {
            if ([self.allConvoIds indexOfObject:self.lastConvo.objectId] > 0 && [self.allConvoIds indexOfObject:self.lastConvo.objectId] < self.allConvoIds.count) {
                //            NSLog(@"MOVING IN ALL ARRAY");
                //and move to top
                [self.convoObjects removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.convoObjects insertObject:self.lastConvo atIndex:0];
                
                //update allIds array
                [self.allConvoIds removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.allConvoIds insertObject:self.lastConvo.objectId atIndex:0];
            }
            else{
                [self.convoObjects removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.convoObjects insertObject:self.lastConvo atIndex:0];
            }
        }
        else{
            //user hasn't loaded this convo in the allConvos tab (hasn't infin loaded far enough)
            //so we can only insert the convo at the top & update allConvosId array
            
            [self.convoObjects insertObject:self.lastConvo atIndex:0];
            [self.allConvoIds insertObject:self.lastConvo.objectId atIndex:0];

        }

    }
    else if (self.segmentedControl.selectedSegmentIndex == 2 && self.lastConvoIndex.row < self.sellingConvos.count && self.sellingConvos.count == self.sellingConvoIds.count) {
        
        //load selling messages only
        if (self.lastConvoIndex.row > 0 && [self.sellingConvoIds indexOfObject:self.lastConvo.objectId] < self.sellingConvoIds.count) {
            [self.sellingConvos removeObjectAtIndex:[self.sellingConvoIds indexOfObject:self.lastConvo.objectId]];
            [self.sellingConvos insertObject:self.lastConvo atIndex:0];
            
            //update Ids array
            [self.sellingConvoIds removeObjectAtIndex:[self.sellingConvoIds indexOfObject:self.lastConvo.objectId]];
            [self.sellingConvoIds insertObject:self.lastConvo.objectId atIndex:0];
        }
        
        //check if this convo has been loaded in allConvos first
        if ([self.allConvoIds containsObject:self.lastConvo.objectId]) {
            if ([self.allConvoIds indexOfObject:self.lastConvo.objectId] > 0 && [self.allConvoIds indexOfObject:self.lastConvo.objectId] < self.allConvoIds.count) {
                //            NSLog(@"MOVING IN ALL ARRAY");
                //and move to top
                [self.convoObjects removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.convoObjects insertObject:self.lastConvo atIndex:0];
                
                //update allIds array
                [self.allConvoIds removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.allConvoIds insertObject:self.lastConvo.objectId atIndex:0];
            }
            else{
                [self.convoObjects removeObjectAtIndex:[self.allConvoIds indexOfObject:self.lastConvo.objectId]];
                [self.convoObjects insertObject:self.lastConvo atIndex:0];
            }
        }
        else{
            //user hasn't loaded this convo in the allConvos tab (hasn't infin loaded far enough)
            //so we can only insert the convo at the top & update allConvosId array
            
            [self.convoObjects insertObject:self.lastConvo atIndex:0];
            [self.allConvoIds insertObject:self.lastConvo.objectId atIndex:0];
            
        }
    }

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ //this wait here is important
        [self.tableView reloadData];
                
        //make sure top cell is unbolded because it's contents are 100% seen by this user since they've been in that convo
        InboxCell *cell = (InboxCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

        [self unboldFontForLabel:cell.usernameLabel];
        [self unboldFontForLabel:cell.messageLabel];
        [self unboldFontForLabel:cell.timeLabel];
        cell.messageLabel.textColor = [UIColor lightGrayColor];
        cell.timeLabel.textColor = [UIColor colorWithRed:0.81 green:0.81 blue:0.81 alpha:1.0];
        [cell.wtbTitleLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:13]];

        //update top cell label
        cell.messageLabel.text = [NSString stringWithFormat:@"%@", message];
        
        //update time label
        [self.dateFormat setDateFormat:@"HH:mm"];
        cell.timeLabel.text = [NSString stringWithFormat:@"%@", [self.dateFormat stringFromDate:[NSDate date]]];
        
        //hide seen icon
        [cell.seenImageView setHidden:YES];

    });

    self.updatingLastMessage = NO;

}

-(void)doubleTapScroll{
    if (self.justViewedMsg == NO) {
        if ([self.tableView numberOfRowsInSection:0] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

-(void)checkIfBanned{
    PFQuery *bannedQuery = [PFQuery queryWithClassName:@"bannedUsers"];
    [bannedQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    
    //also check if device is banned to prevent creating new accounts
    PFInstallation *installation = [PFInstallation currentInstallation];
    PFQuery *bannedInstallsQuery = [PFQuery queryWithClassName:@"bannedUsers"];
    
    if (installation.deviceToken) {
        [bannedInstallsQuery whereKey:@"deviceToken" equalTo:installation.deviceToken];
    }
    else{
        //to prevent simulator returning loads of results and fucking up banning logic
        [bannedInstallsQuery whereKey:@"deviceToken" equalTo:@"thisISNothing"];
    }
    PFQuery *megaBanQuery = [PFQuery orQueryWithSubqueries:@[bannedQuery]];
    [megaBanQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //user is banned - log them out
            
            [Answers logCustomEventWithName:@"Logging Banned User Out"
                           customAttributes:@{
                                              @"from":@"Inbox"
                                              }];
            
            [PFUser logOut];
            [Intercom reset];

            WelcomeViewController *vc = [[WelcomeViewController alloc]init];
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navController animated:NO completion:nil];

            //to prevent user signing up again if they don't have a device token
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"banned"];
        }
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 50;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"header"];
    headerView.contentView.backgroundColor = [UIColor whiteColor];
    
    if (headerView == nil) {
        [tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"header"];
        headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"header"];
    }
    
    if (!self.segmentedControl) {
        self.segmentedControl = [[HMSegmentedControl alloc] init];
        self.segmentedControl.frame = CGRectMake(0,0, [UIApplication sharedApplication].keyWindow.frame.size.width,50);
        self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
        self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
        self.segmentedControl.selectionIndicatorHeight = 2;
        self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:9],NSForegroundColorAttributeName : [UIColor lightGrayColor]};
        
        self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
        [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
        
        //divide width of view by 3 to get x.origin of each title segment
        
        self.allBadge = [[UIView alloc]initWithFrame:CGRectMake((([ [ UIScreen mainScreen ] bounds ].size.width/3)/2)+18, 17, 5,5)];
        [self.allBadge.layer setCornerRadius:2.5];
        self.allBadge.backgroundColor = [UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0];
        self.allBadge.alpha = 0.0;
        [self.segmentedControl addSubview:self.allBadge];
        
        self.buyingBadge = [[UIView alloc]initWithFrame:CGRectMake(([ [ UIScreen mainScreen ] bounds ].size.width/2)+33, 17, 5,5)];
        [self.buyingBadge.layer setCornerRadius:2.5];
        self.buyingBadge.backgroundColor = [UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0];
        self.buyingBadge.alpha = 0.0;
        [self.segmentedControl addSubview:self.buyingBadge];
        
        self.sellingBadge = [[UIView alloc]initWithFrame:CGRectMake( (([ [ UIScreen mainScreen ] bounds ].size.width/2)+36) + ([ [ UIScreen mainScreen ] bounds ].size.width/3), 17, 5,5)];
        [self.sellingBadge.layer setCornerRadius:2.5];
        self.sellingBadge.backgroundColor = [UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0];
        self.sellingBadge.alpha = 0.0;
        [self.segmentedControl addSubview:self.sellingBadge];

        [self.segmentedControl setSectionTitles:@[@"A L L",@"B U Y I N G",@"S E L L I N G"]];
    }
    
    [headerView.contentView addSubview:self.segmentedControl];
    

    return headerView;
}

#pragma mark - colour part of label

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setColorForText:(NSString*) textToFind withColor:(UIColor*) color
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
    
    return mainString;
}

-(void)segmentControlChanged{

    [self.topLabel setHidden:YES];
    [self.bottomLabel setHidden:YES];
    
    [self.tableView reloadData];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if (self.convoObjects.count != 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //show no results label
            
            if (!self.topLabel && !self.bottomLabel) {
                self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                self.topLabel.textAlignment = NSTextAlignmentCenter;
                self.topLabel.text = @"No messages";
                [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                self.topLabel.numberOfLines = 1;
                self.topLabel.textColor = [UIColor lightGrayColor];
                [self.view addSubview:self.topLabel];

                self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                self.bottomLabel.text = @"Explore the Home tab and message sellers or list your items for sale so buyers can get in touch";
                [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                self.bottomLabel.numberOfLines = 0;
                self.bottomLabel.textColor = [UIColor lightGrayColor];
                [self.view addSubview:self.bottomLabel];
            }
            else{
                self.bottomLabel.text = @"Explore the Home tab and message sellers or list your items for sale so buyers can get in touch";

                [self.topLabel setHidden:NO];
                [self.bottomLabel setHidden:NO];
            }
        }
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        //load buying messages only
        if (self.buyingConvos.count != 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //show no results label
            
            if (!self.topLabel && !self.bottomLabel) {
                self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                self.topLabel.textAlignment = NSTextAlignmentCenter;
                self.topLabel.text = @"No messages";
                [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                self.topLabel.numberOfLines = 1;
                self.topLabel.textColor = [UIColor lightGrayColor];
                [self.view addSubview:self.topLabel];
                
                self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                self.bottomLabel.text = @"Messages about items you want to buy will appear here";
                [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                self.bottomLabel.numberOfLines = 0;
                self.bottomLabel.textColor = [UIColor lightGrayColor];
                [self.view addSubview:self.bottomLabel];
            }
            else{
                self.bottomLabel.text = @"Messages about items you want to buy will appear here";

                [self.topLabel setHidden:NO];
                [self.bottomLabel setHidden:NO];
            }
        }
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2) {
        //load selling messages only
        if (self.sellingConvos.count != 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //show no results label
            
            if (!self.topLabel && !self.bottomLabel) {
                self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                self.topLabel.textAlignment = NSTextAlignmentCenter;
                self.topLabel.text = @"No messages";
                [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                self.topLabel.numberOfLines = 1;
                self.topLabel.textColor = [UIColor lightGrayColor];
                [self.view addSubview:self.topLabel];
                
                self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                self.bottomLabel.text = @"Messages about items you're selling will appear here";
                [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                self.bottomLabel.numberOfLines = 0;
                self.bottomLabel.textColor = [UIColor lightGrayColor];
                [self.view addSubview:self.bottomLabel];
            }
            else{
                self.bottomLabel.text = @"Messages about items you're selling will appear here";

                [self.topLabel setHidden:NO];
                [self.bottomLabel setHidden:NO];
            }
        }
    }
}

-(void)generalInfinQuery{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self loadMoreConvos];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        //load buying messages only
        [self loadMoreBuying];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2) {
        //load selling messages only
        [self loadMoreSelling];
        
    }
}

-(void)loadSellingConvos{
    self.sellingPullFinished = NO;
    
    if (!self.sellingPullQuery) {
        
        self.sellingPullQuery = [PFQuery queryWithClassName:@"convos"];
        [self.sellingPullQuery whereKey:@"totalMessages" greaterThan:@0];
        [self.sellingPullQuery includeKey:@"lastSent"];
        [self.sellingPullQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [self.sellingPullQuery whereKey:@"profileConvo" equalTo:@"NO"];
        
        //don't retrieve deleted convos
        [self.sellingPullQuery whereKey:@"sellerDeleted" equalTo:@"NO"];
        
        [self.sellingPullQuery orderByDescending:@"lastSentDate"];
        
        self.sellingPullQuery.limit = 15;
    }

    
    [self.sellingPullQuery cancel];
    [self.sellingPullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                
                if (objects.count == 0) {
                    
                    if (self.segmentedControl.selectedSegmentIndex == 2) {

                        if (!self.topLabel && !self.bottomLabel) {
                            self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                            self.topLabel.textAlignment = NSTextAlignmentCenter;
                            self.topLabel.text = @"No messages";
                            [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                            self.topLabel.numberOfLines = 1;
                            self.topLabel.textColor = [UIColor lightGrayColor];
                            [self.view addSubview:self.topLabel];
                            
                            self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                            self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                            self.bottomLabel.text = @"Messages about items you're selling will appear here";
                            [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                            self.bottomLabel.numberOfLines = 0;
                            self.bottomLabel.textColor = [UIColor lightGrayColor];
                            [self.view addSubview:self.bottomLabel];
                        }
                        else{
                            self.bottomLabel.text = @"Messages about items you're selling will appear here";
                            
                            [self.topLabel setHidden:NO];
                            [self.bottomLabel setHidden:NO];
                        }
                    
                        [self.sellingConvoIds removeAllObjects];
                        [self.sellingConvos removeAllObjects];

                        [self.tableView reloadData];
                        [self.tableView.pullToRefreshView stopAnimating];
                    }

                    self.sellingPullFinished = YES;
                }
                else{
                    if (self.segmentedControl.selectedSegmentIndex == 2) {
                        [self.topLabel setHidden:YES];
                        [self.bottomLabel setHidden:YES];
                    }

                    //load IDs first so can be sure their index exists
                    NSMutableArray *sellingIdsPlaceholder = [NSMutableArray array];
                    
                    for (PFObject *convo in objects) {
                        [sellingIdsPlaceholder addObject:convo.objectId];
                    }
                    
                    //use placeholder to avoid index out of bounds erros if user taps a loaded cell quickly
                    [self.sellingConvoIds removeAllObjects];
                    [self.sellingConvoIds addObjectsFromArray:sellingIdsPlaceholder];
                    
                    [self.sellingConvos removeAllObjects];
                    [self.sellingConvos addObjectsFromArray:objects];
                    
                    int count = (int)[objects count];
                    self.sellingSkipped = count;
                    
                    if (self.segmentedControl.selectedSegmentIndex == 2) {
                        NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
                        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
                        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                        
                        [self.tableView.pullToRefreshView stopAnimating];
                    }
                
                    self.sellingPullFinished = YES;
                }
            }
            else{
                NSLog(@"error");
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)loadMoreSelling{
    if (self.sellingPullFinished == NO || self.sellingInfinFinished == NO) {
        return;
    }
    self.sellingInfinFinished = NO;
    
    if (!self.sellingInfiniteQuery) {
        self.sellingInfiniteQuery = [PFQuery queryWithClassName:@"convos"];

        [self.sellingInfiniteQuery whereKey:@"totalMessages" greaterThan:@0];
        [self.sellingInfiniteQuery includeKey:@"lastSent"];
        [self.sellingInfiniteQuery orderByDescending:@"lastSentDate"];
        
        self.sellingInfiniteQuery.limit = 15;
        [self.sellingInfiniteQuery whereKey:@"profileConvo" equalTo:@"NO"];
        [self.sellingInfiniteQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        
        //don't retrieve deleted convos
        [self.sellingInfiniteQuery whereKey:@"sellerDeleted" equalTo:@"NO"];
    }
    
    self.sellingInfiniteQuery.skip = self.sellingSkipped;
    [self.sellingInfiniteQuery cancel];
    [self.sellingInfiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.sellingSkipped = self.sellingSkipped + count;
            
            NSMutableArray *sellingIdsPlaceholder = [NSMutableArray array];
            
            for (PFObject *convo in objects) {
                [sellingIdsPlaceholder addObject:convo.objectId];
            }
            
            [self.sellingConvoIds addObjectsFromArray:sellingIdsPlaceholder];
            [self.sellingConvos addObjectsFromArray:objects];
            
            if (self.segmentedControl.selectedSegmentIndex == 2) {
                [self.tableView reloadData];
                [self.tableView.infiniteScrollingView stopAnimating];
            }

            self.sellingInfinFinished = YES;
        }
        else{
            NSLog(@"error on infin %@", error);
            
            if (self.segmentedControl.selectedSegmentIndex == 2) {
                [self.tableView.infiniteScrollingView stopAnimating];
            }
            self.sellingInfinFinished = YES;
        }
    }];
}

-(void)loadBuyingConvos{
    self.buyingPullFinished = NO;
    //    self.justViewedMsg = NO;
    
    if (!self.buyingPullQuery) {
        self.buyingPullQuery = [PFQuery queryWithClassName:@"convos"];
        [self.buyingPullQuery whereKey:@"totalMessages" greaterThan:@0];
        [self.buyingPullQuery includeKey:@"lastSent"];
        [self.buyingPullQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [self.buyingPullQuery whereKey:@"profileConvo" equalTo:@"NO"];
        
        //don't retrieve deleted convos (each user has their own custom key on the convo object to track their deletes)
        [self.buyingPullQuery whereKey:@"buyerDeleted" equalTo:@"NO"];
        
        [self.buyingPullQuery orderByDescending:@"lastSentDate"];
        self.buyingPullQuery.limit = 15;
    }
    
    [self.buyingPullQuery cancel];
    [self.buyingPullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                
                if (objects.count == 0) {
                    
                    //check if this segment is showing before showing the labels
                    if (self.segmentedControl.selectedSegmentIndex == 1) {

                        if (!self.topLabel && !self.bottomLabel) {
                            self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                            self.topLabel.textAlignment = NSTextAlignmentCenter;
                            self.topLabel.text = @"No messages";
                            [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                            self.topLabel.numberOfLines = 1;
                            self.topLabel.textColor = [UIColor lightGrayColor];
                            [self.view addSubview:self.topLabel];
                            
                            self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                            self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                            self.bottomLabel.text = @"Messages about items you want to buy will appear here";
                            [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                            self.bottomLabel.numberOfLines = 0;
                            self.bottomLabel.textColor = [UIColor lightGrayColor];
                            [self.view addSubview:self.bottomLabel];
                        }
                        else{
                            self.bottomLabel.text = @"Messages about items you want to buy will appear here";
                            
                            [self.topLabel setHidden:NO];
                            [self.bottomLabel setHidden:NO];
                        }
                    
                        [self.buyingConvoIds removeAllObjects];
                        [self.buyingConvos removeAllObjects];

                        [self.tableView reloadData];
                        [self.tableView.pullToRefreshView stopAnimating];
                    }

                    self.buyingPullFinished = YES;
                }
                else{
                    if (self.segmentedControl.selectedSegmentIndex == 1) {
                        [self.topLabel setHidden:YES];
                        [self.bottomLabel setHidden:YES];
                    }
                    
                    //add IDs first to avoid index bounds errors
                    NSMutableArray *buyingIdsPlaceholder = [NSMutableArray array];
                    
                    for (PFObject *convo in objects) {
                        [buyingIdsPlaceholder addObject:convo.objectId];
                    }
                    
                    //use placeholder to avoid index out of bounds erros if user taps a loaded cell quickly
                    [self.buyingConvoIds removeAllObjects];
                    [self.buyingConvoIds addObjectsFromArray:buyingIdsPlaceholder];
                    
                    [self.buyingConvos removeAllObjects];
                    [self.buyingConvos addObjectsFromArray:objects];
                    
                    int count = (int)[objects count];
                    self.buyingSkipped = count;
                    
                    if (self.segmentedControl.selectedSegmentIndex == 1) {
                        NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
                        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
                        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                        
                        [self.tableView.pullToRefreshView stopAnimating];
                    }

                    self.buyingPullFinished = YES;
                }
            }
            else{
                NSLog(@"error");
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)loadMoreBuying{
    if (self.buyingPullFinished == NO || self.buyingInfinFinished == NO) {
        return;
    }
    
    self.buyingInfinFinished = NO;
    
    if (!self.buyingInfiniteQuery) {
        self.buyingInfiniteQuery = [PFQuery queryWithClassName:@"convos"];
        [self.buyingInfiniteQuery whereKey:@"totalMessages" greaterThan:@0];
        [self.buyingInfiniteQuery includeKey:@"lastSent"];
        [self.buyingInfiniteQuery whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [self.buyingInfiniteQuery orderByDescending:@"lastSentDate"];
        self.buyingInfiniteQuery.limit = 15;
        [self.buyingInfiniteQuery whereKey:@"profileConvo" equalTo:@"NO"];
        [self.buyingInfiniteQuery whereKey:@"buyerDeleted" equalTo:@"NO"];
    }
    
    self.buyingInfiniteQuery.skip = self.buyingSkipped;
    [self.buyingInfiniteQuery cancel];
    [self.buyingInfiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.buyingSkipped = self.buyingSkipped + count;
            
            NSMutableArray *buyingIdsPlaceholder = [NSMutableArray array];
            
            for (PFObject *convo in objects) {
                [buyingIdsPlaceholder addObject:convo.objectId];
            }
            
            [self.buyingConvoIds addObjectsFromArray:buyingIdsPlaceholder];
            [self.buyingConvos addObjectsFromArray:objects];
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                [self.tableView reloadData];
                [self.tableView.infiniteScrollingView stopAnimating];
            }

            self.buyingInfinFinished = YES;
        }
        else{
            NSLog(@"error on buying infin %@", error);
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                [self.tableView.infiniteScrollingView stopAnimating];
            }
            self.buyingInfinFinished = YES;
        }
    }];
}

-(void)loadAllConvos{
    if (self.segmentedControl.selectedSegmentIndex == 0 && self.convoObjects.count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1 && self.buyingConvos.count > 0) {
        //load buying messages only
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 2 && self.sellingConvos.count > 0) {
        //load selling messages only
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }

    [self updateUnseenCount];

    [self loadMessages];
    [self loadSellingConvos];
    [self loadBuyingConvos];
}

-(BOOL) isInPastWeek:(NSDate *)date
{
    
    NSDate *now = [NSDate date];  // now
    NSDate *today;
    [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay // beginning of this day
                                    startDate:&today // save it here
                                     interval:NULL
                                      forDate:now];
    
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    comp.day = -7;      // lets go 7 days back from today
    NSDate * oneWeekBefore = [[NSCalendar currentCalendar] dateByAddingComponents:comp
                                                                           toDate:today
                                                                          options:0];
    
    
    if ([date compare: oneWeekBefore] == NSOrderedDescending) {
        
        if ( [date compare:today] == NSOrderedAscending ) { // or now?
            return YES;
        }
    }
    return NO;
}
@end
