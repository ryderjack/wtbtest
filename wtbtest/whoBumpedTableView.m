//
//  whoBumpedTableView.m
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "whoBumpedTableView.h"
#import "bumperCell.h"
#import "UserProfileController.h"
#import "UIImageView+Letters.h"
#import <Crashlytics/Crashlytics.h>
#import "Mixpanel/Mixpanel.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface whoBumpedTableView ()

@end

@implementation whoBumpedTableView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.mode isEqualToString:@"followers"]) {
        self.navigationItem.title = @"F O L L O W E R S";
        
        [Answers logCustomEventWithName:@"Viewed page"
                       customAttributes:@{
                                          @"pageName":@"Followers"
                                          }];
    }
    else if ([self.mode isEqualToString:@"following"]) {
        self.navigationItem.title = @"F O L L O W I N G";
        
        [Answers logCustomEventWithName:@"Viewed page"
                       customAttributes:@{
                                          @"pageName":@"Following"
                                          }];
    }
    else if ([self.mode isEqualToString:@"discover"]) {
        self.navigationItem.title = @"D I S C O V E R";
        
        [Answers logCustomEventWithName:@"Viewed page"
                       customAttributes:@{
                                          @"pageName":@"Discover"
                                          }];
        
        self.suggestedResults = [NSMutableArray array];

        self.facebookResults = [NSMutableArray array];
        self.suggestedResultsIds = [NSMutableArray array];
        
        self.fbSkip = 0;
    }
    else{
        self.mode = @"likes";
        self.navigationItem.title = @"L I K E S";
        
        [Answers logCustomEventWithName:@"Viewed page"
                       customAttributes:@{
                                          @"pageName":@"likes"
                                          }];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SearchCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.pullFinished = YES;
    self.fbPullFinished = YES;

    self.results = [NSMutableArray array];
    self.facebookIdResults = [NSMutableArray array];
    self.facebookResults = [NSMutableArray array];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.navigationController.navigationBar setHidden:NO];
    
    if (!self.firstLoad) {
        
        self.firstLoad = YES;
        [self loadBumps];
    }
    
    //refresh cell after been tapped & return in case following changes
    if (self.tappedCell && self.tappedIndex) {
        self.tappedCell = NO;
        
        //do a check to ensure index path is not out of bounds
        //need to look at the mode to be sure
        
        if ([self.mode isEqualToString:@"discover"]) {
            
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                if (self.tappedIndex.row < self.suggestedResults.count) {
                    [self.tableView reloadRowsAtIndexPaths:@[self.tappedIndex] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            else{
                if (self.tappedIndex.row < self.facebookResults.count) {
                    [self.tableView reloadRowsAtIndexPaths:@[self.tappedIndex] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
        }
        else{
            if (self.tappedIndex.row < self.results.count) {
                [self.tableView reloadRowsAtIndexPaths:@[self.tappedIndex] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    //when viewing just one review, hide header
    if (![self.mode isEqualToString:@"discover"]) {
        return nil;
    }
    
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
        
        self.segmentedControl.borderType = HMSegmentedControlBorderTypeBottom;
        self.segmentedControl.borderColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
        self.segmentedControl.borderWidth = 0.5;
        
        self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
        [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
        
        [self.segmentedControl setSectionTitles:@[@"S U G G E S T E D",@"F A C E B O O K"]];
    }
    
    [headerView.contentView addSubview:self.segmentedControl];
    
    
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (![self.mode isEqualToString:@"discover"]) {
        return 0;
    }
    return 50;
}

-(void)segmentControlChanged{
    
    if (self.facebookView) {
        [self hideFacebookView];
    }
    
    if (self.suggestedView) {
        [self hideSuggestedView];
    }
    
    [self.tableView reloadData];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if (self.suggestedResults.count > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //got no suggested users
            if (self.suggestedView) {
                [self showSuggestedView];
            }
            else{
                [self setupSuggestedView];
            }
        }
    }
    else{
        if (self.facebookResults.count > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            if (self.facebookView) {
                [self showFacebookView];
            }
            else{
                [self setupFacebookView];
            }
        }
    }
}

-(void)loadBumps{
    
    if ([self.mode isEqualToString:@"followers"] || [self.mode isEqualToString:@"following"]) {
        
        if (!self.pullFinished) {
            return;
        }
        self.pullFinished = NO;
        
        self.skipNumber = 0;
        [self.pullQuery cancel];
        
        self.pullQuery = [PFQuery queryWithClassName:@"Follow"];
        
        if ([self.mode isEqualToString:@"followers"]){
            [self.pullQuery includeKey:@"from"];
            [self.pullQuery whereKey:@"to" equalTo:self.user];
        }
        else{
            [self.pullQuery includeKey:@"to"];
            [self.pullQuery whereKey:@"from" equalTo:self.user];
        }

        [self.pullQuery whereKey:@"status" equalTo:@"live"];
        [self.pullQuery orderByDescending:@"createdAt"];
        self.pullQuery.limit = 30;
        [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                
                int count = (int)objects.count;
                self.skipNumber = count;
                
                [self.results removeAllObjects];
                [self.results addObjectsFromArray:objects];
                [self.tableView reloadData];
                
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
                
                if (objects.count < 30) {
                    self.infinEmpty = YES;
                }
                else{
                    self.infinEmpty = NO;
                }
            }
            else{
                NSLog(@"error getting following %@", error);
                [self.tableView reloadData];
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
        }];
    }
    else if([self.mode isEqualToString:@"discover"]){
        
        if (!self.pullFinished) {
            return;
        }
        self.pullFinished = NO;
        self.skipNumber = 0;
        [self.suggestedQuery cancel];
        
        //add in protection in case we have an empty following dic
        NSDictionary *followingDic = [[NSDictionary alloc]init];

        if ([[PFUser currentUser] objectForKey:@"followingDic"]) {
            followingDic = [[PFUser currentUser] objectForKey:@"followingDic"];
        }
        
        self.followingArray = [followingDic allKeys];
        
        self.suggestedQuery = [PFUser query];
        [self.suggestedQuery whereKey:@"suggest" equalTo:@"YES"];
        [self.suggestedQuery whereKey:@"objectId" notContainedIn:self.followingArray];
        self.suggestedQuery.limit = 10;
        [self.suggestedQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            
            if (error) {
                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    [self setupSuggestedView];
                }
                
                NSLog(@"error getting suggested %@", error);
                [self.tableView reloadData];
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
            else{
                int count = (int)objects.count;

                NSLog(@"suggested %d", count);
                
                if (count == 0) {
                    
                    if (self.segmentedControl.selectedSegmentIndex == 0) {
                        [self setupSuggestedView];
                    }
                }

                self.skipNumber = count;

                [self.suggestedResults removeAllObjects];
                [self.suggestedResults addObjectsFromArray:objects];

                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    [self.tableView reloadData];
                }

                //track ids of users returned
                [self.suggestedResultsIds removeAllObjects];
                for (PFUser *user in objects) {
                    [self.suggestedResultsIds addObject:user.objectId];
                }

                self.pullFinished = YES;
                self.infinLoadFinished = YES;

                if (objects.count < 10) {
                    self.infinEmpty = YES;
                }
                else{
                    self.infinEmpty = NO;
                }
            }
        }];
        
        //load facebook friends
        [self loadFacebookPull];
    }
    else{
        //loading like activity items about this listing
        if (!self.pullFinished) {
            return;
        }
        self.pullFinished = NO;
        
        self.skipNumber = 0;
        [self.pullQuery cancel];
        
        self.pullQuery = [PFUser query];
        [self.pullQuery whereKey:@"objectId" containedIn:self.bumpArray];
        self.pullQuery.limit = 30;
        [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                
                int count = (int)objects.count;
                self.skipNumber = count;
                
                [self.results removeAllObjects];
                [self.results addObjectsFromArray:objects];
                [self.tableView reloadData];
                
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
                self.infinEmpty = NO;
            }
            else{
                NSLog(@"error getting likes %@", error);
                [self.tableView reloadData];
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
        }];
    }
    
}

-(void)loadFacebookPull{
    //check if user has connected fb
    //if so display facebook friends
    if ([[PFUser currentUser]objectForKey:@"facebookId"] || self.connectedPayPal) {
        
        self.friendsArray = [[PFUser currentUser]objectForKey:@"friends"];
        
        if (self.friendsArray.count > 0) {
            
            [self.pullQuery cancel];
            
            self.fbPullFinished = NO;
            
            self.pullQuery = [PFUser query];
            [self.pullQuery whereKey:@"completedReg" equalTo:@"YES"];
            [self.pullQuery whereKey:@"facebookId" containedIn:self.friendsArray];
            self.pullQuery.limit = 30;
            [self.pullQuery orderByDescending:@"createdAt"];
            [self.pullQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    
                    int count = (int)objects.count;
                    
                    if (count == 0) {
                        NSLog(@"zero friends returned");
                        
                        self.inviteMode = YES;
                        
                        if (self.segmentedControl.selectedSegmentIndex == 1) {
                            [self setupFacebookView];
                        }
                    }
                    
                    self.fbSkip = count;
                    
                    [self.facebookResults removeAllObjects];
                    
                    //make sure we don't add duplicates
                    for (PFUser *user in objects) {
                        if (![self.facebookIdResults containsObject:user.objectId]) {
                            [self.facebookResults addObject:user];
                            [self.facebookIdResults addObject:user.objectId];
                        }
                    }
                    
                    if (self.segmentedControl.selectedSegmentIndex == 1) {
                        [self.tableView reloadData];
                    }
                    
                    self.fbPullFinished = YES;
                    self.fbInfinFinished = YES;
                    
                    if (objects.count < 30) {
                        self.fbEmpty = YES;
                    }
                    else{
                        self.fbEmpty = NO;
                    }
                }
                else{
                    NSLog(@"error on fb pull %@", error);
                    [self showAlertWithTitle:@"Friend Error" andMsg:error.description];
                }
            }];
        }
        else{
            NSLog(@"no facebook friends so show prompt to invite!");
            self.inviteMode = YES;
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                [self setupFacebookView];
            }
        }
    }
    else{
        NSLog(@"no facebook connected so show prompt to connect");
        self.inviteMode = NO;
        
        if (self.segmentedControl.selectedSegmentIndex == 1) {
            [self setupFacebookView];
        }
    }
}

