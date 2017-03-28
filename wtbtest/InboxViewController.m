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

@interface InboxViewController ()

@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"M E S S A G E S";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"InboxCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    self.convoObjects = [[NSMutableArray alloc]init];
    self.unseenConvos = [[NSMutableArray alloc]init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages) name:@"NewMessage" object:nil];
    
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setLocale:[NSLocale currentLocale]];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.pullFinished = YES;
    self.infinFinished = YES;
    self.justViewedMsg = NO;
    self.lastSkipped = 0;
    self.lastSentDate = [[NSDate alloc]init];
    self.lastConvoIndex = [[NSIndexPath alloc]init];
    
    self.currentInstallation = [PFInstallation currentInstallation];
    NSLog(@"current %@", self.currentInstallation);
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    [self loadMessages];
    
    //load when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadMessages)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:[UIApplication sharedApplication]];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.selectedConvo = @"";
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Inbox"
                                      }];
    
    if (self.justViewedMsg == NO) {
        NSLog(@"HAVENT SEEN A MESSAGE");
    }
    else{
        self.justViewedMsg = NO;
    }
    
    //reset last convo as only useful when we're not looking at the inbox
    self.lastConvo = nil;

    
    self.currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([self.currency isEqualToString:@"GBP"]) {
        self.currencySymbol = @"£";
    }
    else if ([self.currency isEqualToString:@"EUR"]) {
        self.currencySymbol = @"€";
    }
    else if ([self.currency isEqualToString:@"USD"]) {
        self.currencySymbol = @"$";
    }
    
    [self.infiniteQuery cancel];
    [self.tableView.infiniteScrollingView stopAnimating];
    self.infinFinished = YES;
}

