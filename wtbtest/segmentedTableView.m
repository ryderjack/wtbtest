
//
//  segmentedTableView.m
//  wtbtest
//
//  Created by Jack Ryder on 01/10/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "segmentedTableView.h"
//#import <SVPullToRefresh/SVPullToRefresh.h>
#import <Crashlytics/Crashlytics.h>
#import <DGActivityIndicatorView.h>
#import "splitTableViewCell.h"
#import "CheckoutSummary.h"
#import "OrderSummaryView.h"
#import "ChatWithBump.h"

@interface segmentedTableView ()

@end

@implementation segmentedTableView

- (void)viewDidLoad {
    [super viewDidLoad];
    self.supportUnseen = 0;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"splitTableViewCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    //setup refresh control with custom view
    self.refreshControl = [[UIRefreshControl alloc]init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    [self.refreshControl addTarget:self action:@selector(pullTarget) forControlEvents:UIControlEventAllEvents];
    
    //implement pull to refresh
    if (@available(iOS 10.0, *)) {
        self.tableView.refreshControl = self.refreshControl;
    }
    else{
        [self.tableView addSubview:self.refreshControl];
    }

//    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
//    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.firstPullFinished = YES;
    self.secondPullFinished = YES;
    
    self.purchased = [NSMutableArray array];
    self.sold = [NSMutableArray array];
    
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setLocale:[NSLocale currentLocale]];

    self.navigationItem.title = @"O R D E R S";
    [self loadOrders];
    
}

-(void)pullTarget{
    [self loadOrders];
}

#pragma mark - infinite scrolling

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    float bottom = scrollView.contentSize.height - scrollView.frame.size.height;
    float buffer = 84 * 2;
    float scrollPosition = scrollView.contentOffset.y;
    
    // Reached the bottom of the list
    if (scrollPosition > (bottom - buffer)) {
        // Add more dates to the bottom
        
        //infinity query
        [self loadMoreOrders];
    }
}

-(void)loadOrders{
    [self loadPurchased];
    [self loadSold];
}

-(void)loadPurchased{
    if(self.firstPullFinished != YES || ![PFUser currentUser]){
        return;
    }
    
    self.firstPullFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.firstInfin cancel];
    
    if (!self.firstPull) {
        self.firstPull = [PFQuery queryWithClassName:@"saleOrders"];
        [self.firstPull whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [self.firstPull whereKey:@"status" containedIn:@[@"live",@"pending", @"failed", @"refunded"]];
        self.firstPull.limit = 20;
        [self.firstPull orderByDescending:@"lastUpdated"];
    }

    [self.firstPull cancel];
    [self.firstPull findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            [self.purchased removeAllObjects];
            
            if (objects.count == 0) {
                NSLog(@"no purchased");
                //show no results label
                if (!self.noResultsLabel && self.segmentedControl.selectedSegmentIndex == 0) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"Items you've Purchased on BUMP appear here";
                    [self.tableView addSubview:self.noResultsLabel];
                    [self.noResultsLabel setHidden:YES];
                }
                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    [self.noResultsLabel setHidden:NO];
                }
            }
            else{
                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    [self.noResultsLabel setHidden:YES];
                }
                [self.purchased addObjectsFromArray:objects];
            }

            int count = (int)[objects count];
            self.firstSkipped = count;
            
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                [self.tableView reloadData];
            }
            [self.refreshControl endRefreshing];
            self.firstPullFinished = YES;
            self.firstInfinFinished = YES;
            self.purchasedInfinEmpty = NO;
            
        }
        else{
            NSLog(@"error finding purchased orders %@", error);
            [self.refreshControl endRefreshing];
            
            self.firstPullFinished = YES;
        }
    }];
}