-(void)loadMore{
    
    if (!self.pullFinished || !self.infinLoadFinished || self.infinEmpty) {
        return;
    }
    self.infinLoadFinished = NO;
    [self.infinQuery cancel];
    
    if ([self.mode isEqualToString:@"followers"] || [self.mode isEqualToString:@"following"]) {
        self.infinQuery = [PFQuery queryWithClassName:@"Follow"];
        
        if ([self.mode isEqualToString:@"followers"]) {
            [self.infinQuery includeKey:@"from"];
            [self.infinQuery whereKey:@"to" equalTo:self.user];
        }
        else{
            [self.infinQuery includeKey:@"to"];
            [self.infinQuery whereKey:@"from" equalTo:self.user];
        }
        //
        [self.infinQuery whereKey:@"status" equalTo:@"live"];
        self.infinQuery.limit = 30;
        self.infinQuery.skip = self.skipNumber;
        [self.infinQuery orderByDescending:@"createdAt"];
        [self.infinQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                
                int count = (int)objects.count;
                self.skipNumber += count;
                
                [self.results addObjectsFromArray:objects];
                [self.tableView reloadData];
                
                if (count < 30) {
                    self.infinEmpty = YES;
                }
                
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
            else{
                NSLog(@"error getting infin %@", error);
                
                [self.tableView reloadData];
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
        }];
    }
    else if([self.mode isEqualToString:@"discover"]){
        
        [self.suggestedInfinQuery cancel];
        
        self.suggestedInfinQuery = [PFUser query];
        [self.suggestedInfinQuery whereKey:@"suggest" equalTo:@"YES"];
        [self.suggestedInfinQuery whereKey:@"objectId" notContainedIn:self.followingArray];
        self.suggestedInfinQuery.limit = 10;
        self.suggestedInfinQuery.skip = self.skipNumber;
        [self.suggestedInfinQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                
                int count = (int)objects.count;
                self.skipNumber += count;
                
                [self.suggestedResults addObjectsFromArray:objects];
                [self.tableView reloadData];
                
                if (count < 10) {
                    self.infinEmpty = YES;
                }
                
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
            else{
                NSLog(@"error getting suggested infin %@", error);
                
                [self.tableView reloadData];
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
        }];
    }
    else{
        self.infinQuery = [PFUser query];
        [self.infinQuery whereKey:@"objectId" containedIn:self.bumpArray];
        
        self.infinQuery.limit = 30;
        self.infinQuery.skip = self.skipNumber;
        
        //        [self.infinQuery selectKeys:@[@"username",@"picture",@"fullname"]];
        //        [self.infinQuery selectKeys:@[@"veriUser",@"mod",@"bio",@"username",@"picture",@"followingCount",@"followerCount",@"followingCount",@"profileLocation",@"firstName",@"lastName",@"fullname",@"facebookId",@"totalBumpArray",@"wantedBumpArray",@"saleBumpArray",@"reportersArray",@"emailIsVerified",@"addPicPromptSeen",@"reviewExplainer",@"reportedArray"]];
        
        [self.infinQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                
                int count = (int)objects.count;
                self.skipNumber += count;
                
                [self.results addObjectsFromArray:objects];
                [self.tableView reloadData];
                
                if (count == 0) {
                    self.infinEmpty = YES;
                }
                
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
            else{
                NSLog(@"error getting likes infin %@", error);
                
                [self.tableView reloadData];
                self.pullFinished = YES;
                self.infinLoadFinished = YES;
            }
        }];
    }
}

