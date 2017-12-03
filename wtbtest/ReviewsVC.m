//
//  ReviewsVC.m
//  wtbtest
//
//  Created by Jack Ryder on 09/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ReviewsVC.h"
#import "ReviewCell.h"
#import "UserProfileController.h"
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import "UIImageView+Letters.h"

@interface ReviewsVC ()

@end

@implementation ReviewsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"ReviewCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setLocale:[NSLocale currentLocale]];
    [self.dateFormatter setDateFormat:@"dd MMM"];
    
    self.totalFeedback = [NSArray array];
    
    self.purchasedFeedback = [NSMutableArray array];
    self.soldFeedback = [NSMutableArray array];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.singleMode = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadFeedback{
    PFQuery *bigFeedbackQuery = [PFQuery queryWithClassName:@"feedback"];
    [bigFeedbackQuery whereKey:@"status" equalTo:@"live"];
    [bigFeedbackQuery whereKey:@"gotFeedback" equalTo:self.user];
    [bigFeedbackQuery orderByDescending:@"createdAt"];
//    [bigFeedbackQuery whereKey:@"order" equalTo:@"YES"];
    [bigFeedbackQuery includeKey:@"gaveFeedback"];
    [bigFeedbackQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            
            if (objects.count == 0) {
                //show no reviews label
                if (!self.noResultsLabel) {
                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                    self.noResultsLabel.numberOfLines = 0;
                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                    self.noResultsLabel.text = @"No Purchase Reviews";
                    [self.tableView addSubview:self.noResultsLabel];
                }
                [self.noResultsLabel setHidden:NO];
            }
            else{
                [self.noResultsLabel setHidden:YES];

                self.totalFeedback = objects;
                
//                for (PFObject *review in objects) {
//
//                    NSString *sellerId = [review objectForKey:@"sellerId"];
//                    if ([sellerId isEqualToString:[PFUser currentUser].objectId]) {
//                        [self.purchasedFeedback addObject:review];
//                    }
//                    else{
//                        [self.soldFeedback addObject:review];
//                    }
//                }
            }
            
            [self.tableView reloadData];
            
//            if (self.purchasedFeedback.count == 0 && self.segmentedControl.selectedSegmentIndex == 0) {
//                //show no reviews label
//                if (!self.noResultsLabel) {
//                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
//                    self.noResultsLabel.numberOfLines = 0;
//                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
//
//                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
//                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
//                    self.noResultsLabel.text = @"No Purchase Reviews";
//                    [self.tableView addSubview:self.noResultsLabel];
//                }
//                [self.noResultsLabel setHidden:NO];
//            }
//            else if (self.soldFeedback.count == 0 && self.segmentedControl.selectedSegmentIndex == 1) {
//                if (!self.noResultsLabel) {
//                    self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
//                    self.noResultsLabel.numberOfLines = 0;
//                    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
//
//                    [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
//                    [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
//                    self.noResultsLabel.text = @"No Sale Reviews";
//                    [self.tableView addSubview:self.noResultsLabel];
//                }
//                [self.noResultsLabel setHidden:NO];
//            }
//            else{
//                [self.noResultsLabel setHidden:YES];
//            }
            
        }
        else{
            NSLog(@"feedback error %@", error);
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
//    if (self.singleMode) {
//        return self.totalFeedback.count;
//    }
//    else{
//        if (self.segmentedControl.selectedSegmentIndex == 0) {
//            return self.purchasedFeedback.count;
//        }
//        else{
//            return self.soldFeedback.count;
//        }
//    }
    
    return self.totalFeedback.count;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[ReviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.userImageView.image = nil;
    cell.itemImageView.image = nil;
    
    [self setImageBorder:cell.userImageView withNumber:30];
    
    PFObject *feedbackObject;
    
    if (self.singleMode) {
        feedbackObject = [self.totalFeedback objectAtIndex:indexPath.row];
    }
    else{
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            feedbackObject = [self.purchasedFeedback objectAtIndex:indexPath.row];
        }
        else{
            feedbackObject = [self.soldFeedback objectAtIndex:indexPath.row];
        }
    }
    
    //set time
    NSDate *formattedDate = feedbackObject.createdAt;
    cell.timeLabel.text = [NSString stringWithFormat:@"%@",[self.dateFormatter stringFromDate:formattedDate]];
    
    int starNumber = [[feedbackObject objectForKey:@"rating"]intValue];
    
    if (starNumber == 1){
        [cell.starImageView setImage:[UIImage imageNamed:@"1star"]];
    }
    else if (starNumber == 2){
        [cell.starImageView setImage:[UIImage imageNamed:@"2star"]];
    }
    else if (starNumber == 3){
        [cell.starImageView setImage:[UIImage imageNamed:@"3star"]];
    }
    else if (starNumber == 4){
        [cell.starImageView setImage:[UIImage imageNamed:@"4star"]];
    }
    else if (starNumber == 5){
        [cell.starImageView setImage:[UIImage imageNamed:@"5star"]];
    }
    
    PFUser *gaveUser = [feedbackObject objectForKey:@"gaveFeedback"];
    
    if([gaveUser objectForKey:@"picture"]){
        
        [cell.userImageView setFile:[gaveUser objectForKey:@"picture"]];
        [cell.userImageView loadInBackground];
    }
    else{
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                        NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
        
        [cell.userImageView setImageWithString:gaveUser.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
    }
    
    cell.commentLabel.text = [feedbackObject objectForKey:@"comment"];
    cell.usernameLabel.text = gaveUser.username;
    
//    [cell.itemImageView setFile:[feedbackObject objectForKey:@"thumbnail"]];
//    [cell.itemImageView loadInBackground];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //goto user's profile
    PFObject *feedbackObject;
    
    if (self.singleMode) {
        feedbackObject = [self.totalFeedback objectAtIndex:indexPath.row];
    }
    else{
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            feedbackObject = [self.purchasedFeedback objectAtIndex:indexPath.row];
        }
        else{
            feedbackObject = [self.soldFeedback objectAtIndex:indexPath.row];
        }
    }
    
    PFUser *gaveUser = [feedbackObject objectForKey:@"gaveFeedback"];
    
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = gaveUser;
    [self.navigationController pushViewController:vc animated:YES];
    
//    if ([gaveUser.objectId isEqualToString:[PFUser currentUser].objectId]) {
//
//        //show prompt to edit review
//        self.selectedFbObject = feedbackObject;
//        [self reviewPressed];
//    }
//    else if(gaveUser){
//        //control for nil users
//        UserProfileController *vc = [[UserProfileController alloc]init];
//        vc.user = gaveUser;
//        [self.navigationController pushViewController:vc animated:YES];
//    }
}

-(void)reviewPressed{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Edit Review" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Edit review tapped"
                       customAttributes:@{}];
        
        FeedbackController *vc = [[FeedbackController alloc]init];
        vc.editMode = YES;
        vc.editFBObject = self.selectedFbObject;
        vc.user = self.user;
        
        if ([[[self.selectedFbObject objectForKey:@"sellerUser"]objectId] isEqualToString:[[PFUser currentUser]objectId]]) {
            //user is seller
            vc.purchased = NO;
        }
        else{
            //user is buyer
            vc.purchased = YES;
        }
        vc.delegate = self;
        vc.messageNav = self.navigationController;
    
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete Review" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteReviewWithObject:self.selectedFbObject];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.navigationItem.title = @"R E V I E W S";
    
    [self loadFeedback];
    
//    if (self.singleMode) {
//        self.navigationItem.title = @"R E V I E W";
//
//        [self.feedbackObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//            if (object) {
//                NSLog(@"fb object %@", self.feedbackObject);
//
//                self.totalFeedback = @[object];
//                [self.tableView reloadData];
//            }
//            else{
//                NSLog(@"error fetching feedback %@", error);
//            }
//        }];
//    }
//    else{
//        self.navigationItem.title = @"R E V I E W S";
//
//        [self loadFeedback];
//    }
}