-(void)loadMessages{
    NSLog(@"LOAD MESSAGES CALLED");
    self.pullFinished = NO;
//    self.justViewedMsg = NO;
    
    self.pullQuery = [PFQuery queryWithClassName:@"convos"];
    [self.pullQuery whereKey:@"convoId" containsString:[PFUser currentUser].objectId];
    [self.pullQuery whereKey:@"totalMessages" notEqualTo:@0];
    [self.pullQuery includeKey:@"buyerUser"];
    [self.pullQuery includeKey:@"sellerUser"];
    [self.pullQuery includeKey:@"wtbListing"];
    [self.pullQuery includeKey:@"wtsListing"];
    [self.pullQuery includeKey:@"lastSent"];
    [self.pullQuery orderByDescending:@"lastSentDate"];
    self.pullQuery.limit = 20;
    [self.pullQuery cancel];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects) {
                [self.convoObjects removeAllObjects];
                [self.unseenConvos removeAllObjects];
                
                if (objects.count == 0) {
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
                        self.bottomLabel.text = @"Create listings so sellers can message you or tap Home to explore listings to message buyers now";
                        [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:17]];
                        self.bottomLabel.numberOfLines = 0;
                        self.bottomLabel.textColor = [UIColor lightGrayColor];
                        [self.view addSubview:self.bottomLabel];
                    }
                    else{
                        [self.topLabel setHidden:NO];
                        [self.bottomLabel setHidden:NO];
                    }
                    
                    [self.tableView reloadData];
                    
                    [self.tableView.pullToRefreshView stopAnimating];
                    self.pullFinished = YES;
                }
                else{
                    if (self.topLabel && self.bottomLabel) {
                        [self.topLabel setHidden:YES];
                        [self.bottomLabel setHidden:YES];
                    }
                    
                    [self.convoObjects addObjectsFromArray:objects];
                    
                    int count = (int)[objects count];
                    self.lastSkipped = count;
                    
                    NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
                    NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
                    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    [self.tableView.pullToRefreshView stopAnimating];
                    self.pullFinished = YES;
                    
                    [self updateUnseenCount];
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

-(void)updateUnseenCount{
    PFQuery *convosQuery = [PFQuery queryWithClassName:@"convos"];
    [convosQuery whereKey:@"convoId" containsString:[PFUser currentUser].objectId];
    [convosQuery whereKey:@"totalMessages" notEqualTo:@0];
    [convosQuery orderByDescending:@"createdAt"];
    [convosQuery includeKey:@"lastSent"];
    [convosQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                //check if last msg sent is seen
                //if no then retrieves the relevant unseen counter for the user
                //use that on the tab
                
                [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                self.navigationItem.title = @"M E S S A G E S";
                
                [self.unseenConvos removeAllObjects];
                int totalUnseen = 0;
                int unseen = 0;
                
                for (PFObject *convo in objects) {
                    PFObject *msgObject = [convo objectForKey:@"lastSent"];
                    
                    if ([[msgObject objectForKey:@"status"]isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                        [self.unseenConvos addObject:convo];

                        PFUser *buyer = [convo objectForKey:@"buyerUser"];
                        if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
                            //current user is buyer so other user is seller
                            unseen = [[convo objectForKey:@"buyerUnseen"] intValue];
                        }
                        else{
                            //other user is buyer, current is seller
                            unseen = [[convo objectForKey:@"sellerUnseen"] intValue];
                        }
                        totalUnseen = totalUnseen + unseen;
                        
//                        NSLog(@"total unseen %d", totalUnseen);
                    }
                }
                
                if (totalUnseen != 0) {
                    
                    if (totalUnseen > 0) {
                        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d", totalUnseen]];
                        self.navigationItem.title = [NSString stringWithFormat:@"M E S S A G E S  %d", totalUnseen];
                        
                        self.currentInstallation.badge = totalUnseen;
                        [self.currentInstallation saveEventually];
                        
                    }
                    else{
                        [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                        self.navigationItem.title = @"M E S S A G E S";
                    }
                }
                else{
                    [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                    self.navigationItem.title = @"M E S S A G E S";
                    
                    if (self.currentInstallation.badge != 0) {
                        self.currentInstallation.badge = 0;
                        [self.currentInstallation saveEventually];
                    }
                }
            }
            else{
                //no convos
                NSLog(@"error getting convos %@", error);
                [[self.tabBarController.tabBar.items objectAtIndex:3] setBadgeValue:nil];
                self.navigationItem.title = @"M E S S A G E S";
            }
    }];
}

-(void)loadMoreConvos{
    if (self.pullFinished == NO) {
        return;
    }
    self.infinFinished = NO;
    self.infiniteQuery = [PFQuery queryWithClassName:@"convos"];
    [self.infiniteQuery whereKey:@"convoId" containsString:[PFUser currentUser].objectId];
    [self.infiniteQuery whereKey:@"totalMessages" notEqualTo:@0];
    [self.infiniteQuery includeKey:@"buyerUser"];
    [self.infiniteQuery includeKey:@"sellerUser"];
    [self.infiniteQuery includeKey:@"wtbListing"];
    [self.infiniteQuery includeKey:@"wtsListing"];
    [self.infiniteQuery includeKey:@"lastSent"];
    [self.infiniteQuery orderByDescending:@"lastSentDate"];
    self.infiniteQuery.limit = 20;
    self.infiniteQuery.skip = self.lastSkipped;
    [self.infiniteQuery cancel];
    [self.infiniteQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            int count = (int)[objects count];
            self.lastSkipped = self.lastSkipped + count;
            [self.convoObjects addObjectsFromArray:objects];
            [self.tableView reloadData];
            [self.tableView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
        }
        else{
            NSLog(@"error on infin %@", error);
            [self.tableView.infiniteScrollingView stopAnimating];
            self.infinFinished = YES;
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
    
    DGActivityIndicatorView *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.tableView.pullToRefreshView setCustomView:spinner forState:SVPullToRefreshStateAll];
    [spinner startAnimating];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        if (self.infinFinished == YES) {
            [weakSelf loadMoreConvos];
        }
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
    return self.convoObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!self.cell) {
        self.cell = [[InboxCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    self.cell.wtbImageView.image = nil;    
    self.cell.userPicView.image = nil;
    
    PFObject *convoObject = [self.convoObjects objectAtIndex:indexPath.row];
    
    PFUser *seller = [convoObject objectForKey:@"sellerUser"];
    PFUser *buyer = [convoObject objectForKey:@"buyerUser"];
    
    BOOL isBuyer = NO;
    
    if ([seller.objectId isEqualToString:[PFUser currentUser].objectId]) {
        //current user is seller
        self.cell.usernameLabel.text = [NSString stringWithFormat:@"%@", buyer.username];
        [self.cell.userPicView setFile:[buyer objectForKey:@"picture"]];
        [self.cell.userPicView loadInBackground];
    }
    else{
        //current user is buyer
        isBuyer = YES;
        self.cell.usernameLabel.text = [NSString stringWithFormat:@"%@", seller.username];
        [self.cell.userPicView setFile:[seller objectForKey:@"picture"]];
        [self.cell.userPicView loadInBackground];
    }
    
    //set timestamp
    NSDate *convoDate = convoObject[@"lastSentDate"];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    BOOL updatedToday = [calendar isDateInToday:convoDate];
    
    if (updatedToday == YES) {
        //format into the time
        [self.dateFormat setDateFormat:@"HH:mm"];
    }
    else{
        //format into the day/month
        [self.dateFormat setDateFormat:@"EEE"];
    }
    self.cell.timeLabel.text = [NSString stringWithFormat:@"%@", [self.dateFormat stringFromDate:convoDate]];
    [self setProfImageBorder];

    //message from a for sale listing
    if ([[convoObject objectForKey:@"pureWTS"]isEqualToString:@"YES"]) {
        //no WTB associated with this convo
        PFObject *saleListing = [convoObject objectForKey:@"wtsListing"];
        [self.cell.wtbImageView setFile:[saleListing objectForKey:@"thumbnail"]];
        [self.cell.wtbImageView loadInBackground];
        self.cell.wtbTitleLabel.text = @"";
        self.cell.wtbPriceLabel.text = @"";
        [self setWTSImageBorder];
    }
    
    //message from a user's profile
    else if ([[convoObject objectForKey:@"profileConvo"]isEqualToString:@"YES"]) {
        //no WTB or WTS associated with this convo
        self.cell.wtbTitleLabel.text = @"";
        self.cell.wtbPriceLabel.text = @"";
    }
    
    //message from a WTB listing
    else{
        PFObject *wtbListing = [convoObject objectForKey:@"wtbListing"];
        [self.cell.wtbImageView setFile:[wtbListing objectForKey:@"image1"]];
        [self.cell.wtbImageView loadInBackground];
        self.cell.wtbTitleLabel.text = [NSString stringWithFormat:@"%@", [wtbListing objectForKey:@"title"]];

        self.cell.wtbPriceLabel.text = @"";
        [self setWTBImageBorder];
    }

    PFObject *msgObject = [convoObject objectForKey:@"lastSent"];
    NSString *text = [msgObject objectForKey:@"message"];
    
    //setup inbox cell preview text
    if ([[msgObject objectForKey:@"mediaMessage"]isEqualToString:@"YES"]) {
        
        if ([[msgObject objectForKey:@"senderName"]isEqualToString:[PFUser currentUser].username]) {
            self.cell.messageLabel.text = @"You sent a photo 💥";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ sent a photo 💥", [msgObject objectForKey:@"senderName"]];
        }
    }
    else if ([[msgObject objectForKey:@"offer"]isEqualToString:@"YES"]){
        if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
            self.cell.messageLabel.text = @"You sent an offer 🔌";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ sent an offer 🔌", [msgObject objectForKey:@"senderName"]];
        }
    }
    else if ([[msgObject objectForKey:@"sharedMessage"]isEqualToString:@"YES"]){
        if ([msgObject objectForKey:@"Sale"]) {
            //shared a for sale item
            if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                self.cell.messageLabel.text = @"You shared a for-sale item 📲";
            }
            else{
                self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ shared a for-sale item with you 📲", [msgObject objectForKey:@"senderName"]];
            }
        }
        else{
            if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
                self.cell.messageLabel.text = @"You shared a wanted listing 📲";
            }
            else{
                self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ shared a wanted listing with you 📲", [msgObject objectForKey:@"senderName"]];
            }
        }
    }
    else if ([[msgObject objectForKey:@"paypalMessage"]isEqualToString:@"YES"]){
        if ([[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
            self.cell.messageLabel.text = @"You sent your PayPal 🤑";
        }
        else{
            self.cell.messageLabel.text = [NSString stringWithFormat:@"%@ sent their PayPal 🛒", [msgObject objectForKey:@"senderName"]];
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
    
    if ([convoObject.objectId isEqualToString:self.lastConvo.objectId] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        
        NSLog(@"last convo!");
        //this is the convo the user is currently in so set the last sent to 'Seen' if sent by other user
        [self.cell.seenImageView setHidden:YES];
        [self megaUnbold];
//        self.lastConvo = nil;
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"sent"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //unseen message sent by other user
        //hide pic
        [self.cell.seenImageView setHidden:YES];
        //bold text
        [self megaBold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"sent"] && [[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //unseen message sent by me
        //hide pic
        [self.cell.seenImageView setHidden:YES];
        //unbolded
        [self megaUnbold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"seen"] && ![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //seen message sent by other user
        //hide pic
        [self.cell.seenImageView setHidden:YES];
        //unbolded
        [self megaUnbold];
    }
    else if ([[msgObject objectForKey:@"status"] isEqualToString:@"seen"] && [[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        //seen message sent by me
        //show pic
        [self.cell.seenImageView setHidden:NO];
        [self setSeenImageBorder];
        if (isBuyer == YES) {
            [self.cell.seenImageView setFile:[seller objectForKey:@"picture"]];
        }
        else{
            [self.cell.seenImageView setFile:[buyer objectForKey:@"picture"]];
        }
        [self.cell.seenImageView loadInBackground];
        //unbolded
        [self megaUnbold];
    }
    else{
        //fail safe
        NSLog(@"fail safe");
        [self.cell.seenImageView setHidden:YES];
        [self megaUnbold];
    }
    
    return self.cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFObject *convoObject = [self.convoObjects objectAtIndex:indexPath.row];
    PFObject *msgObject = [convoObject objectForKey:@"lastSent"];
    if (![[msgObject objectForKey:@"senderId"]isEqualToString:[PFUser currentUser].objectId]) {
        [msgObject setObject:@"seen" forKey:@"status"];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    int unseen = 0;
    
    PFUser *buyer = [convoObject objectForKey:@"buyerUser"];

    if ([[PFUser currentUser].objectId isEqualToString:buyer.objectId]) {
        //current user is buyer so other user is seller
        unseen = [[convoObject objectForKey:@"buyerUnseen"] intValue];
    }
    else{
        //other user is buyer, current is seller
        unseen = [[convoObject objectForKey:@"sellerUnseen"] intValue];
    }
    
    UITabBarItem *itemToBadge = self.tabBarController.tabBar.items[3];
    int currentTabValue = [itemToBadge.badgeValue intValue];
    int newTabValue = currentTabValue - unseen;
    
    if (newTabValue == 0) {
        self.navigationItem.title = @"M E S S A G E S";
        [self.navigationController tabBarItem].badgeValue = nil;
        
        self.currentInstallation.badge = 0;
    }
    
    else if (newTabValue > 0){
        self.navigationItem.title = [NSString stringWithFormat:@"M E S S A G E S  %d", newTabValue];
        [self.navigationController tabBarItem].badgeValue = [NSString stringWithFormat:@"%d", newTabValue];
        
        self.currentInstallation.badge = newTabValue;
    }
    
    else{
        NSLog(@"error calc'n %d", newTabValue);
        self.currentInstallation.badge = 0;
    }

    [self.currentInstallation saveEventually];

    self.selectedConvo = convoObject.objectId;
    
    MessageViewController *vc = [[MessageViewController alloc]init];
    vc.convoId = [convoObject objectForKey:@"convoId"];
    vc.convoObject = convoObject;
    vc.delegate = self;
    
    if ([[convoObject objectForKey:@"pureWTS"]isEqualToString:@"YES"]) {
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
    self.lastConvoIndex = indexPath;
    [self.navigationController pushViewController:vc animated:YES];
}

//multiple bcoz of imageview.cornerradius bug
-(void)setWTBImageBorder{
    self.cell.wtbImageView.layer.cornerRadius =4;
    self.cell.wtbImageView.layer.masksToBounds = YES;
    self.cell.wtbImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.cell.wtbImageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)setWTSImageBorder{
    self.cell.wtbImageView.layer.cornerRadius =15;
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
    self.cell.seenImageView.layer.cornerRadius = 10;
    self.cell.seenImageView.layer.masksToBounds = YES;
    self.cell.seenImageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.cell.seenImageView.contentMode = UIViewContentModeScaleAspectFill;
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
    self.cell.timeLabel.textColor = [UIColor darkGrayColor];
    [self.cell.wtbTitleLabel setFont:[UIFont fontWithName:@"PingFangSC-UltraLight" size:14]];
}

-(void)megaBold{
    [self boldFontForLabel:self.cell.usernameLabel];
    [self boldFontForLabel:self.cell.messageLabel];
    self.cell.messageLabel.textColor = [UIColor blackColor];
    [self boldFontForLabel:self.cell.timeLabel];
    self.cell.timeLabel.textColor = [UIColor blackColor];
    [self unboldFontForLabel:self.cell.wtbTitleLabel];
}

#pragma mark - messageVC delegates


-(void)lastMessageInConvo:(PFObject *)message{
    if (self.convoObjects.count != 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)doubleTapScroll{
    if (self.convoObjects.count != 0 && self.justViewedMsg == NO) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}
@end