-(void)loadMoreFacebook{
    if (!self.fbPullFinished || !self.fbInfinFinished || self.facebookResults.count < 30 || self.fbEmpty) {
        return;
    }
    self.fbInfinFinished = NO;
    
    [self.infinQuery cancel];
    
    self.infinQuery = [PFUser query];
    [self.infinQuery whereKey:@"facebookId" containedIn:self.friendsArray];
    [self.infinQuery whereKey:@"completedReg" equalTo:@"YES"];

    self.infinQuery.limit = 30;
    self.infinQuery.skip = self.fbSkip;
    [self.infinQuery orderByDescending:@"createdAt"];
    [self.infinQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            int count = (int)objects.count;
            self.fbSkip += count;
            
            
            //make sure we don't add duplicates
            for (PFUser *user in objects) {
                if (![self.facebookIdResults containsObject:user.objectId]) {
                    [self.facebookResults addObject:user];
                    [self.facebookIdResults addObject:user.objectId];
                }
            }
            
            [self.tableView reloadData];
            
            if (count < 30) {
                self.fbEmpty = YES;
            }
            
            self.fbPullFinished = YES;
            self.fbInfinFinished = YES;
        }
        else{
            NSLog(@"error getting fb infin %@", error);
            
            [self.tableView reloadData];
            self.fbPullFinished = YES;
            self.fbInfinFinished = YES;
        }
    }];
    
}