//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//
//    //when viewing just one review, hide header
//    if (self.singleMode) {
//        return nil;
//    }
//
//    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"header"];
//    headerView.contentView.backgroundColor = [UIColor whiteColor];
//
//    if (headerView == nil) {
//        [tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"header"];
//        headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"header"];
//    }
//
//    if (!self.segmentedControl) {
//        self.segmentedControl = [[HMSegmentedControl alloc] init];
//        self.segmentedControl.frame = CGRectMake(0,0, [UIApplication sharedApplication].keyWindow.frame.size.width,50);
//        self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
//        self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
//        self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
//        self.segmentedControl.selectionIndicatorHeight = 2;
//        self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:9],NSForegroundColorAttributeName : [UIColor lightGrayColor]};
//
//        self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
//        [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
//
//        [self.segmentedControl setSectionTitles:@[@"P U R C H A S E D",@"S O L D"]];
//    }
//
//    [headerView.contentView addSubview:self.segmentedControl];
//
//
//    return headerView;
//}

-(void)segmentControlChanged{
    [self.noResultsLabel setHidden:YES];

    [self.tableView reloadData];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if (self.purchasedFeedback.count > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //got no purchases so show label
            if (!self.noResultsLabel) {
                self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                self.noResultsLabel.numberOfLines = 0;
                self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                
                [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                [self.tableView addSubview:self.noResultsLabel];
            }
            
            self.noResultsLabel.text = @"No Purchase Reviews";
            [self.noResultsLabel setHidden:NO];
        }
    }
    else{
        if (self.soldFeedback.count > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else{
            //got no purchases so show label
            if (!self.noResultsLabel) {
                self.noResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.tableView.frame.size.width/2) - 150, (self.tableView.frame.size.height/2) - 150, 300, 300)];
                self.noResultsLabel.numberOfLines = 0;
                self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
                
                [self.noResultsLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:14]];
                [self.noResultsLabel setTextColor:[UIColor lightGrayColor]];
                [self.tableView addSubview:self.noResultsLabel];
            }
            
            self.noResultsLabel.text = @"No Sale Reviews";
            [self.noResultsLabel setHidden:NO];
        }
    }
}

