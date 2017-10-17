
//
//  segmentedTableView.m
//  wtbtest
//
//  Created by Jack Ryder on 01/10/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "segmentedTableView.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
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

    if (!self.supportMode) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancelCross"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    self.firstPullFinished = YES;
    self.secondPullFinished = YES;
    
    self.purchased = [NSMutableArray array];
    self.sold = [NSMutableArray array];
    
    self.dateFormat = [[NSDateFormatter alloc] init];
    [self.dateFormat setLocale:[NSLocale currentLocale]];

    if (self.supportMode) {
        self.navigationItem.title = @"T I C K E T S";
        [self loadTickets];
    }
    else{
        self.navigationItem.title = @"O R D E R S";
        [self loadOrders];
    }
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    //put refresh code here so it remembers correct UICollectionView insets - doesn't work in VDL
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        if (weakSelf.supportMode) {
            [weakSelf loadTickets];
        }
        else{
            [weakSelf loadOrders];
        }
    }];
    
    DGActivityIndicatorView *spinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    [self.tableView.pullToRefreshView setCustomView:spinner forState:SVPullToRefreshStateAll];
    [spinner startAnimating];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        if (weakSelf.supportMode) {
            [weakSelf loadMoreTickets];
        }
        else{
            [weakSelf loadMoreOrders];
        }
    }];
}

-(void)loadTickets{
    [self loadOpenTickets];
    [self loadClosedTickets];
}

-(void)loadMoreTickets{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self loadMoreOpen];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        //load buying messages only
        [self loadMoreClosed];
    }
}

-(void)loadOpenTickets{
    if(self.firstPullFinished != YES || ![PFUser currentUser]){
        return;
    }
    
    self.firstPullFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.firstInfin cancel];
    
    if (!self.firstPull) {
        self.firstPull = [PFQuery queryWithClassName:@"supportConvos"];
        [self.firstPull whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
        [self.firstPull whereKey:@"status" equalTo:@"open"];
        self.firstPull.limit = 20;
        [self.firstPull orderByDescending:@"lastUpdated"];
    }
    
    [self.firstPull cancel];
    [self.firstPull findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            [self.purchased removeAllObjects];
            
            if (objects.count == 0) {
                NSLog(@"no open support tickets");
                //show no results label
                if (!self.noResultsLabel) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"No Open Tickets\n\nOpen a support ticket from an order summary page on BUMP";
                    [self.tableView addSubview:self.noResultsLabel];
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
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstPullFinished = YES;
            
        }
        else{
            NSLog(@"error finding purchased orders %@", error);
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstPullFinished = YES;
        }
    }];
}

-(void)loadMoreOpen{
    if(self.firstPullFinished != YES || ![PFUser currentUser] || self.firstInfinFinished != YES || self.purchased.count == 0){
        
        if (self.firstPullFinished == YES) {
            [self.tableView.infiniteScrollingView stopAnimating];
        }
        return;
    }
    
    self.firstInfinFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.firstInfin cancel];
    
    if (!self.firstInfin) {
        self.firstInfin = [PFQuery queryWithClassName:@"supportConvos"];
        [self.firstInfin whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
        [self.firstInfin whereKey:@"status" equalTo:@"open"];
        self.firstInfin.limit = 20;
        [self.firstInfin orderByDescending:@"lastUpdated"];
    }
    
    self.firstInfin.skip = self.firstSkipped;
    [self.firstInfin cancel];
    
    [self.firstInfin findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                NSLog(@"no more open tickets");
            }
            else{
                [self.purchased addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.firstSkipped += count;
            
            [self.tableView reloadData];
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding more purchased orders %@", error);
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstInfinFinished = YES;
        }
    }];
}

