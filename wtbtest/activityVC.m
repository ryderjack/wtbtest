//
//  activityVC.m
//  wtbtest
//
//  Created by Jack Ryder on 09/02/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "activityVC.h"
#import "ForSaleListing.h"
#import <Crashlytics/Crashlytics.h>
#import "UserProfileController.h"
#import "UIImageView+Letters.h"
#import "MessageViewController.h"
#import "Mixpanel/Mixpanel.h"

@interface activityVC ()

@end

@implementation activityVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"A C T I V I T Y";
    
    //respond to new activty items from push or timer triggered queries in delegate
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadActivity) name:@"newActivtyItems" object:nil];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    self.resultsArray = [NSMutableArray array];
    [self.tableView registerNib:[UINib nibWithNibName:@"activityCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    //setup refresh control with custom view
    self.refresherControl = [[UIRefreshControl alloc]init];
    self.refresherControl.backgroundColor = [UIColor clearColor];
    self.refresherControl.tintColor = [UIColor lightGrayColor];
    [self.refresherControl addTarget:self action:@selector(loadActivity) forControlEvents:UIControlEventAllEvents];
    
    //implement pull to refresh
    if (@available(iOS 10.0, *)) {
        self.tableView.refreshControl = self.refresherControl;
    }
    else{
        [self.tableView addSubview:self.refresherControl];
    }
    
    self.pullFinished = YES;
    
    [self loadActivity];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.navigationController.navigationBar setHidden:NO];
    
    //reset badge value when select it
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
    
    //refresh cell after been tapped & return in case following changes
    if (self.tappedCell && self.tappedIndex) {
        self.tappedCell = NO;
        
        //do a check to ensure index path is not out of bounds
        if (self.tappedIndex.row < self.resultsArray.count) {
            [self.tableView reloadRowsAtIndexPaths:@[self.tappedIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

-(void)loadActivity{
    
    if (!self.pullFinished || ![PFUser currentUser]) {
        return;
    }
    
    self.pullFinished = NO;
    self.skipNumber = 0;
    
    //cancel outstanding queries
    [self.pullQuery cancel];
    
    self.pullQuery = [PFQuery queryWithClassName:@"Activity"];
    [self.pullQuery whereKey:@"status" equalTo:@"live"];
    [self.pullQuery whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    self.pullQuery.limit = 30;
    [self.pullQuery orderByDescending:@"createdAt"];
    [self.pullQuery includeKey:@"listing"];
    [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                //show no results label
                NSLog(@"no results");
                if (!self.topLabel && !self.bottomLabel) {
                    self.topLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                    self.topLabel.textAlignment = NSTextAlignmentCenter;
                    self.topLabel.text = @"Activity Feed";
                    [self.topLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                    self.topLabel.numberOfLines = 1;
                    self.topLabel.textColor = [UIColor lightGrayColor];
                    [self.view addSubview:self.topLabel];
                    
                    self.bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.topLabel.frame.origin.y+80, 250, 200)];
                    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
                    self.bottomLabel.text = @"People that like your items and follow your page will appear here";
                    [self.bottomLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
                    self.bottomLabel.numberOfLines = 0;
                    self.bottomLabel.textColor = [UIColor lightGrayColor];
                    [self.view addSubview:self.bottomLabel];
                }
                else{
                    [self.topLabel setHidden:NO];
                    [self.bottomLabel setHidden:NO];
                }
                [self.resultsArray removeAllObjects];
            }
            else{
                
                [self.topLabel setHidden:YES];
                [self.bottomLabel setHidden:YES];
                
                [self.resultsArray removeAllObjects];
                [self.resultsArray addObjectsFromArray:objects];
                
                int count = (int)objects.count;
                self.skipNumber = count;
            }
            
            [self.tableView reloadData];
            self.infinLoadFinished = YES;
            self.infinEmpty = NO;
            
            self.pullFinished = YES;
            [self.refreshControl endRefreshing];
            
        }
        else{
            NSLog(@"error retrieving activity objects %@", error);
            
            [self.tableView reloadData];
            self.infinLoadFinished = YES;
            self.pullFinished = YES;
            [self.refreshControl endRefreshing];
        }
    }];
    
}

-(void)loadMoreActivity{
    if (!self.infinLoadFinished || !self.pullFinished || self.resultsArray.count < 30 || self.infinEmpty) {
        return;
    }
    
    [self.refreshControl endRefreshing];
    self.infinLoadFinished = NO;
    
    [self.infinQuery cancel];
    
    self.infinQuery = [PFQuery queryWithClassName:@"Activity"];
    [self.infinQuery whereKey:@"status" equalTo:@"live"];
    [self.infinQuery whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    self.infinQuery.limit = 30;
    self.infinQuery.skip = self.skipNumber;
    [self.infinQuery orderByDescending:@"createdAt"];
    [self.infinQuery includeKey:@"listing"];
    [self.infinQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count > 0) {
                [self.resultsArray addObjectsFromArray:objects];
                int count = (int)objects.count;
                self.skipNumber += count;
            }
            else{
                self.infinEmpty = YES;
            }
            
            [self.tableView reloadData];
            self.infinLoadFinished = YES;
        }
        else{
            NSLog(@"error retrieving activity objects %@", error);
            
            [self.tableView reloadData];
            self.infinLoadFinished = YES;
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    activityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    cell.cellImageView.file = nil;
    cell.cellImageView.image = nil;

    cell.mainLabel.text = @"";
    
    PFObject *activityObject = [self.resultsArray objectAtIndex:indexPath.row];
    NSString *type = [activityObject objectForKey:@"type"];
    
    NSString *senderUsername = [activityObject objectForKey:@"senderUsername"];
    NSString *senderId = [activityObject objectForKey:@"senderId"];
    NSString *postedString = [self calcPostDateForDate:activityObject.createdAt];
    
    //mark as seen if needs be
    if ([[activityObject objectForKey:@"seen"]isEqualToString:@"unseen"]) {
        [activityObject setObject:@"seen" forKey:@"seen"];
        [activityObject saveInBackground];
    }
    
    //check what type of activity object & setup cell appropriately
    if ([type isEqualToString:@"like"]) {
        
        //setup message button
        [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"msgBg"] forState:UIControlStateNormal];
        [cell.actionButton setTitle:@"Message" forState:UIControlStateNormal];
        [cell.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        //other cell setup
        [self setSquareBorder:cell.cellImageView];
        [cell.cellImageView setFile:[activityObject objectForKey:@"image"]];
        [cell.cellImageView loadInBackground];
        
        
        cell.mainLabel.text = [NSString stringWithFormat:@"%@ liked your listing  %@",senderUsername, postedString];
        
    }
    else if([type isEqualToString:@"follow"]){
        
        //setup follow button
        
        //do check if following already
        NSDictionary *followingDic = [[PFUser currentUser]objectForKey:@"followingDic"];
        
        if ([followingDic valueForKey:senderId]) {
            //following
            [cell.actionButton setTitle:@"Following" forState:UIControlStateNormal];
            [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"following90x28"] forState:UIControlStateNormal];
            [cell.actionButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
        }
        else{
            //not following
            [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
            [cell.actionButton setTitle:@"Follow back" forState:UIControlStateNormal];
            [cell.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        
        //other cell setup
        [self setRoundedBorder:cell.cellImageView];
        
        //following user may not have a profile pic so do check
        [cell.cellImageView setFile:[activityObject objectForKey:@"image"]];
        [cell.cellImageView loadInBackground];
        
        if(![activityObject objectForKey:@"image"]){
            
            NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                            NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
            
            [cell.cellImageView setImageWithString:senderUsername color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
        }
        else{
            [cell.cellImageView setFile:[activityObject objectForKey:@"image"]];
            [cell.cellImageView loadInBackground];
        }
        
        
        cell.mainLabel.text = [NSString stringWithFormat:@"%@ started following you  %@",senderUsername, postedString];
    }
    
    //bold sender's username
    NSMutableAttributedString *mainString = [[NSMutableAttributedString alloc] initWithString:cell.mainLabel.text];
    [self modifyUsername:mainString setFontForText:senderUsername];
    [self modifyTime:mainString setFontForText:postedString];
    
    [cell.mainLabel setAttributedText:mainString];
    
    return cell;
}

-(void)setRoundedBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)setSquareBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = 0;
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
    return self.resultsArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 85;
}


-(NSString *) calcPostDateForDate:(NSDate *)createdDate{
    
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    
    NSString *postedLabelText = @"";
    if (minsBetweenDates >= 0 && minsBetweenDates < 1) {
        //seconds
        postedLabelText = [NSString stringWithFormat:@"%.fs", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        postedLabelText = @"1m";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        postedLabelText = [NSString stringWithFormat:@"%.fm", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        postedLabelText = @"1h";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        postedLabelText = [NSString stringWithFormat:@"%.fh", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        postedLabelText = [NSString stringWithFormat:@"%.fd", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        postedLabelText = [NSString stringWithFormat:@"%.fd", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        //if posted weeks ago hide label and the clock icon
        //        [self.IDLabel setHidden:YES];
        postedLabelText = [NSString stringWithFormat:@"%.fw", (minsBetweenDates/10080)];
    }
    else{
        //leave blank if doesn't fit
    }
    
    return postedLabelText;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFObject *activityObject = [self.resultsArray objectAtIndex:indexPath.row];
    NSString *type = [activityObject objectForKey:@"type"];
    
    if ([type isEqualToString:@"like"]) {
        
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = [activityObject objectForKey:@"listing"];
        vc.source = @"latest";
        vc.fromBuyNow = YES;
        vc.pureWTS = YES;
        
        //switch off hiding nav bar
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    else if([type isEqualToString:@"follow"]){
        self.tappedCell = YES;
        self.tappedIndex = indexPath;
        
        UserProfileController *vc = [[UserProfileController alloc]init];
        vc.user = [activityObject objectForKey:@"senderUser"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - activity cell delegate

-(void)cellButtonPressed:(activityCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(activityCell*)cell];
    
    PFObject *activityObject = [self.resultsArray objectAtIndex:indexPath.row];
    NSString *type = [activityObject objectForKey:@"type"];
    
    //check what type of button has been pressed
    if ([type isEqualToString:@"like"]) {
        
        //message button pressed
        [self setupMessagesForUser:[activityObject objectForKey:@"senderId"] aboutListing:[activityObject objectForKey:@"listing"] fromActivityObj:activityObject];
        
    }
    else if([type isEqualToString:@"follow"]){
        
        //do check if following already
        NSDictionary *followingDic = [[PFUser currentUser]objectForKey:@"followingDic"];
        NSString *senderId = [activityObject objectForKey:@"senderId"];
        NSString *senderUsername = [activityObject objectForKey:@"senderUsername"];
        
        if ([followingDic valueForKey:senderId]) {
            //unfollow pressed
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            actionSheet.title = [NSString stringWithFormat:@"Unfollow %@?", senderUsername];
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unfollow" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self unfollowPressedOnCell:cell toUnfollowUserId:senderId];
            }]];
            
            [self presentViewController:actionSheet animated:YES completion:nil];
            
        }
        else{
            //follow pressed
            [self followPressedOnCell:cell toFollowUserId:senderId];
        }
    }
}

#pragma mark - infinite scrolling

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    float bottom = scrollView.contentSize.height - scrollView.frame.size.height;
    float buffer = 85 * 1;
    float scrollPosition = scrollView.contentOffset.y;
    
    // Reached the bottom of the list
    if (scrollPosition > (bottom - buffer)) {
        // Add more dates to the bottom
        
        if (self.infinLoadFinished == YES) {
            //infinity query
//            NSLog(@"load more");
            [self loadMoreActivity];
        }
        
    }
}

-(NSMutableAttributedString *)modifyUsername: (NSMutableAttributedString *)mainString setFontForText:(NSString*) textToFind
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        
        [mainString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Semibold" size:13] range:range];
        [mainString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] range:range];
    }
    
    return mainString;
}

-(NSMutableAttributedString *)modifyTime: (NSMutableAttributedString *)mainString setFontForText:(NSString*) textToFind
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        
        [mainString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.61 green:0.61 blue:0.61 alpha:1.0] range:range];
    }
    
    return mainString;
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

#pragma mark - cell action button helpers

-(void)followPressedOnCell: (activityCell *)cell toFollowUserId:(NSString *)senderId{
    
    //tracking
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"follow_pressed" properties:@{
                                                   @"source":@"activity"
                                                   }];
    
    //update current user's followingDic locally
    if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
        //add to existing
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
        
        //check if value already exists in dictionary before adding
        if (![dic valueForKey:senderId]) {
            dic[senderId] = senderId;
            [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
            [[PFUser currentUser]saveInBackground];
        }
    }
    else{
        //create one
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
        dic[senderId] = senderId;
        [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
        [[PFUser currentUser]saveInBackground];
    }
    
    //change follow button
    [cell.actionButton setTitle:@"Following" forState:UIControlStateNormal];
    [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"following90x28"] forState:UIControlStateNormal];
    [cell.actionButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
    
    //call follow func
    NSDictionary *params = @{@"followedId": senderId, @"followingId": [PFUser currentUser].objectId};
    [PFCloud callFunctionInBackground:@"followUser" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error following user: %@", error);
            
            
            [Answers logCustomEventWithName:@"Error Following User"
                           customAttributes:@{
                                              @"error":error.description
                                              }];
            
            if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
                //remove from existing
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
                
                if ([dic valueForKey:senderId]) {
                    [dic removeObjectForKey:senderId];
                    [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                    [[PFUser currentUser]saveInBackground];
                }
            }
            
            //reset button
            [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
            [cell.actionButton setTitle:@"Follow back" forState:UIControlStateNormal];
            [cell.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
        }
        else{
            NSLog(@"success following user!");
            
            [Answers logCustomEventWithName:@"Followed User"
                           customAttributes:@{
                                              @"where":@"profile"
                                              }];
        }
    }];
}

-(void)unfollowPressedOnCell: (activityCell *)cell toUnfollowUserId:(NSString *)senderId{
    //unfollow pressed
    //tracking
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"unfollow_pressed" properties:@{
                                                     @"source":@"activity"
                                                     }];
    
    [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
    [cell.actionButton setTitle:@"Follow back" forState:UIControlStateNormal];
    [cell.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //update current user's followingDic locally
    if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
        //remove from existing
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
        
        if ([dic valueForKey:senderId]) {
            [dic removeObjectForKey:senderId];
            [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
            [[PFUser currentUser]saveInBackground];
        }
    }
    
    NSDictionary *params = @{@"followedId": senderId, @"followingId": [PFUser currentUser].objectId};
    [PFCloud callFunctionInBackground:@"unfollowUser" withParameters: params block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error unfollowing user: %@", error);
            
            
            [Answers logCustomEventWithName:@"Error Unfollowing User"
                           customAttributes:@{
                                              @"error":error.description
                                              }];
            
            //add user back into the local following array
            if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
                //add to existing
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
                
                //check if value already exists in dictionary before adding
                if (![dic valueForKey:senderId]) {
                    dic[senderId] = senderId;
                    [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                    [[PFUser currentUser]saveInBackground];
                }
            }
            
            //reset button
            [cell.actionButton setTitle:@"Following" forState:UIControlStateNormal];
            [cell.actionButton setBackgroundImage:[UIImage imageNamed:@"following90x28"] forState:UIControlStateNormal];
            [cell.actionButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
            
        }
        else{
            NSLog(@"success unfollowing user!");
            
            [Answers logCustomEventWithName:@"Unfollowed User"
                           customAttributes:@{
                                              @"where":@"activity"
                                              }];
        }
    }];
}

-(void)setupMessagesForUser:(NSString *)userId aboutListing:(PFObject *)listing fromActivityObj: (PFObject *)activeObj{
    
    if (![PFUser currentUser]) {
        [Answers logCustomEventWithName:@"No user error setting up messages"
                       customAttributes:@{
                                          @"where":@"for sale"
                                          }];
        
        [self showAlertWithTitle:@"User Error" andMsg:@"Check your connection and try again. If the problem persists, try looging out then logging back in again"];
        return;
    }
    
    [self showHUD];
    
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    [convoQuery whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
    [convoQuery whereKey:@"buyerId" equalTo:userId];
    [convoQuery whereKey:@"convoId" equalTo: [NSString stringWithFormat:@"%@%@%@",[PFUser currentUser].objectId,userId, listing.objectId]];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one but pretype a message like "I'm interested in your Supreme bogo" etc.
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            
            vc.listing = listing;
            vc.otherUser = [object objectForKey:@"buyerUser"];
            vc.otherUserName = @"";
            
            vc.fromActivity = YES;
            vc.sellerItemTitle = [listing objectForKey:@"itemTitle"];
            
            vc.userIsBuyer = NO;
            vc.fromLatest = YES;
            vc.pureWTS = YES;
            
            [self hideHUD];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            
            //fetch buyer object here
            PFQuery *buyerQuery = [PFUser query];
            [buyerQuery whereKey:@"objectId" equalTo:userId];
            [buyerQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                if (object) {
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"Created Convo" properties:@{
                                                                  @"source":@"activity"
                                                                  }];
                    
                    PFUser *buyer = (PFUser *)object;
                    
                    //create a new convo and goto it
                    PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
                    convoObject[@"sellerUser"] = [PFUser currentUser];
                    convoObject[@"buyerUser"] = buyer;
                    convoObject[@"wtsListing"] = listing;
                    convoObject[@"pureWTS"] = @"YES";
                    convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[PFUser currentUser].objectId,userId, listing.objectId];
                    
                    convoObject[@"totalMessages"] = @0;
                    convoObject[@"buyerUnseen"] = @0;
                    convoObject[@"sellerUnseen"] = @0;
                    convoObject[@"profileConvo"] = @"NO";
                    [convoObject setObject:@"NO" forKey:@"buyerDeleted"];
                    [convoObject setObject:@"NO" forKey:@"sellerDeleted"];
                    
                    //save additional stuff onto convo object for faster inbox loading
                    convoObject[@"thumbnail"] = [activeObj objectForKey:@"image"];
                    convoObject[@"sellerUsername"] = [PFUser currentUser].username;
                    convoObject[@"sellerId"] = [PFUser currentUser].objectId;
                    
                    if ([[PFUser currentUser] objectForKey:@"picture"]) {
                        convoObject[@"sellerPicture"] = [[PFUser currentUser] objectForKey:@"picture"];
                    }
                    
                    convoObject[@"buyerUsername"] = buyer.username;
                    convoObject[@"buyerId"] = buyer.objectId;
                    
                    if ([buyer objectForKey:@"picture"]) {
                        convoObject[@"buyerPicture"] = [buyer objectForKey:@"picture"];
                    }
                    
                    [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            //saved
                            MessageViewController *vc = [[MessageViewController alloc]init];
                            vc.convoId = [convoObject objectForKey:@"convoId"];
                            vc.convoObject = convoObject;
                            
                            vc.otherUser = buyer;
                            vc.otherUserName = buyer.username;
                            
                            vc.fromActivity = YES;
                            vc.sellerItemTitle = [listing objectForKey:@"itemTitle"];
                            
                            vc.userIsBuyer = NO;
                            vc.listing = listing;
                            vc.pureWTS = YES;
                            vc.fromLatest = YES;
                            
                            [self hideHUD];
                            [self.navigationController pushViewController:vc animated:YES];
                        }
                        else{
                            NSLog(@"error saving convo");
                            [self hideHUD];
                        }
                    }];
                }
                else{
                    NSLog(@"error finding buyer %@", error);
                    [self hideHUD];
                }
            }];
        }
    }];
}

#pragma mark - HUD

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud = nil;
    });
}

-(void)doubleTapScroll{
    if ([self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

@end