-(void)setImageBorder:(UIImageView *)imageView withNumber:(int)number{
    imageView.layer.cornerRadius =  number;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (self.singleMode) {
        return 0;
    }
    return 50;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 132;
}

//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 186;
//}

#pragma mark - feedback delegates

-(void)leftReview{
    [self loadFeedback];
}

-(void)deleteReviewWithObject:(PFObject *)feedbackObject{
    [feedbackObject setObject:@"deleted" forKey:@"status"];
    [feedbackObject saveInBackground];
    
    __block int starsLeft = [[feedbackObject objectForKey:@"rating"]intValue];
    
    //update user's deals data
    PFQuery *dealsQuery = [PFQuery queryWithClassName:@"deals"];
    PFUser *gotFeedback = [feedbackObject objectForKey:@"gotFeedback"];
    [dealsQuery whereKey:@"User" equalTo:gotFeedback];
    [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
//            NSLog(@"found users deals data %@", object);
            
            //decrement by the same star value
            [object incrementKey:[NSString stringWithFormat:@"star%d",starsLeft] byAmount:@-1];
            
            //decrement overall deals total
            [object incrementKey:@"dealsTotal" byAmount:@-1];
            
            //update their overall rating
            int totalReviews = [[object objectForKey:@"dealsTotal"]intValue];
            
            // weight the different stars
            int star1 = [[object objectForKey:@"star1"]intValue]*1;
            int star2 = [[object objectForKey:@"star2"]intValue]*2;
            int star3 = [[object objectForKey:@"star3"]intValue]*3;
            int star4 = [[object objectForKey:@"star4"]intValue]*4;
            int star5 = [[object objectForKey:@"star5"]intValue]*5;
            
            int total = (star1 + star2 + star3 + star4 + star5);
            int rating = total / totalReviews;
            
            [object setObject:[NSNumber numberWithInt:rating] forKey:@"currentRating"];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"updated deals data!");
                    [self loadFeedback];
                }
                else{
                    NSLog(@"error saving deals data %@", error);
                }
            }];
            
        }
        else{
            NSLog(@"error getting users deals data %@",error);
        }
    }];
}
@end