#pragma mark - infinite scrolling

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    float bottom = scrollView.contentSize.height - scrollView.frame.size.height;
    float buffer = 70 * 4;
    float scrollPosition = scrollView.contentOffset.y;
    
    // Reached the bottom of the list
    if (scrollPosition > (bottom - buffer)) {
        // Add more dates to the bottom
        
        if ([self.mode isEqualToString:@"discover"]) {
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                //load more suggested
                [self loadMore];
            }
            else{
                //load more facebook
                [self loadMoreFacebook];
            }
        }
        else if (self.infinLoadFinished == YES) {
            //infinity query
            [self loadMore];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self.mode isEqualToString:@"discover"]) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            return self.suggestedResults.count;
        }
        return self.facebookResults.count;
    }
    return self.results.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    
    cell.userImageView.image = nil;
    cell.userImageView.file = nil;
    cell.usernameLabel.text = @"";
    [cell.badgeImageView setHidden:YES];

    [self setImageBorder:cell.userImageView];
    
    PFUser *user;
    
    if ([self.mode isEqualToString:@"followers"]) {
        PFObject *followObject = [self.results objectAtIndex:indexPath.row];
        user = [followObject objectForKey:@"from"];
    }
    else if([self.mode isEqualToString:@"following"]){
        PFObject *followObject = [self.results objectAtIndex:indexPath.row];
        user = [followObject objectForKey:@"to"];
    }
    else if([self.mode isEqualToString:@"discover"]){
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            user = [self.suggestedResults objectAtIndex:indexPath.row];
        }
        else{
            user = [self.facebookResults objectAtIndex:indexPath.row];
        }
    }
    else{
        user = [self.results objectAtIndex:indexPath.row];
    }
    
    if ([[user objectForKey:@"veriUser"] isEqualToString:@"YES"]) {
        [cell.badgeImageView setImage:[UIImage imageNamed:@"veriBadge"]];
        [cell.badgeImageView setHidden:NO];
    }
    else if([[user objectForKey:@"mod"] isEqualToString:@"YES"]){
        [cell.badgeImageView setImage:[UIImage imageNamed:@"modBadge"]];
        [cell.badgeImageView setHidden:NO];
    }
    
    if(![user objectForKey:@"picture"]){
        
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                        NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
        
        [cell.userImageView setImageWithString:user.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
    }
    else{
        [cell.userImageView setFile:[user objectForKey:@"picture"]];
        [cell.userImageView loadInBackground];
    }
    
    cell.usernameLabel.text = user.username;
    [cell.usernameLabel sizeToFit];

    cell.nameLabel.text = [user objectForKey:@"fullname"];
    
    NSDictionary *followingDic = [[PFUser currentUser]objectForKey:@"followingDic"];
    
    if ([[PFUser currentUser].objectId isEqualToString:user.objectId]) {
        //looking at them selves
        [cell.followButton setHidden:YES];
    }
    else if ([followingDic valueForKey:user.objectId]) {
        //following
        [cell.followButton setHidden:NO];
        
        [cell.followButton setTitle:@"Following" forState:UIControlStateNormal];
        [cell.followButton setBackgroundImage:[UIImage imageNamed:@"following105x27"] forState:UIControlStateNormal];
        [cell.followButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
        
    }
    else{
        //not following
        [cell.followButton setHidden:NO];
        
        [cell.followButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
        [cell.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        [cell.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    return cell;
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFUser *user;
    
    if ([self.mode isEqualToString:@"followers"]) {
        PFObject *followObject = [self.results objectAtIndex:indexPath.row];
        user = [followObject objectForKey:@"from"];
    }
    else if([self.mode isEqualToString:@"following"]){
        PFObject *followObject = [self.results objectAtIndex:indexPath.row];
        user = [followObject objectForKey:@"to"];
    }
    else if([self.mode isEqualToString:@"discover"]){
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            user = [self.suggestedResults objectAtIndex:indexPath.row];
        }
        else{
            user = [self.facebookResults objectAtIndex:indexPath.row];
        }
    }
    else{
        user = [self.results objectAtIndex:indexPath.row];
    }
    
    self.tappedCell = YES;
    self.tappedIndex = indexPath;
    
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = user;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)followButtonPressed:(SearchCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(SearchCell*)cell];
    
    PFUser *user;
    
    if ([self.mode isEqualToString:@"followers"]) {
        PFObject *followObject = [self.results objectAtIndex:indexPath.row];
        user = [followObject objectForKey:@"from"];
    }
    else if([self.mode isEqualToString:@"following"]){
        PFObject *followObject = [self.results objectAtIndex:indexPath.row];
        user = [followObject objectForKey:@"to"];
    }
    else if([self.mode isEqualToString:@"discover"]){
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            user = [self.suggestedResults objectAtIndex:indexPath.row];
        }
        else{
            user = [self.facebookResults objectAtIndex:indexPath.row];
        }
    }
    else{
        user = [self.results objectAtIndex:indexPath.row];
    }
    
    NSDictionary *followingDic = [[PFUser currentUser]objectForKey:@"followingDic"];
    
    //check if user already following
    if ([followingDic valueForKey:user.objectId]) {
        
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        actionSheet.title = [NSString stringWithFormat:@"Unfollow %@?", user.username];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unfollow" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            //unfollow pressed
            [cell.followButton setHidden:NO];
            
            //tracking
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"unfollow_pressed" properties:@{
                                                             @"source":self.mode
                                                             }];
            
            NSLog(@"unfollow pressed");
            [cell.followButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
            [cell.followButton setTitle:@"Follow" forState:UIControlStateNormal];
            [cell.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            //update current user's followingDic locally
            if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
                //remove from existing
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
                
                if ([dic valueForKey:user.objectId]) {
                    [dic removeObjectForKey:user.objectId];
                    [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                    [[PFUser currentUser]saveInBackground];
                }
            }
            
            NSDictionary *params = @{@"followedId": user.objectId, @"followingId": [PFUser currentUser].objectId};
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
                        if (![dic valueForKey:user.objectId]) {
                            dic[user.objectId] = user.objectId;
                            [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                            [[PFUser currentUser]saveInBackground];
                        }
                    }
                    
                    //reset button
                    [cell.followButton setTitle:@"Following" forState:UIControlStateNormal];
                    [cell.followButton setBackgroundImage:[UIImage imageNamed:@"following105x27"] forState:UIControlStateNormal];
                    [cell.followButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
                    
                }
                else{
                    NSLog(@"success unfollowing user!");
                    
                    [Answers logCustomEventWithName:@"Unfollowed User"
                                   customAttributes:@{
                                                      @"where":self.mode
                                                      }];
                }
            }];
        }]];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
        
    }
    else{
        //follow pressed
        NSLog(@"follow pressed");
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"follow_pressed" properties:@{
                                                       @"source":self.mode
                                                       }];
        
        [cell.followButton setHidden:NO];
        
        [cell.followButton setTitle:@"Following" forState:UIControlStateNormal];
        [cell.followButton setBackgroundImage:[UIImage imageNamed:@"following105x27"] forState:UIControlStateNormal];
        [cell.followButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1] forState:UIControlStateNormal];
        
        //update current user's followingDic locally
        if ([[PFUser currentUser]objectForKey:@"followingDic"]) {
            //add to existing
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[[PFUser currentUser]objectForKey:@"followingDic"]];
            
            //check if value already exists in dictionary before adding
            if (![dic valueForKey:user.objectId]) {
                dic[user.objectId] = user.objectId;
                [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                [[PFUser currentUser]saveInBackground];
            }
        }
        else{
            //create one
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            dic[user.objectId] = user.objectId;
            [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
            [[PFUser currentUser]saveInBackground];
        }
        
        NSDictionary *params = @{@"followedId": user.objectId, @"followingId": [PFUser currentUser].objectId};
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
                    
                    if ([dic valueForKey:user.objectId]) {
                        [dic removeObjectForKey:user.objectId];
                        [[PFUser currentUser]setObject:dic forKey:@"followingDic"];
                        [[PFUser currentUser]saveInBackground];
                    }
                }
                
                //reset button
                [cell.followButton setBackgroundImage:[UIImage imageNamed:@"followBg"] forState:UIControlStateNormal];
                [cell.followButton setTitle:@"Follow" forState:UIControlStateNormal];
                [cell.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
            }
            else{
                NSLog(@"success following user!");
                
                [Answers logCustomEventWithName:@"Followed User"
                               customAttributes:@{
                                                  @"where":self.mode
                                                  }];
            }
        }];
    }
}