-(void)loadClosedTickets{
    if(self.secondPullFinished != YES || ![PFUser currentUser]){
        return;
    }
    
    self.secondPullFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.secondInfin cancel];
    
    if (!self.secondPull) {
        self.secondPull = [PFQuery queryWithClassName:@"supportConvos"];
        [self.secondPull whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
        [self.secondPull whereKey:@"status" equalTo:@"closed"];
        self.secondPull.limit = 20;
        [self.secondPull orderByDescending:@"lastUpdated"];
    }
    
    [self.secondPull cancel];
    [self.secondPull findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            [self.sold removeAllObjects];
            
            if (objects.count == 0) {
                NSLog(@"no closed tickets");
                //show no results label
                if (!self.noResultsLabel) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"No Closed Tickets\n\nWhen your issues have been resolved, they'll appear here";
                    [self.tableView addSubview:self.noResultsLabel];
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
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondPullFinished = YES;
            
        }
        else{
            NSLog(@"error finding closed tickets %@", error);
            
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondPullFinished = YES;
        }
    }];
}

-(void)loadMoreClosed{
    if(self.secondPullFinished != YES || ![PFUser currentUser] || self.secondInfinFinished != YES || self.sold.count == 0){
        return;
    }
    
    self.secondInfinFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.secondInfin cancel];
    
    if (!self.secondInfin) {
        self.secondInfin = [PFQuery queryWithClassName:@"supportConvos"];
        [self.secondInfin whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
        [self.secondInfin whereKey:@"status" equalTo:@"closed"];
        self.secondInfin.limit = 20;
        [self.secondInfin orderByDescending:@"lastUpdated"];
    }
    
    self.secondInfin.skip = self.secondSkipped;
    [self.secondInfin cancel];
    
    [self.secondInfin findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                NSLog(@"no more closed tickets");
            }
            else{
                [self.purchased addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.secondSkipped += count;
            
            [self.tableView reloadData];
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding more closed tickets %@", error);
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondInfinFinished = YES;
        }
    }];
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
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.firstInfin cancel];
    
    if (!self.firstPull) {
        self.firstPull = [PFQuery queryWithClassName:@"saleOrders"];
        [self.firstPull whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [self.firstPull whereKey:@"status" containedIn:@[@"live",@"pending"]];
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
                if (!self.noResultsLabel) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"Items you purchase on BUMP appear here";
                    [self.tableView addSubview:self.noResultsLabel];
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
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstPullFinished = YES;
            
        }
        else{
            NSLog(@"error finding purchased orders %@", error);
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstPullFinished = YES;
        }
    }];
}

-(void)loadMorePurchased{
    if(self.firstPullFinished != YES || ![PFUser currentUser] || self.firstInfinFinished != YES || self.purchased.count == 0){
        
        if (self.firstPullFinished == YES) {
            [self.tableView.infiniteScrollingView stopAnimating];
        }
        return;
    }
    
    self.firstInfinFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.firstInfin cancel];
    
    if (!self.firstInfin) {
        self.firstInfin = [PFQuery queryWithClassName:@"saleOrders"];
        [self.firstInfin whereKey:@"buyerUser" equalTo:[PFUser currentUser]];
        [self.firstInfin whereKey:@"status" containedIn:@[@"live",@"pending"]];
        self.firstInfin.limit = 20;
        [self.firstInfin orderByDescending:@"lastUpdated"];
    }
    
    self.firstInfin.skip = self.firstSkipped;
    [self.firstInfin cancel];
    
    [self.firstInfin findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                NSLog(@"no more purchased");
            }
            else{
                [self.purchased addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.firstSkipped += count;
            
            [self.tableView reloadData];
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding more purchased orders %@", error);
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.firstInfinFinished = YES;
        }
    }];
}

-(void)loadMoreOrders{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self loadMorePurchased];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        //load buying messages only
        [self loadMoreSold];
    }
}