-(void)loadMorePurchased{
    if(self.firstPullFinished != YES || ![PFUser currentUser] || self.firstInfinFinished != YES || self.purchased.count < 20 || self.purchasedInfinEmpty){
        return;
    }
    
    self.firstInfinFinished = NO;
    [self.firstInfin cancel];
    
    if (!self.firstInfin) {
        self.firstInfin = [PFQuery queryWithClassName:@"saleOrders"];
        [self.firstInfin whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [self.firstInfin whereKey:@"status" containedIn:@[@"live",@"pending", @"refunded", @"failed"]];
        self.firstInfin.limit = 20;
        [self.firstInfin orderByDescending:@"lastUpdated"];
    }
    
    self.firstInfin.skip = self.firstSkipped;
    [self.firstInfin cancel];
    
    [self.firstInfin findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                NSLog(@"no more purchased");
                self.purchasedInfinEmpty = YES;
            }
            else{
                [self.purchased addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.firstSkipped += count;
            
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
            
            self.firstInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding more purchased orders %@", error);
            [self.refreshControl endRefreshing];
            
            self.firstInfinFinished = YES;
        }
    }];
}

-(void)loadMoreOrders{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self loadMorePurchased];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1 && self.secondInfinFinished == YES) {
        //load buying messages only
        [self loadMoreSold];
    }
}

-(void)loadSold{
    if(self.secondPullFinished != YES || ![PFUser currentUser]){
        return;
    }
    
    self.secondPullFinished = NO;
    [self.secondInfin cancel];
    
    if (!self.secondPull) {
        self.secondPull = [PFQuery queryWithClassName:@"saleOrders"];
        [self.secondPull whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [self.secondPull whereKey:@"status" containedIn:@[@"live", @"refunded"]];
        self.secondPull.limit = 20;
        [self.secondPull orderByDescending:@"lastUpdated"];
    }
    
    [self.secondPull cancel];
    [self.secondPull findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            [self.sold removeAllObjects];
            
            if (objects.count == 0) {
                NSLog(@"no sold");
                //show no results label
                if (!self.noResultsLabel && self.segmentedControl.selectedSegmentIndex == 1) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"Items you've Sold on BUMP appear here";
                    [self.tableView addSubview:self.noResultsLabel];
                    [self.noResultsLabel setHidden:YES];
                }
                if (self.segmentedControl.selectedSegmentIndex == 1) {
                    [self.noResultsLabel setHidden:NO];
                }
            }
            else{
                if (self.segmentedControl.selectedSegmentIndex == 1) {
                    [self.noResultsLabel setHidden:YES];
                }
                
                [self.sold addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.secondSkipped = count;
            
            if (self.segmentedControl.selectedSegmentIndex == 1) {
                [self.tableView reloadData];
            }
            [self.refreshControl endRefreshing];
            
            self.secondPullFinished = YES;
            self.soldInfinEmpty = NO;
            self.secondInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding sold orders %@", error);
            [self.refreshControl endRefreshing];
            
            self.secondPullFinished = YES;
        }
    }];
}