#pragma mark - connect Facebook prompt

-(void)setupFacebookView{
    //setup intro PayPal message header
    
    self.facebookView = nil;
    self.facebookView = [[UIView alloc]init];
    [self.facebookView setFrame:CGRectMake(0,0, 300, 200)];
    
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(self.facebookView.frame.size.width/2-25,0, 50, 50)];
    [imgView setImage:[UIImage imageNamed:@"connectFbIcon"]];
    
    //title label
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,imgView.frame.origin.y + 20 + 50,300, 30)];
    titleLabel.numberOfLines = 1;
    [titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:15]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    
    //message label
    UILabel *messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,titleLabel.frame.origin.y + 5 + titleLabel.frame.size.height, 300, 40)];
    messageLabel.numberOfLines = 2;
    [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12]];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    
    //connect button
    UIButton *connectButton = [[UIButton alloc]initWithFrame:CGRectMake(0,messageLabel.frame.origin.y + 15 + messageLabel.frame.size.height, 300, 42)];
    [connectButton setBackgroundImage:[UIImage imageNamed:@"connectFbBg"] forState:UIControlStateNormal];
    [connectButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:15]];
    [connectButton setTintColor:[UIColor whiteColor]];
    [connectButton addTarget:self action:@selector(connectFbPressed) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.inviteMode) {
        titleLabel.text = @"Invite Friends";
        messageLabel.text = @"You choose which friends to invite. Invite friends from Whatsapp, Facebook & more";
        [connectButton setTitle:@"Invite" forState:UIControlStateNormal];
    }
    else{
        titleLabel.text = @"Find Facebook Friends";
        messageLabel.text = @"You choose which friends to follow. We’ll never post to Facebook without your permission";
        [connectButton setTitle:@"Connect to Facebook" forState:UIControlStateNormal];
        
        [self.facebookView addSubview:imgView];
    }
    
    [self.facebookView addSubview:messageLabel];
    [self.facebookView addSubview:titleLabel];
    [self.facebookView addSubview:connectButton];
    
    self.facebookView.alpha = 0.0;
    [self.view addSubview:self.facebookView];
    
    [self showFacebookView];
    
    self.facebookView.center = CGPointMake(CGRectGetMidX([[UIScreen mainScreen]bounds]), (CGRectGetMidY([[UIScreen mainScreen]bounds]) - (self.navigationController.navigationBar.frame.size.height + self.tabBarController.tabBar.frame.size.height) )  );
}