-(void)loadSold{
    if(self.secondPullFinished != YES || ![PFUser currentUser]){
        return;
    }
    
    self.secondPullFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.secondInfin cancel];
    
    if (!self.secondPull) {
        self.secondPull = [PFQuery queryWithClassName:@"saleOrders"];
        [self.secondPull whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [self.secondPull whereKey:@"status" containedIn:@[@"live",@"pending"]];
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
                if (!self.noResultsLabel) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"Items you Sell on BUMP appear here";
                    [self.tableView addSubview:self.noResultsLabel];
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
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondPullFinished = YES;
            
        }
        else{
            NSLog(@"error finding sold orders %@", error);
            
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondPullFinished = YES;
        }
    }];
}

-(void)loadMoreSold{
    if(self.secondPullFinished != YES || ![PFUser currentUser] || self.secondInfinFinished != YES || self.sold.count == 0){
        return;
    }
    
    self.secondInfinFinished = NO;
    
    //make sure infin is cancelled before loading pull
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.secondInfin cancel];
    
    if (!self.secondInfin) {
        self.secondInfin = [PFQuery queryWithClassName:@"saleOrders"];
        [self.secondInfin whereKey:@"sellerUser" equalTo:[PFUser currentUser]];
        [self.secondInfin whereKey:@"status" containedIn:@[@"live",@"pending"]];
        self.secondInfin.limit = 20;
        [self.secondInfin orderByDescending:@"lastUpdated"];
    }
    
    self.secondInfin.skip = self.secondSkipped;
    [self.secondInfin cancel];
    
    [self.secondInfin findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                NSLog(@"no more sold");
            }
            else{
                [self.purchased addObjectsFromArray:objects];
            }
            
            int count = (int)[objects count];
            self.secondSkipped += count;
            
            [self.tableView reloadData];
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondInfinFinished = YES;
            
        }
        else{
            NSLog(@"error finding more sold orders %@", error);
            
            [self.tableView.pullToRefreshView stopAnimating];
            [self.tableView.infiniteScrollingView stopAnimating];
            
            self.secondInfinFinished = YES;
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.supportMode) {
        PFQuery *convosQuery = [PFQuery queryWithClassName:@"supportConvos"];
        [convosQuery whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
        [convosQuery whereKey:@"userUnseen" greaterThan:@0];
        [convosQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                NSLog(@"support unseen %ld", objects.count);
                
                int count = (int)[objects count];
                self.supportUnseen = count;
            }
            else{
                NSLog(@"error finding support messages %@", error);
            }
        }];
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
    
    if (self.supportMode) {
        [cell.priceLabel setTextColor:[UIColor lightGrayColor]];
        
        PFObject *ticket;
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            //first index
            ticket = [self.purchased objectAtIndex:indexPath.row];
        }
        else{
            //second index
            ticket = [self.sold objectAtIndex:indexPath.row];
        }
        
        //setup image file
        PFFile *orderImage = [ticket objectForKey:@"itemImage"];
        [cell.itemImageView setFile:orderImage];
        [cell.itemImageView loadInBackground];
        
        //setup item title, price & time
        cell.topLabel.text = [ticket objectForKey:@"itemTitle"];
        
        //set timestamp
        NSDate *convoDate = [ticket objectForKey:@"orderDate"];
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
        
        //setup next action required by this user (buyer/seller)
        if ([[ticket objectForKey:@"buyerId"] isEqualToString:[PFUser currentUser].objectId]) {
            //user is buyer
            cell.middleLabel.text = [NSString stringWithFormat:@"Purchased %@",[self.dateFormat stringFromDate:convoDate]];
        }
        else{
            //user is seller
            cell.middleLabel.text = [NSString stringWithFormat:@"Sold %@",[self.dateFormat stringFromDate:convoDate]];
        }
        
        //add timestamp of last correspondance
        NSDate *updateDate = [ticket objectForKey:@"lastSentDate"];
        BOOL updatedMessageToday = [calendar isDateInToday:updateDate];
        BOOL updatedMessageInLastWeek = [self isInPastWeek:updateDate];
        
        if (updatedMessageToday == YES) {
            //format into the time
            [self.dateFormat setDateFormat:@"HH:mm"];
        }
        else if (updatedMessageInLastWeek){
            [self.dateFormat setDateFormat:@"EEE"];
        }
        else{
            //format into date
            [self.dateFormat setDateFormat:@"dd MMM"];
        }
        cell.priceLabel.text =[self.dateFormat stringFromDate:updateDate];
        
        if ([[ticket objectForKey:@"lastSentUserId"]isEqualToString:[PFUser currentUser].objectId]) {
            cell.bottomLabel.text = @"Message Sent";
            [cell.bottomLabel setTextColor:[UIColor darkGrayColor]];
        }
        else{
            cell.bottomLabel.text = @"Awaiting Your Reply";
            [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
        }
    }
    else{
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
        
        //setup next action required by this user (buyer/seller)
        if ([[order objectForKey:@"buyerId"] isEqualToString:[PFUser currentUser].objectId]) {
            //user is buyer, to do's:
            
            if ([[order objectForKey:@"buyerLeftFeedback"] isEqualToString:@"NO"]) {
                cell.bottomLabel.text = @"Leave review";
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
            if([[order objectForKey:@"shipped"] isEqualToString:@"NO"]){
                cell.bottomLabel.text = @"Mark as Shipped";
                [cell.bottomLabel setTextColor:[UIColor colorWithRed:1.00 green:0.31 blue:0.39 alpha:1.0]];
            }
            else if ([[order objectForKey:@"sellerLeftFeedback"] isEqualToString:@"NO"]) {
                cell.bottomLabel.text = @"Leave review";
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

    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PFObject *order;
    
    if (self.supportMode) {
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            //first index
            order = [self.purchased objectAtIndex:indexPath.row];
        }
        else{
            //second index
            order = [self.sold objectAtIndex:indexPath.row];
        }
        
        //if all unseen, reset the unread icon in profileController
        //check if this ticket is unseen
        int unseen = [[order objectForKey:@"userUnseen"]intValue];
        
        if (unseen > 0) {
            self.supportUnseen =- unseen;
            if (self.supportUnseen == 0) {
                [self.delegate dismissUnreadSupport];
            }
        }
        
        //then minus off total
        //if zero, call delegate to dismiss unread icon
        
        //convo exists, go there
        ChatWithBump *vc = [[ChatWithBump alloc]init];
        vc.convoId = [order objectForKey:@"ticketId"];
        vc.convoObject = order;
        vc.otherUser = [PFUser currentUser];
        vc.supportMode = YES;
        
        if ([[order objectForKey:@"buyerId"]isEqualToString:[PFUser currentUser].objectId]) {
            vc.isBuyer = YES;
        }
        
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
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
        
        [self.navigationController pushViewController:vc animated:YES];
    }
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
        
        self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
        [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
        
        if (self.supportMode) {
            [self.segmentedControl setSectionTitles:@[@"O P E N",@"C L O S E D"]];
        }
        else{
            [self.segmentedControl setSectionTitles:@[@"P U R C H A S E D",@"S O L D"]];
        }
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
            if (self.supportMode) {
                self.noResultsLabel.text = @"No Open Tickets\n\nOpen a support ticket from an order summary page on BUMP";
            }
            else{
                self.noResultsLabel.text = @"Items you Purchase on BUMP appear here";
            }
            [self.noResultsLabel setHidden:NO];
        }
    }
    else{
        if (self.sold.count != 0) {
            [self.noResultsLabel setHidden:YES];

            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //show no results
            if (self.supportMode) {
                self.noResultsLabel.text = @"No Closed Tickets\n\nWhen your issues have been resolved, they'll appear here";
            }
            else{
                self.noResultsLabel.text = @"Items you Sell on BUMP appear here";
            }
            [self.noResultsLabel setHidden:NO];
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

@end