-(void)loadMoreSold{
    if(self.secondPullFinished != YES || ![PFUser currentUser] || self.secondInfinFinished != YES || self.sold.count < 20 || self.soldInfinEmpty){
        return;
    }
    
    self.secondInfinFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.secondInfin cancel];
    
    if (!self.secondInfin) {
        self.secondInfin = [PFQuery queryWithClassName:@"saleOrders"];
        [self.secondInfin whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [self.secondInfin whereKey:@"status" containedIn:@[@"live", @"refunded"]];
        self.secondInfin.limit = 20;
        [self.secondInfin orderByDescending:@"lastUpdated"];
    }
    
    self.secondInfin.skip = self.secondSkipped;
    [self.secondInfin cancel];
    
    [self.secondInfin findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                self.soldInfinEmpty = YES;
            }
            else{
                [self.sold addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.secondSkipped += count;
            
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
            
            self.secondInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding more sold orders %@", error);
            [self.refreshControl endRefreshing];
            
            self.secondInfinFinished = YES;
        }
    }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    //post notification that forces profile tab badge to be recalculated
    [[NSNotificationCenter defaultCenter] postNotificationName:@"orderPlaced" object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [Answers logCustomEventWithName:@"Viewed Orders"
                   customAttributes:@{}];
    
    if (self.tappedOrder) {
        self.tappedOrder = NO;
        [self loadOrders];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    splitTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[splitTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.itemImageView.image = nil;
    [cell.unreadIcon setHidden:YES];

    PFObject *order;
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        //first index
        order = [self.purchased objectAtIndex:indexPath.row];
    }
    else{
        //second index
        order = [self.sold objectAtIndex:indexPath.row];
    }
    
    //setup image file
    PFFile *orderImage = [order objectForKey:@"itemImage"];
    [cell.itemImageView setFile:orderImage];
    [cell.itemImageView loadInBackground];
    
    //setup item title, price & time
    cell.topLabel.text = [order objectForKey:@"itemTitle"];
    cell.priceLabel.text = [order objectForKey:@"totalPriceLabel"];
    
    //set timestamp
    NSDate *convoDate = order.createdAt;
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
    
    cell.middleLabel.text = [self.dateFormat stringFromDate:convoDate];
    
    if ([[order objectForKey:@"status"] isEqualToString:@"failed"]) {
        cell.bottomLabel.text = @"Payment Failed";
        [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
    }
    else if ([[order objectForKey:@"status"] isEqualToString:@"pending"]) {
        cell.bottomLabel.text = @"Payment Pending";
        [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
        
        
    }
    else if ([[order objectForKey:@"status"] isEqualToString:@"refunded"]) {
        cell.bottomLabel.text = @"Payment Refunded";
        [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
    }
    else{
        //setup next action required by this user (buyer/seller)
        if ([[order objectForKey:@"buyerId"] isEqualToString:[PFUser currentUser].objectId]) {
            //user is buyer, to do's:
            
            if([[order objectForKey:@"refundStatus"] isEqualToString:@"requested"]){
                cell.bottomLabel.text = @"Refund Requested";
                [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
            }
            else if ([[order objectForKey:@"buyerLeftFeedback"] isEqualToString:@"NO"]) {
                cell.bottomLabel.text = @"Leave Feedback";
                [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
            }
            else if([[order objectForKey:@"shipped"] isEqualToString:@"NO"]){
                cell.bottomLabel.text = @"Awaiting Shipment";
                [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
            }
            else if ([[order objectForKey:@"sellerLeftFeedback"] isEqualToString:@"NO"]) {
                cell.bottomLabel.text = @"Awaiting Feedback";
                [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                cell.bottomLabel.text = @"Complete";
                [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        else{
            //user is seller, to do's:
            if([[order objectForKey:@"refundStatus"] isEqualToString:@"requested"]){
                cell.bottomLabel.text = @"Refund Requested";
                [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
            }
            else if([[order objectForKey:@"shipped"] isEqualToString:@"NO"]){
                cell.bottomLabel.text = @"Mark as Shipped";
                [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
            }
            else if ([[order objectForKey:@"sellerLeftFeedback"] isEqualToString:@"NO"]) {
                cell.bottomLabel.text = @"Leave Feedback";
                [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
            }
            else if ([[order objectForKey:@"buyerLeftFeedback"] isEqualToString:@"NO"]) {
                cell.bottomLabel.text = @"Awaiting Feedback";
                [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
            }
            else{
                cell.bottomLabel.text = @"Complete";
                [cell.bottomLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
    }
    
    if ([[order objectForKey:@"buyerId"] isEqualToString:[PFUser currentUser].objectId]) {
        //check buyer unseen
        int unseen = [[order objectForKey:@"buyerUnseen"]intValue];
        if (unseen != 0) {
            [self setCellUnread:cell];
        }
        else{
            [self setCellRead:cell];
        }
    }
    else{
        //check seller unseen
        int unseen = [[order objectForKey:@"sellerUnseen"]intValue];
        if (unseen != 0) {
            [self setCellUnread:cell];
        }
        else{
            [self setCellRead:cell];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PFObject *order;
    
    OrderSummaryView *vc = [[OrderSummaryView alloc]init];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        //first index
        order = [self.purchased objectAtIndex:indexPath.row];
        vc.isBuyer = YES;
    }
    else{
        //second index
        order = [self.sold objectAtIndex:indexPath.row];
    }
    
    vc.orderObject = order;
    self.tappedOrder = YES;
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 84;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return self.purchased.count;
    }
    else{
        return self.sold.count;
    }
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
        
        self.segmentedControl.borderType = HMSegmentedControlBorderTypeBottom;
        self.segmentedControl.borderColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
        self.segmentedControl.borderWidth = 0.5;
        
        self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
        [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
        
        //get current user's purchase/sale totals & set as titles
        int saleNumber = 0;
        int purchaseNumber = 0;
        
        if ([[PFUser currentUser]objectForKey:@"saleNumber"]) {
            saleNumber = [[[PFUser currentUser]objectForKey:@"saleNumber"]intValue];
        }
        
        if ([[PFUser currentUser]objectForKey:@"purchaseNumber"]) {
            purchaseNumber = [[[PFUser currentUser]objectForKey:@"purchaseNumber"]intValue];
        }
        
        NSString *purchaseTitle = @"P U R C H A S E D";
        NSString *soldTitle = @"S O L D";
        
        if (saleNumber > 0 && purchaseNumber > 0) {
            purchaseTitle = [NSString stringWithFormat:@"%d  P U R C H A S E D", purchaseNumber];
            soldTitle = [NSString stringWithFormat:@"%d  S O L D", saleNumber];
        }
        else if(saleNumber > 0 && purchaseNumber == 0){
            soldTitle = [NSString stringWithFormat:@"%d  S O L D", saleNumber];
        }
        else if(saleNumber == 0 && purchaseNumber > 0){
            purchaseTitle = [NSString stringWithFormat:@"%d  P U R C H A S E D", purchaseNumber];
        }
        
        [self.segmentedControl setSectionTitles:@[purchaseTitle,soldTitle]];

    }
    
    [headerView.contentView addSubview:self.segmentedControl];
    
    
    return headerView;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(void)segmentControlChanged{
    
    [self.tableView reloadData];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if (self.purchased.count != 0) {
            [self.noResultsLabel setHidden:YES];

            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //show no results
            
            if (!self.noResultsLabel) {
                self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                self.noResultsLabel.numberOfLines = 0;
                self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                
                [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                
                self.noResultsLabel.text = @"Items you've Purchased on BUMP appear here";
                
                [self.tableView addSubview:self.noResultsLabel];
            }
            else{
                self.noResultsLabel.text = @"Items you've Purchased on BUMP appear here";
                [self.noResultsLabel setHidden:NO];
            }
        }
    }
    else{
        if (self.sold.count != 0) {
            [self.noResultsLabel setHidden:YES];

            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            
            if (!self.noResultsLabel) {
                self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                self.noResultsLabel.numberOfLines = 0;
                self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                
                [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                
                self.noResultsLabel.text = @"Items you've Sold on BUMP appear here";
                
                [self.tableView addSubview:self.noResultsLabel];
            }
            else{
                
                self.noResultsLabel.text = @"Items you've Sold on BUMP appear here";
                [self.noResultsLabel setHidden:NO];
            }
        }
    }
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

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setCellRead: (splitTableViewCell *) cell{
    [cell.unreadIcon setHidden:YES];

    [self unboldFontForLabel:cell.topLabel];
    [self unboldFontForLabel:cell.middleLabel];
    cell.topLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    cell.middleLabel.textColor = [UIColor lightGrayColor];
}

-(void)setCellUnread: (splitTableViewCell *) cell{
    [cell.unreadIcon setHidden:NO];
    
    [self boldFontForLabel:cell.topLabel];
    [self boldFontForLabel:cell.middleLabel];
    cell.topLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    cell.middleLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
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


@end