-(void)connectFbPressed{
    
    if (self.inviteMode) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showInvite" object:nil];
        return;
    }
    
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withPublishPermissions:@[] block:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                [self hideFacebookView];

                NSLog(@"linked now!");
                [Answers logCustomEventWithName:@"Successfully Linked Facebook Account"
                               customAttributes:@{}];
                
                if ([PFUser currentUser]) {
                    [self retrieveFacebookData];
                }
            }
            else{
                NSLog(@"not linked! %@", error);
                
                if (error) {
                    [Answers logCustomEventWithName:@"Failed to Link Facebook Account"
                                   customAttributes:@{}];
                    
                    [self showAlertWithTitle:@"Connection Error" andMsg:@"You may have already signed up for BUMP with your Facebook account\n\nTry signing in with Facebook"];
                }
            }
        }];
    }
    else{
        [self hideFacebookView];

        [Answers logCustomEventWithName:@"Already Linked Facebook Account"
                       customAttributes:@{}];
        
        NSLog(@"is already linked!");
        if ([PFUser currentUser]) {
            [self retrieveFacebookData];
        }
    }
}

-(void)retrieveFacebookData{
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"id,gender,picture" forKey:@"fields"];
    
    //get friends
    FBSDKGraphRequest *friendRequest = [[FBSDKGraphRequest alloc]
                                        initWithGraphPath:@"me/friends/?limit=5000"
                                        parameters:@{@"fields": @"id, name"}
                                        HTTPMethod:@"GET"];
    [friendRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                id result,
                                                NSError *error) {
        // Handle the result
        if (!error) {
            NSArray* friends = [result objectForKey:@"data"];
            NSLog(@"Found: %lu friends with bump installed", (unsigned long)friends.count);
            NSMutableArray *friendsHoldingArray = [NSMutableArray array];
            
            for (NSDictionary *friend in friends) {
                [friendsHoldingArray addObject:[friend objectForKey:@"id"]];
            }
            
            if (friendsHoldingArray.count > 0) {
                [[PFUser currentUser]setObject:friendsHoldingArray forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
            }
            
            //find friends on BUMP
            self.friendsArray = friendsHoldingArray;
            self.connectedPayPal = YES;
            
            [self loadBumps];
            
        }
        else{
            NSLog(@"error on friends %li", (long)error.code);
        }
    }];
    
    //get FacebookId
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                  id result, NSError *error) {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             
             NSLog(@"user data; %@", userData);
             
             if ([userData objectForKey:@"gender"]) {
                 [[PFUser currentUser] setObject:[userData objectForKey:@"gender"] forKey:@"gender"];
             }
             
             if ([userData objectForKey:@"id"]) {
                 [[PFUser currentUser] setObject:[userData objectForKey:@"id"] forKey:@"facebookId"];
                 [[PFUser currentUser]saveInBackground];
                 
                 //create bumped object so can know when friends create listings
                 PFObject *bumpedObj = [PFObject objectWithClassName:@"Bumped"];
                 [bumpedObj setObject:[userData objectForKey:@"id"] forKey:@"facebookId"];
                 [bumpedObj setObject:[PFUser currentUser] forKey:@"user"];
                 [bumpedObj setObject:@"live" forKey:@"status"];
                 [bumpedObj setObject:[NSDate date] forKey:@"safeDate"];
                 [bumpedObj setObject:@0 forKey:@"timesBumped"];
                 [bumpedObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                     if (succeeded) {
                         NSLog(@"saved bumped obj");
                     }
                 }];
             }
             
             //if user doesn't have a profile picture, set their fb one
             if (![[PFUser currentUser]objectForKey:@"picture"]) {
                 if ([userData objectForKey:@"picture"]) {
                     NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
                     NSURL *picUrl = [NSURL URLWithString:userImageURL];
                     NSData *picData = [NSData dataWithContentsOfURL:picUrl];
                     
                     //save image
                     if (picData == nil) {
                         
                         [Answers logCustomEventWithName:@"PFFile Nil Data"
                                        customAttributes:@{
                                                           @"pageName":@"Adding FB pic after linking in Discover"
                                                           }];
                     }
                     else{
                         PFFile *picFile = [PFFile fileWithData:picData];
                         [picFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                             if (succeeded) {
                                 
                                 [PFUser currentUser] [@"picture"] = picFile;
                                 [[PFUser currentUser] saveInBackground];
                             }
                             else{
                                 NSLog(@"error saving new facebook pic");
                             }
                         }];
                     }
                 }
             }
         }
         else{
             NSLog(@"error connecting facebook %@", error);
         }
     }];
}

