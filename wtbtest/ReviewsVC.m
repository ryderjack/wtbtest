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

@interface ReviewsVC ()

@end

@implementation ReviewsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"R E V I E W S";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    [self.tableView registerNib:[UINib nibWithNibName:@"ReviewCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setLocale:[NSLocale currentLocale]];
    [self.dateFormatter setDateFormat:@"dd MMM"];
    
    self.feedbackArray = [NSMutableArray array];
    self.totalFeedback = [NSArray array];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadFeedback{
    //first query for sales feedback
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"feedback"];
    [salesQuery whereKey:@"sellerUser" equalTo:self.user];
    [salesQuery whereKey:@"gaveFeedback" notEqualTo:self.user];
    [salesQuery includeKey:@"buyerUser"];
    [salesQuery includeKey:@"gaveFeedback"];
    [salesQuery orderByDescending:@"createdAt"];
    [salesQuery whereKey:@"status" notEqualTo:@"deleted"];
    
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [self.feedbackArray removeAllObjects];
            [self.feedbackArray addObjectsFromArray:objects];
            
            //query for purchase feedback
            PFQuery *purchaseQuery = [PFQuery queryWithClassName:@"feedback"];
            [purchaseQuery whereKey:@"buyerUser" equalTo:self.user];
            [purchaseQuery whereKey:@"gaveFeedback" notEqualTo:self.user];
            [purchaseQuery includeKey:@"gaveFeedback"];
            [purchaseQuery includeKey:@"sellerUser"];
            [purchaseQuery orderByDescending:@"createdAt"];
            [purchaseQuery whereKey:@"status" notEqualTo:@"deleted"];

            [purchaseQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (!error) {
                    [self.feedbackArray addObjectsFromArray:objects];
                    NSSortDescriptor *sortDescriptor;
                    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                 ascending:NO];
                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSArray *sortedArray = [self.feedbackArray sortedArrayUsingDescriptors:sortDescriptors];
                    
                    [self.feedbackArray removeAllObjects];
                    [self.feedbackArray addObjectsFromArray:sortedArray];
                    
                    self.totalFeedback = nil;
                    self.totalFeedback = [NSArray arrayWithArray:self.feedbackArray];
                                        
                    if (self.feedbackArray.count == 0) {
                        //show label
                    }
                    
                    [self.tableView reloadData];
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.totalFeedback.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[ReviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    [cell.itemImageView setHidden:YES];
    cell.userImageView.image = nil;
    cell.itemImageView.image = nil;
    
    [self setImageBorder:cell.userImageView withNumber:30];
    
    PFObject *feedbackObject = [self.totalFeedback objectAtIndex:indexPath.row];
    
    //set time
    NSDate *formattedDate = feedbackObject.createdAt;
    cell.timeLabel.text = [NSString stringWithFormat:@"%@",[self.dateFormatter stringFromDate:formattedDate]];
    
    int starNumber = [[feedbackObject objectForKey:@"rating"]intValue];
    
    if (starNumber == 0) {
        [cell.starImageView setImage:[UIImage imageNamed:@"0star"]];
    }
    else if (starNumber == 1){
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
    [cell.userImageView setFile:[gaveUser objectForKey:@"picture"]];
    [cell.userImageView loadInBackground];
    cell.usernameLabel.text = gaveUser.username;
    
    cell.commentLabel.text = [feedbackObject objectForKey:@"comment"];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //goto user's profile
    PFObject *feedbackObject = [self.totalFeedback objectAtIndex:indexPath.row];
    PFUser *gaveUser = [feedbackObject objectForKey:@"gaveFeedback"];
    
    if ([gaveUser.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        //show prompt to edit review
        self.selectedFbObject = feedbackObject;
        [self reviewPressed];
    }
    else{
        UserProfileController *vc = [[UserProfileController alloc]init];
        vc.user = gaveUser;
        [self.navigationController pushViewController:vc animated:YES];
    }
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
        vc.IDUser = self.user.objectId;
        
        if ([[[self.selectedFbObject objectForKey:@"sellerUser"]objectId] isEqualToString:[[PFUser currentUser]objectId]]) {
            //user is seller
            vc.isBuyer = NO;
        }
        else{
            //user is buyer
            vc.isBuyer = YES;
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
    
    [self loadFeedback];
}

-(void)setImageBorder:(UIImageView *)imageView withNumber:(int)number{
    imageView.layer.cornerRadius =  number;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 141;
}

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
    
    PFUser *gaveFeedback = [feedbackObject objectForKey:@"gaveFeedback"];
    
    PFUser *otherUser;
    if ([[[feedbackObject objectForKey:@"sellerUser"]objectId] isEqualToString:gaveFeedback.objectId]) {
        //current user is seller user
        otherUser = [feedbackObject objectForKey:@"buyerUser"];
        
    }
    else{
        //current user is buyer user so get the other one
        otherUser = [feedbackObject objectForKey:@"sellerUser"];
    }
    
    [dealsQuery whereKey:@"User" equalTo:otherUser];
    [dealsQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSLog(@"found users deals data %@", object);
            
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