-(void)hideFacebookView{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.facebookView.alpha = 0.0;
                     }
                     completion:nil];
}

-(void)showFacebookView{
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.facebookView.alpha = 1.0;
                     }
                     completion:nil];
}
-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)setupSuggestedView{
    //setup intro PayPal message header
    
    self.suggestedView = nil;
    self.suggestedView = [[UIView alloc]init];
    [self.suggestedView setFrame:CGRectMake(0,0, 300, 200)];
    
    //title label
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,20 + 50,300, 30)];
    titleLabel.numberOfLines = 1;
    [titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:15]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    
    //message label
    UILabel *messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,titleLabel.frame.origin.y + 5 + titleLabel.frame.size.height, 300, 40)];
    messageLabel.numberOfLines = 2;
    [messageLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12]];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    
    titleLabel.text = @"Suggested Users";
    messageLabel.text = @"Check back soon to find more suggested users to follow";
    
    [self.suggestedView addSubview:messageLabel];
    [self.suggestedView addSubview:titleLabel];
    
    self.suggestedView.alpha = 0.0;
    [self.view addSubview:self.suggestedView];
    
    [self showSuggestedView];
    
    self.suggestedView.center = CGPointMake(CGRectGetMidX([[UIScreen mainScreen]bounds]), (CGRectGetMidY([[UIScreen mainScreen]bounds]) - (self.navigationController.navigationBar.frame.size.height + self.tabBarController.tabBar.frame.size.height) )  );
}

-(void)hideSuggestedView{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.suggestedView.alpha = 0.0;
                     }
                     completion:nil];
}

-(void)showSuggestedView{
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.suggestedView.alpha = 1.0;
                     }
                     completion:nil];
}

-(void)showHUDWithLabel:(NSString *)label{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    if (!label) {
        self.hud.customView = self.spinner;
        [self.spinner startAnimating];
    }
    else{
        self.hud.labelText = label;
    }
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud.labelText = @"";
        self.hud = nil;
    });
}
@end

